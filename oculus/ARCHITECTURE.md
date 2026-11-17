# Oculus — Architecture

## Goal

Legal, authorized security toolbox for **own / whitelisted** targets.
Windows `.exe` with a dark-blue GUI. No exploits, malware, DDoS against third parties.

## Stack choice

| Option | Pros | Cons |
|--------|------|------|
| **Python + PySide6 (chosen)** | Fast module development (DNS/HTTP/TLS), rich Qt widgets, animations, packaging via PyInstaller → `.exe`, works on this Linux CI/dev host with offscreen/Qt | Larger binary; needs PyInstaller for Windows |
| C# / WPF | Native Windows look | Hard to build/test on Linux agent; slower iteration for network modules |
| Electron | Familiar web UI | Heavy runtime; overkill for scanners |

**Decision:** Python 3.12 + **PySide6** + worker `QThread`s + PyInstaller for Windows exe.

## Package layout

```
oculus/
  ARCHITECTURE.md
  README.md
  requirements.txt
  main.py                 # entrypoint
  build_windows.bat       # PyInstaller helper
  oculus_app/
    __init__.py
    app.py                # QApplication bootstrap
    config.py             # paths, theme constants, first-run flag
    theme.py              # dark-blue QSS
    permissions.py        # first-run consent (network/files)
    audio.py              # click / bubble sounds
    core/
      scope.py            # whitelist manager
      workers.py          # base async worker
      results.py          # shared result models
    ui/
      main_window.py
      sidebar.py
      widgets.py          # RoundedButton + press animation
      pages/
        home.py
        recon.py
        scanners.py
        web_checks.py
        ssl_page.py
        bruteforce.py
        loadtest.py
        reports.py
        settings_perms.py
    modules/
      recon.py            # DNS, WHOIS, subdomains
      portscan.py
      webscan.py          # safe detection only
      sslcheck.py
      bruteforce.py       # dictionary, rate-limited
      loadtest.py         # controlled RPS for own hosts
      reports.py          # HTML/PDF
  assets/
    icons/
    images/
    sounds/
  tests/
```

## UI flow

1. First launch → permissions dialog (network + write reports).
2. Until accepted → module buttons disabled.
3. Left **drawer** sidebar (icons + labels) → section pages.
4. Each page: rounded buttons with captions → start worker → log + results → Reports.

## Safety invariants

- Every network module checks `Scope.allows(target)`.
- Load test: hard RPS/concurrency caps + kill switch.
- Web SQLi/XSS: **detection heuristics / canary reflection only** — no exploit payloads.
- Bruteforce: rate limit, lockout detection, stop-on-success.
- Sounds/animations are cosmetic and optional.
