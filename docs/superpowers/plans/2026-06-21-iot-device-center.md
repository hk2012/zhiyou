# IoT Device Center Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a responsive, fully interactive device center for smart tackle boxes, umbrellas, and platforms, backed by simulated command receipts and extensible device APIs.

**Architecture:** Extend the FastAPI device domain with capabilities, commands, scenes, binding, settings, and firmware operations. Add a dedicated Flutter `features/devices` module with repository, Riverpod application state, responsive screens, shared device primitives, and device-specific panels.

**Tech Stack:** Flutter 3 / Dart, Riverpod, GoRouter, Dio, FastAPI, SQLAlchemy, Pydantic, pytest.

---

### Task 1: Device command and capability backend

**Files:**
- Modify: `backend/app/db/models.py`
- Modify: `backend/app/schemas/devices.py`
- Modify: `backend/app/services/device_service.py`
- Modify: `backend/app/api/v1/devices.py`
- Modify: `backend/app/api/router.py`
- Test: `backend/tests/test_devices_api.py`

- [ ] Add failing tests for capability lookup, settings updates, ordinary commands, dangerous confirmation, command lookup, binding, unbinding, scenes, scene execution, and firmware upgrades.
- [ ] Run `backend/.venv/bin/pytest backend/tests/test_devices_api.py -q` and verify the new tests fail because endpoints do not exist.
- [ ] Add focused SQLAlchemy models for product models, capabilities, commands, receipts, scenes, and actions.
- [ ] Add Pydantic request/response contracts with explicit command status and danger levels.
- [ ] Implement the simulated command state machine and persist command timelines.
- [ ] Implement routes and service methods.
- [ ] Run the device API tests and the complete backend suite.
- [ ] Commit with `feat: add device command and scene APIs`.

### Task 2: Flutter device data and application state

**Files:**
- Create: `lib/features/devices/data/device_center_models.dart`
- Create: `lib/features/devices/data/device_center_repository.dart`
- Create: `lib/features/devices/data/device_center_demo_data.dart`
- Create: `lib/features/devices/application/device_center_controller.dart`
- Create: `test/features/devices/device_center_models_test.dart`
- Create: `test/features/devices/device_center_controller_test.dart`

- [ ] Write failing parser and controller tests for capabilities, command receipts, scenes, API source, fallback source, and optimistic command updates.
- [ ] Run the focused Flutter tests and verify RED.
- [ ] Implement immutable DTOs and repository methods for every new API.
- [ ] Implement Riverpod state for list, detail, commands, tabs, filters, scenes, and fallback.
- [ ] Run focused tests and refactor while green.
- [ ] Commit with `feat: add device center data layer`.

### Task 3: Shared responsive device UI

**Files:**
- Create: `lib/features/devices/view/widgets/device_shell.dart`
- Create: `lib/features/devices/view/widgets/device_components.dart`
- Create: `lib/features/devices/view/widgets/device_command_status.dart`
- Create: `lib/features/devices/view/widgets/device_charts.dart`
- Test: `test/features/devices/device_components_test.dart`

- [ ] Write failing widget tests for phone, tablet, and desktop shell modes plus stable command status rendering.
- [ ] Implement common headers, status indicators, metric rows, segmented tabs, control rows, telemetry charts, confirmation dialogs, and responsive panes.
- [ ] Keep controls keyboard accessible and motion respectful of reduced-motion preferences.
- [ ] Run focused tests.
- [ ] Commit with `feat: add responsive device ui primitives`.

### Task 4: Device center and support screens

**Files:**
- Create: `lib/features/devices/view/device_center_screen.dart`
- Create: `lib/features/devices/view/device_binding_screen.dart`
- Create: `lib/features/devices/view/device_scenes_screen.dart`
- Create: `lib/features/devices/view/device_alerts_screen.dart`
- Create: `lib/features/devices/view/device_command_screen.dart`
- Test: `test/features/devices/device_center_screen_test.dart`

