# Device Center Design QA

## Scope

- Approved references:
  - `/Users/hongkuan/Desktop/mydir/blog/source/images/zhiyou-system-audit-20260620/device-tackle-box-detail.png`
  - `/Users/hongkuan/Desktop/mydir/blog/source/images/zhiyou-system-audit-20260620/device-umbrella-detail.png`
  - `/Users/hongkuan/Desktop/mydir/blog/source/images/zhiyou-system-audit-20260620/device-platform-detail.png`
- Render method: local release Flutter Web build, Chrome DevTools Protocol screenshots.
- API: local FastAPI at `http://127.0.0.1:8080`.

## Viewports

- Mobile: 390 x 844.
- Tablet: 768 x 1024.
- Desktop: 1440 x 1000.

## Comparison Ledger

| Area | Reference | Render evidence | Result |
| --- | --- | --- | --- |
| Information hierarchy | Device name, online state, battery and signal lead the page | All three detail pages use the same header hierarchy | Passed |
| Common navigation | Four tabs: status, control, automation, maintenance | Four stable tabs render at 390px without wrapping | Passed |
| Tackle box | Temperature, cooling mode, lock, light, USB and freshness | Mobile render contains temperature slider, segmented cooling control and toggles | Passed |
| Umbrella | Weather state, open/close, tilt, wind threshold and automation | Mobile render contains three environment metrics and safety controls | Passed |
| Platform | Level, four-leg adjustment, load, safety lock and emergency stop | Mobile render contains level and leg controls; lower safety controls remain scroll-accessible | Passed |
| Responsive layout | Mobile single column, tablet dual pane, desktop three pane | Captures show 390 single, 768 dual and 1440 three-column layouts | Passed |
| Density and typography | Short labels and clear emphasis | Labels remain concise; no clipped primary text or button labels | Passed |
| Color and component system | White surfaces, teal action color, restrained warning orange | Palette and semantic warning colors match the approved direction | Passed |
| Interaction feedback | Dangerous confirmation and visible execution receipt | API and widget tests cover confirmation; command route exposes timeline and command id | Passed |
| Source transparency | Real API versus demo fallback is visible | Device header and center show `实时 API` or `本地演示` | Passed |

## Functional Verification

- Backend tests: 42 passed.
- Flutter tests: 11 passed.
- Flutter analyze: no issues.
- Flutter Web release build: passed.
- Dangerous command smoke test:
  - unconfirmed umbrella close -> `awaiting_confirmation`
  - confirmed umbrella close -> `queued -> sent -> acknowledged -> succeeded`

## Intentional Boundaries

- MQTT, BLE and vendor cloud adapters are not faked. This release uses persisted simulated receipts behind the same command contract.
- Device product photography remains outside the interactive control surface; the app uses the existing icon system so controls remain code-native and responsive.

final result: passed
