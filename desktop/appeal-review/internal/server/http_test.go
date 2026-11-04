package server

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/romangolotvin/plate-vault/desktop/appeal-review/internal/inbox"
)

func TestPostAndGetAppeal(t *testing.T) {
	store, err := inbox.Open(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	handler := Handler(store)
	body, contentType := multipartBody(t, map[string]string{
		"id":              "a1",
		"plateItemId":     "p1",
		"countryCode":     "RU",
		"scannedNumber":   "М777ЕР178",
		"correctedNumber": "М777ЕР177",
		"createdAt":       "2026-11-04T18:00:00Z",
	}, []byte{0xFF, 0xD8, 0xFF, 0x00, 0xD9})

	req := httptest.NewRequest(http.MethodPost, "/v1/appeals", body)
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("Authorization", "Bearer "+store.Token())
	res := httptest.NewRecorder()
	handler.ServeHTTP(res, req)
	if res.Code != http.StatusCreated {
		t.Fatalf("status %d body %s", res.Code, res.Body.String())
	}
	var created inbox.Appeal
	if err := json.Unmarshal(res.Body.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.ScannedNumber != "М777ЕР178" || created.CorrectedNumber != "М777ЕР177" {
		t.Fatalf("numbers %#v", created)
	}
	if len(created.Photos) != 1 {
		t.Fatalf("photos %#v", created.Photos)
	}

	unauth := httptest.NewRequest(http.MethodGet, "/v1/appeals/a1", nil)
	unauthRes := httptest.NewRecorder()
	handler.ServeHTTP(unauthRes, unauth)
	if unauthRes.Code != http.StatusUnauthorized {
		t.Fatalf("unauth %d", unauthRes.Code)
	}

	get := httptest.NewRequest(http.MethodGet, "/v1/appeals/a1", nil)
	get.Header.Set("Authorization", "Bearer "+store.Token())
	getRes := httptest.NewRecorder()
	handler.ServeHTTP(getRes, get)
	if getRes.Code != http.StatusOK {
		t.Fatalf("get %d %s", getRes.Code, getRes.Body.String())
	}
}

func multipartBody(t *testing.T, meta map[string]string, photo []byte) (io.Reader, string) {
	t.Helper()
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)
	raw, err := json.Marshal(meta)
	if err != nil {
		t.Fatal(err)
	}
	if err := writer.WriteField("meta", string(raw)); err != nil {
		t.Fatal(err)
	}
	part, err := writer.CreateFormFile("photo", "wide.jpg")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := part.Write(photo); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	return &buf, writer.FormDataContentType()
}
