// Plate Vault appeal review.
//
// The owner's Windows program. Collectors send a scanned plate number, a
// corrected number, and the plate photos from the phone app. This window
// lists those appeals so the owner can approve or reject them later.
//
// Build the Windows exe from this directory:
//
//	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags "-H windowsgui -s -w" -o dist/PlateVaultAppeals.exe .
//
// Double-click PlateVaultAppeals.exe. Appeals and the access code are stored
// in a data folder next to the exe. The phone must reach this computer on
// the same network (default port 8787).
package main

import (
	"bytes"
	"fmt"
	"image"
	"image/color"
	_ "image/jpeg"
	_ "image/png"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"gioui.org/app"
	"gioui.org/font/gofont"
	"gioui.org/layout"
	"gioui.org/op"
	"gioui.org/op/paint"
	"gioui.org/text"
	"gioui.org/unit"
	"gioui.org/widget"
	"gioui.org/widget/material"

	"github.com/romangolotvin/plate-vault/desktop/appeal-review/internal/inbox"
	"github.com/romangolotvin/plate-vault/desktop/appeal-review/internal/server"
)

func main() {
	logPath := ""
	data, err := dataDir()
	if err == nil {
		_ = os.MkdirAll(data, 0o755)
		logPath = filepath.Join(data, "app.log")
		if f, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644); err == nil {
			log.SetOutput(f)
		}
	}
	store, err := inbox.Open(data)
	if err != nil {
		log.Fatalf("inbox: %v", err)
	}
	handler := server.Handler(store)
	listener, listenErr := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", store.Port()))

	go func() {
		window := new(app.Window)
		window.Option(
			app.Title("Plate Vault — обжалования"),
			app.Size(unit.Dp(1100), unit.Dp(740)),
			app.MinSize(unit.Dp(860), unit.Dp(560)),
		)
		ui := newUI(store, listener, listenErr)
		store.OnChange = func() { window.Invalidate() }
		if listener != nil {
			go func() {
				if err := http.Serve(listener, handler); err != nil {
					log.Printf("http: %v", err)
				}
			}()
		}
		if err := ui.run(window); err != nil {
			log.Printf("window: %v", err)
		}
		if listener != nil {
			_ = listener.Close()
		}
		os.Exit(0)
	}()
	app.Main()
}

func dataDir() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	return filepath.Join(filepath.Dir(exe), "data"), nil
}

type deskUI struct {
	store      *inbox.Store
	theme      *material.Theme
	list       widget.List
	rows       []widget.Clickable
	approve    widget.Clickable
	reject     widget.Clickable
	selected   int
	listenLine string
	tokenEdit  widget.Editor
	images     map[string]image.Image
}

func newUI(store *inbox.Store, listener net.Listener, listenErr error) *deskUI {
	th := material.NewTheme()
	th.Shaper = text.NewShaper(text.WithCollection(gofont.Collection()))
	th.Palette.Bg = color.NRGBA{R: 12, G: 10, B: 18, A: 255}
	th.Palette.Fg = color.NRGBA{R: 243, G: 236, B: 248, A: 255}
	th.Palette.ContrastBg = color.NRGBA{R: 181, G: 107, B: 255, A: 255}
	th.Palette.ContrastFg = color.NRGBA{R: 18, G: 8, B: 32, A: 255}
	line := listenLine(listener, listenErr, store.Port())
	ui := &deskUI{
		store:      store,
		theme:      th,
		list:       widget.List{List: layout.List{Axis: layout.Vertical}},
		listenLine: line,
		images:     map[string]image.Image{},
	}
	ui.tokenEdit.SingleLine = true
	ui.tokenEdit.ReadOnly = true
	ui.tokenEdit.SetText(store.Token())
	return ui
}

func (u *deskUI) run(window *app.Window) error {
	var ops op.Ops
	for {
		switch e := window.Event().(type) {
		case app.DestroyEvent:
			return e.Err
		case app.FrameEvent:
			gtx := app.NewContext(&ops, e)
			u.layout(gtx)
			e.Frame(gtx.Ops)
		}
	}
}

