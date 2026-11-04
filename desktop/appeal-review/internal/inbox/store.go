// Package inbox stores plate appeals on the owner's computer.
package inbox

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type Status string

const (
	StatusPending  Status = "pending"
	StatusApproved Status = "approved"
	StatusRejected Status = "rejected"
)

// Appeal is one collector request to correct a scanned plate.
type Appeal struct {
	ID              string  `json:"id"`
	PlateItemID     string  `json:"plateItemId"`
	CountryCode     string  `json:"countryCode"`
	ScannedNumber   string  `json:"scannedNumber"`
	CorrectedNumber string  `json:"correctedNumber"`
	CreatedAt       string  `json:"createdAt"`
	ReceivedAt      string  `json:"receivedAt"`
	Status          Status  `json:"status"`
	Photos          []Photo `json:"photos"`
	DecidedAt       string  `json:"decidedAt,omitempty"`
}

// Photo is a file saved next to the appeal.
type Photo struct {
	Name string `json:"name"`
	Path string `json:"path"`
}

// Upload is a photo the phone just sent.
type Upload struct {
	Filename string
	Bytes    []byte
}

// Store is the on-disk inbox. It is safe for the HTTP server and the window.
type Store struct {
	mu       sync.Mutex
	dir      string
	token    string
	port     int
	appeals  []Appeal
	OnChange func()
}

type fileState struct {
	Token   string   `json:"token"`
	Port    int      `json:"port"`
	Appeals []Appeal `json:"appeals"`
}

// Open loads an inbox directory, creating a config and token on first use.
func Open(dir string) (*Store, error) {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, err
	}
	s := &Store{dir: dir, port: 8787}
	path := filepath.Join(dir, "inbox.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			return nil, err
		}
		s.token, err = newToken()
		if err != nil {
			return nil, err
		}
		return s, s.persistLocked()
	}
	var state fileState
	if err := json.Unmarshal(raw, &state); err != nil {
		return nil, err
	}
	s.token = state.Token
	if state.Port > 0 {
		s.port = state.Port
	}
	s.appeals = state.Appeals
	if s.token == "" {
		s.token, err = newToken()
		if err != nil {
			return nil, err
		}
		if err := s.persistLocked(); err != nil {
			return nil, err
		}
	}
	return s, nil
}

func (s *Store) Dir() string { return s.dir }

func (s *Store) Token() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.token
}

func (s *Store) Port() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.port
}

func (s *Store) List() []Appeal {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]Appeal, len(s.appeals))
	copy(out, s.appeals)
	return out
}

func (s *Store) Get(id string) (Appeal, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, appeal := range s.appeals {
		if appeal.ID == id {
			return appeal, true
		}
	}
	return Appeal{}, false
}

// Create stores a new appeal and its photos. The same id is returned unchanged.
func (s *Store) Create(incoming Appeal, photos []Upload) (Appeal, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	incoming.ID = strings.TrimSpace(incoming.ID)
	incoming.ScannedNumber = strings.TrimSpace(incoming.ScannedNumber)
	incoming.CorrectedNumber = strings.TrimSpace(incoming.CorrectedNumber)
	if incoming.ID == "" {
		return Appeal{}, errors.New("missing id")
	}
	if incoming.ScannedNumber == "" || incoming.CorrectedNumber == "" {
		return Appeal{}, errors.New("missing plate numbers")
	}
	for _, existing := range s.appeals {
		if existing.ID == incoming.ID {
			return existing, nil
		}
	}
	savedPhotos := make([]Photo, 0, len(photos))
	photoDir := filepath.Join(s.dir, "photos", sanitize(incoming.ID))
	if len(photos) > 0 {
		if err := os.MkdirAll(photoDir, 0o755); err != nil {
			return Appeal{}, err
		}
	}
	for i, photo := range photos {
		ext := extension(photo.Bytes, photo.Filename)
		name := fmt.Sprintf("%d%s", i+1, ext)
		full := filepath.Join(photoDir, name)
		if err := os.WriteFile(full, photo.Bytes, 0o644); err != nil {
			return Appeal{}, err
		}
		rel, err := filepath.Rel(s.dir, full)
		if err != nil {
			rel = full
		}
		savedPhotos = append(savedPhotos, Photo{Name: name, Path: rel})
	}
	now := time.Now().UTC().Format(time.RFC3339)
	appeal := Appeal{
		ID:              incoming.ID,
		PlateItemID:     incoming.PlateItemID,
		CountryCode:     strings.ToUpper(incoming.CountryCode),
		ScannedNumber:   incoming.ScannedNumber,
		CorrectedNumber: incoming.CorrectedNumber,
		CreatedAt:       incoming.CreatedAt,
		ReceivedAt:      now,
		Status:          StatusPending,
		Photos:          savedPhotos,
	}
	if appeal.CreatedAt == "" {
		appeal.CreatedAt = now
	}
	s.appeals = append([]Appeal{appeal}, s.appeals...)
	if err := s.persistLocked(); err != nil {
		return Appeal{}, err
	}
	s.notify()
	return appeal, nil
}

// Decide records the owner's approval or rejection.
func (s *Store) Decide(id string, status Status) (Appeal, error) {
	if status != StatusApproved && status != StatusRejected {
		return Appeal{}, errors.New("decision must be approved or rejected")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	for i, appeal := range s.appeals {
		if appeal.ID != id {
			continue
		}
		appeal.Status = status
		appeal.DecidedAt = time.Now().UTC().Format(time.RFC3339)
		s.appeals[i] = appeal
		if err := s.persistLocked(); err != nil {
			return Appeal{}, err
		}
		s.notify()
		return appeal, nil
	}
	return Appeal{}, os.ErrNotExist
}

func (s *Store) notify() {
	if s.OnChange != nil {
		go s.OnChange()
	}
}

func (s *Store) persistLocked() error {
	state := fileState{
		Token:   s.token,
		Port:    s.port,
		Appeals: s.appeals,
	}
	if state.Appeals == nil {
		state.Appeals = []Appeal{}
	}
	raw, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	path := filepath.Join(s.dir, "inbox.json")
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

func (s *Store) ReadPhoto(rel string) ([]byte, error) {
	clean := filepath.Clean(rel)
	if clean == "." || strings.HasPrefix(clean, "..") {
		return nil, errors.New("bad photo path")
	}
	full := filepath.Join(s.dir, clean)
	prefix := filepath.Clean(s.dir) + string(os.PathSeparator)
	if !strings.HasPrefix(filepath.Clean(full), prefix) && filepath.Clean(full) != filepath.Clean(s.dir) {
		return nil, errors.New("bad photo path")
	}
	return os.ReadFile(full)
}

func newToken() (string, error) {
	const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	buf := make([]byte, 8)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	out := make([]byte, len(buf))
	for i, b := range buf {
		out[i] = alphabet[int(b)%len(alphabet)]
	}
	return string(out), nil
}

func sanitize(id string) string {
	var b strings.Builder
	for _, r := range id {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '-' {
			b.WriteRune(r)
		}
	}
	if b.Len() == 0 {
		return "appeal"
	}
	return b.String()
}

func extension(data []byte, filename string) string {
	if len(data) >= 8 && string(data[:8]) == "\x89PNG\r\n\x1a\n" {
		return ".png"
	}
	if len(data) >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
		return ".jpg"
	}
	ext := strings.ToLower(filepath.Ext(filename))
	if ext == ".jpg" || ext == ".jpeg" || ext == ".png" {
		if ext == ".jpeg" {
			return ".jpg"
		}
		return ext
	}
	return ".img"
}
