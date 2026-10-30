# Plate font approximations

Official plate typefaces are proprietary / restricted. Plate Vault uses
**google_fonts** stand-ins — never redistributed RoadNumbers, FE-Schrift, or
Charles Wright binaries.

| Country | Real typeface (approx.) | App font key | google_fonts |
|---------|-------------------------|--------------|--------------|
| RU | ГОСТ «дорожные номера» / RoadNumbers-like | `ruGostApprox` | Roboto Condensed |
| BY / KZ | same CIS family | `ruGostApprox` | Roboto Condensed |
| DE | FE-Schrift | `deFeApprox` | Roboto Condensed |
| UA / PL / FR / IT / ES / TR | DIN / Euro Plate | `dinApprox` | Roboto Condensed |
| GB / UK | Charles Wright | `ukCharlesApprox` | Oswald |
| US | state block | `usBlock` | Oswald |
| GEN | generic | `dinApprox` | Roboto Condensed |

Visual fidelity flags live on `PlateVisualSpec.fidelity`:
- `authentic` — RU white ГОСТ layout tuned first
- `approximate` — EU blue-strip / CIS cousins
- `placeholder` — US / TR / generic until detailed templates land