func (u *deskUI) layout(gtx layout.Context) layout.Dimensions {
	appeals := u.store.List()
	if u.selected >= len(appeals) {
		u.selected = 0
	}
	if len(u.rows) < len(appeals) {
		extra := make([]widget.Clickable, len(appeals)-len(u.rows))
		u.rows = append(u.rows, extra...)
	}
	paint.Fill(gtx.Ops, u.theme.Palette.Bg)
	return layout.Flex{Axis: layout.Vertical}.Layout(gtx,
		layout.Rigid(func(gtx layout.Context) layout.Dimensions {
			return layout.UniformInset(unit.Dp(16)).Layout(gtx, func(gtx layout.Context) layout.Dimensions {
				return layout.Flex{Axis: layout.Vertical}.Layout(gtx,
					layout.Rigid(material.H6(u.theme, "Обжалования номеров").Layout),
					layout.Rigid(layout.Spacer{Height: unit.Dp(6)}.Layout),
					layout.Rigid(material.Body2(u.theme, u.listenLine).Layout),
					layout.Rigid(layout.Spacer{Height: unit.Dp(4)}.Layout),
					layout.Rigid(func(gtx layout.Context) layout.Dimensions {
						return layout.Flex{Alignment: layout.Middle}.Layout(gtx,
							layout.Rigid(material.Body1(u.theme, "Код доступа  ").Layout),
							layout.Flexed(1, material.Editor(u.theme, &u.tokenEdit, "").Layout),
						)
					}),
					layout.Rigid(material.Caption(u.theme, "Телефон и этот компьютер должны быть в одной сети. Разрешите программу в брандмауэре Windows, если телефон не подключается.").Layout),
				)
			})
		}),
		layout.Flexed(1, func(gtx layout.Context) layout.Dimensions {
			return layout.Flex{}.Layout(gtx,
				layout.Rigid(func(gtx layout.Context) layout.Dimensions {
					gtx.Constraints.Min.X = gtx.Dp(unit.Dp(280))
					gtx.Constraints.Max.X = gtx.Dp(unit.Dp(320))
					if len(appeals) == 0 {
						return layout.UniformInset(unit.Dp(16)).Layout(gtx,
							material.Body1(u.theme, "Пока пусто. Заявления появятся здесь, когда их отправят из приложения.").Layout,
						)
					}
					return u.list.Layout(gtx, len(appeals), func(gtx layout.Context, i int) layout.Dimensions {
						if u.rows[i].Clicked(gtx) {
							u.selected = i
						}
						label := appeals[i].CorrectedNumber
						if label == "" {
							label = appeals[i].ScannedNumber
						}
						title := fmt.Sprintf("%s · %s", label, statusRu(appeals[i].Status))
						btn := material.Button(u.theme, &u.rows[i], title)
						if i == u.selected {
							btn.Background = u.theme.Palette.ContrastBg
							btn.Color = u.theme.Palette.ContrastFg
						} else {
							btn.Background = color.NRGBA{R: 28, G: 21, B: 40, A: 255}
							btn.Color = u.theme.Palette.Fg
						}
						return layout.UniformInset(unit.Dp(6)).Layout(gtx, btn.Layout)
					})
				}),
				layout.Flexed(1, func(gtx layout.Context) layout.Dimensions {
					if len(appeals) == 0 {
						return layout.Dimensions{Size: gtx.Constraints.Max}
					}
					return u.detail(gtx, appeals[u.selected])
				}),
			)
		}),
	)
}

