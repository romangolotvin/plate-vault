// Package server receives appeals from the Plate Vault phone app.
package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"

	"github.com/romangolotvin/plate-vault/desktop/appeal-review/internal/inbox"
)

const maxBody = 32 << 20

// Handler is the local API the phone posts to.
func Handler(store *inbox.Store) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/health", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
	})
	mux.HandleFunc("POST /v1/appeals", func(w http.ResponseWriter, r *http.Request) {
		if !authorized(r, store.Token()) {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		create(store, w, r)
	})
	mux.HandleFunc("GET /v1/appeals", func(w http.ResponseWriter, r *http.Request) {
		if !authorized(r, store.Token()) {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"appeals": store.List()})
	})
	mux.HandleFunc("GET /v1/appeals/{id}", func(w http.ResponseWriter, r *http.Request) {
		if !authorized(r, store.Token()) {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		appeal, ok := store.Get(r.PathValue("id"))
		if !ok {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "not found"})
			return
		}
		writeJSON(w, http.StatusOK, appeal)
	})
	return mux
}

func create(store *inbox.Store, w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, maxBody)
	if err := r.ParseMultipartForm(maxBody); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "expected multipart form"})
		return
	}
	meta := r.FormValue("meta")
	var appeal inbox.Appeal
	if err := json.Unmarshal([]byte(meta), &appeal); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "meta is not json"})
		return
	}
	var photos []inbox.Upload
	if r.MultipartForm != nil {
		for _, header := range r.MultipartForm.File["photo"] {
			file, err := header.Open()
			if err != nil {
				writeJSON(w, http.StatusBadRequest, map[string]string{"error": "photo unreadable"})
				return
			}
			bytes, err := io.ReadAll(io.LimitReader(file, maxBody))
			file.Close()
			if err != nil {
				writeJSON(w, http.StatusBadRequest, map[string]string{"error": "photo unreadable"})
				return
			}
			photos = append(photos, inbox.Upload{Filename: header.Filename, Bytes: bytes})
		}
	}
	saved, err := store.Create(appeal, photos)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, saved)
}

func authorized(r *http.Request, token string) bool {
	if token == "" {
		return false
	}
	header := strings.TrimSpace(r.Header.Get("Authorization"))
	return header == "Bearer "+token
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	raw, err := json.Marshal(body)
	if err != nil {
		http.Error(w, "json", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(raw)
}

// ErrClosed is reserved so callers can treat a stopped server as expected.
var ErrClosed = errors.New("server closed")