- [ ] Write failing tests for health summary, abnormal filter, device selection, add-device flow, scene execution, alert list, and command timeline.
- [ ] Implement mobile single-column, tablet dual-pane, and desktop three-pane layouts.
- [ ] Implement simulated scan/discovery binding flow and scene execution feedback.
- [ ] Run focused tests.
- [ ] Commit with `feat: build device center workflows`.

### Task 5: Three detailed device experiences

**Files:**
- Create: `lib/features/devices/view/device_detail_screen.dart`
- Create: `lib/features/devices/view/device_panels/tackle_box_panel.dart`
- Create: `lib/features/devices/view/device_panels/umbrella_panel.dart`
- Create: `lib/features/devices/view/device_panels/platform_panel.dart`
- Create: `test/features/devices/device_detail_screen_test.dart`

- [ ] Write failing tests for the four common tabs and each device's primary controls.
- [ ] Implement tackle-box temperature, cooling, lock, lighting, USB, freshness, trend, alerts, calibration, and firmware controls.
- [ ] Implement umbrella open/close, tilt, wind threshold, auto-close, sun tracking, rain response, events, battery, and firmware controls.
- [ ] Implement platform level, four-leg adjustment, load, stability, safety lock, emergency stop, calibration, diagnostics, and firmware controls.
- [ ] Require confirmation for lock, close umbrella, emergency stop, unbind, and firmware update.
- [ ] Run focused tests.
- [ ] Commit with `feat: add detailed smart device controls`.

### Task 6: Routing and product integration

**Files:**
- Modify: `lib/routes/app_route_names.dart`
- Modify: `lib/routes/app_router.dart`
- Modify: `lib/features/home/view/home_screen.dart`
- Modify: `lib/features/profile/view/profile_screen.dart`
- Modify: `lib/features/main_shell/view/main_shell_screen.dart`
- Test: `test/features/devices/device_navigation_test.dart`

- [ ] Write failing navigation tests for home/profile entry, device detail, add device, scenes, alerts, and command result.
- [ ] Register all routes under the root navigator.
- [ ] Replace legacy device summary actions with device center navigation.
- [ ] Let the desktop shell use available width instead of forcing a phone canvas.
- [ ] Run navigation and regression tests.
- [ ] Commit with `feat: integrate device center navigation`.

### Task 7: Cleanup, naming, and maintainability

**Files:**
- Modify: `.gitignore`
- Modify: relevant large Flutter files only where device blocks are extracted
- Modify: `backend/app/db/models.py`
- Modify: `backend/app/db/seed.py`
- Create: `backend/app/db/device_models.py` or focused seed modules if needed

- [ ] Remove only confirmed unused font assets and generated local artifacts.
- [ ] Keep conditionally imported location readers.
- [ ] Extract device responsibilities out of home/profile without unrelated redesign.
- [ ] Add concise Chinese comments to domain boundaries and dangerous command logic.
- [ ] Ensure user-visible branding says “江湖钓客”.
- [ ] Run static reachability checks and full tests.
- [ ] Commit with `refactor: isolate device domain and remove stale assets`.

### Task 8: Verification, screenshots, and completion report

**Files:**
- Create: `design-qa.md`
- Create: blog completion article under `/Users/hongkuan/Desktop/mydir/blog/source/_posts/doc/`
- Create: blog evidence assets under `/Users/hongkuan/Desktop/mydir/blog/source/images/`

- [ ] Run backend pytest, Flutter analyze, Flutter tests, and Flutter Web build.
- [ ] Start backend and Flutter Web through project scripts.
- [ ] Capture 390px, 768px, and 1440px screenshots for device center and all three detail pages.
- [ ] Compare implementation screenshots against the three approved reference images and fix P0/P1/P2 mismatches.
- [ ] Record the comparison in `design-qa.md` with `final result: passed`.
- [ ] Create a completion workflow diagram, implementation animation, and before/after image set.
- [ ] Write and build the completion report blog article.
- [ ] Commit and push the app branch.
- [ ] Commit, push, and publish the blog article without including unrelated blog worktree changes.