func (u *deskUI) detail(gtx layout.Context, appeal inbox.Appeal) layout.Dimensions {
	if u.approve.Clicked(gtx) {
		_, _ = u.store.Decide(appeal.ID, inbox.StatusApproved)
	}
	if u.reject.Clicked(gtx) {
		_, _ = u.store.Decide(appeal.ID, inbox.StatusRejected)
	}
	return layout.UniformInset(unit.Dp(20)).Layout(gtx, func(gtx layout.Context) layout.Dimensions {
		return layout.Flex{Axis: layout.Vertical}.Layout(gtx,
			layout.Rigid(material.H5(u.theme, appeal.CorrectedNumber).Layout),
			layout.Rigid(layout.Spacer{Height: unit.Dp(8)}.Layout),
			layout.Rigid(material.Body1(u.theme, "Как распознано: "+appeal.ScannedNumber).Layout),
			layout.Rigid(material.Body1(u.theme, "Скорректированный номер: "+appeal.CorrectedNumber).Layout),
			layout.Rigid(material.Body2(u.theme, fmt.Sprintf("%s · %s · %s", appeal.CountryCode, statusRu(appeal.Status), appeal.ReceivedAt)).Layout),
			layout.Rigid(layout.Spacer{Height: unit.Dp(12)}.Layout),
			layout.Rigid(func(gtx layout.Context) layout.Dimensions {
				if len(appeal.Photos) == 0 {
					return material.Body1(u.theme, "Фото нет.").Layout(gtx)
				}
				return layout.Flex{Axis: layout.Horizontal}.Layout(gtx, u.photoFlex(appeal)...)
			}),
			layout.Rigid(layout.Spacer{Height: unit.Dp(16)}.Layout),
			layout.Rigid(func(gtx layout.Context) layout.Dimensions {
				return layout.Flex{}.Layout(gtx,
					layout.Rigid(material.Button(u.theme, &u.approve, "Принять").Layout),
					layout.Rigid(layout.Spacer{Width: unit.Dp(12)}.Layout),
					layout.Rigid(func(gtx layout.Context) layout.Dimensions {
						btn := material.Button(u.theme, &u.reject, "Отклонить")
						btn.Background = color.NRGBA{R: 90, G: 40, B: 58, A: 255}
						return btn.Layout(gtx)
					}),
				)
			}),
		)
	})
}

func (u *deskUI) photoFlex(appeal inbox.Appeal) []layout.FlexChild {
	children := make([]layout.FlexChild, 0, len(appeal.Photos))
	for _, photo := range appeal.Photos {
		photo := photo
		children = append(children, layout.Rigid(func(gtx layout.Context) layout.Dimensions {
			img := u.photo(photo.Path)
			gtx.Constraints.Max.X = gtx.Dp(unit.Dp(280))
			gtx.Constraints.Max.Y = gtx.Dp(unit.Dp(200))
			if img == nil {
				return material.Body2(u.theme, "Не удалось показать "+photo.Name).Layout(gtx)
			}
			op := paint.NewImageOp(img)
			view := widget.Image{Src: op, Fit: widget.Contain, Scale: 1}
			return view.Layout(gtx)
		}))
	}
	return children
}

func (u *deskUI) photo(rel string) image.Image {
	if img, ok := u.images[rel]; ok {
		return img
	}
	raw, err := u.store.ReadPhoto(rel)
	if err != nil {
		u.images[rel] = nil
		return nil
	}
	img, _, err := image.Decode(bytes.NewReader(raw))
	if err != nil {
		u.images[rel] = nil
		return nil
	}
	u.images[rel] = img
	return img
}

func statusRu(status inbox.Status) string {
	switch status {
	case inbox.StatusApproved:
		return "Принято"
	case inbox.StatusRejected:
		return "Отклонено"
	default:
		return "На рассмотрении"
	}
}

func listenLine(listener net.Listener, listenErr error, port int) string {
	if listenErr != nil {
		return "Не удалось открыть порт: " + listenErr.Error()
	}
	ips := lanIPv4()
	if len(ips) == 0 {
		return fmt.Sprintf("Слушает http://127.0.0.1:%d", port)
	}
	parts := make([]string, 0, len(ips))
	for _, ip := range ips {
		parts = append(parts, fmt.Sprintf("http://%s:%d", ip, port))
	}
	_ = listener
	return "Адрес для телефона: " + strings.Join(parts, "   ")
}

func lanIPv4() []string {
	ifaces, err := net.Interfaces()
	if err != nil {
		return nil
	}
	var ips []string
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			ip = ip.To4()
			if ip == nil || ip.IsLoopback() {
				continue
			}
			ips = append(ips, ip.String())
		}
	}
	return ips
}
