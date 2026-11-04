package inbox

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCreateAndDecide(t *testing.T) {
	dir := t.TempDir()
	store, err := Open(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(store.Token()) != 8 {
		t.Fatalf("token %q", store.Token())
	}
	jpeg := []byte{0xFF, 0xD8, 0xFF, 0xD9}
	saved, err := store.Create(Appeal{
		ID:              "appeal-1",
		PlateItemID:     "plate-1",
		CountryCode:     "ru",
		ScannedNumber:   "A123BC77",
		CorrectedNumber: "А123ВС77",
	}, []Upload{{Filename: "wide.jpg", Bytes: jpeg}})
	if err != nil {
		t.Fatal(err)
	}
	if saved.Status != StatusPending {
		t.Fatalf("status %s", saved.Status)
	}
	if saved.CountryCode != "RU" {
		t.Fatalf("country %s", saved.CountryCode)
	}
	if len(saved.Photos) != 1 {
		t.Fatalf("photos %#v", saved.Photos)
	}
	again, err := store.Create(Appeal{
		ID:              "appeal-1",
		ScannedNumber:   "A123BC77",
		CorrectedNumber: "OTHER",
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if again.CorrectedNumber != "А123ВС77" {
		t.Fatalf("duplicate changed the number to %s", again.CorrectedNumber)
	}
	photo, err := os.ReadFile(filepath.Join(dir, saved.Photos[0].Path))
	if err != nil {
		t.Fatal(err)
	}
	if photo[0] != 0xFF {
		t.Fatal("photo bytes were not written")
	}
	decided, err := store.Decide("appeal-1", StatusApproved)
	if err != nil {
		t.Fatal(err)
	}
	if decided.Status != StatusApproved || decided.DecidedAt == "" {
		t.Fatalf("decision %#v", decided)
	}
	reopened, err := Open(dir)
	if err != nil {
		t.Fatal(err)
	}
	if got, ok := reopened.Get("appeal-1"); !ok || got.Status != StatusApproved {
		t.Fatalf("reload %#v %v", got, ok)
	}
}

func TestRejectsEmptyNumbers(t *testing.T) {
	store, err := Open(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	_, err = store.Create(Appeal{ID: "x", ScannedNumber: "  ", CorrectedNumber: "A1"}, nil)
	if err == nil {
		t.Fatal("expected error")
	}
}
