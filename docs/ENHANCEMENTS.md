# PlayNow — Enhancement Backlog
_Updated: 2026-04-18_

Grouped by effort (S = small, M = medium, L = large). Items marked ⚡ are high-value / low-risk.

---

## Security

| # | Effort | Item |
|---|---|---|
| S-01 | S ⚡ | Migrate secrets to `dotnet user-secrets` (dev) and environment variables (prod). `appsettings.Development.json` is already gitignored — move DB password, JWT key, Gmail app-password there. |
| S-02 | S ⚡ | Strengthen JWT key to ≥ 64 random bytes; store in user-secrets. |
| S-03 | M | Add `AspNetCoreRateLimit` (NuGet) to throttle `POST /api/auth/login` and `POST /api/auth/register` (5 req/min per IP). |
| S-04 | M | Add account lockout: after 5 failed logins lock user for 15 min, store `LockoutUntil` column on `users`. |
| S-05 | L | Introduce refresh tokens: short-lived JWTs (15 min) + long-lived refresh token stored in `refresh_tokens` table. |
| S-06 | S | Use `Path.GetFullPath` to resolve the Firebase SDK JSON path at startup instead of the relative `"firebase-adminsdk.json"` string. |

---

## Backend — API Quality

| # | Effort | Item |
|---|---|---|
| B-01 | S ⚡ | Add `[MaxLength]` / `[Required]` data annotations to all DTOs (currently no server-side length validation). |
| B-02 | S ⚡ | `SessionsController.Cancel`: add ownership check — only the venue owner or admin should be able to cancel a session. |
| B-03 | S | Replace string status literals (`"open"`, `"full"`, `"cancelled"`, `"reserved"`) with a shared `SessionStatus` / `BookingStatus` enum to prevent typos. |
| B-04 | M | Add `ETag` / `Last-Modified` headers to `GET /api/venues/{id}` for conditional GET caching. |
| B-05 | M | Add `GET /api/venues/{id}/sessions` so the Flutter app doesn't need to filter the global sessions list by venueId on every venue-detail page load. |
| B-06 | M | Extract a `UserService` for all user-lookup logic shared between Auth and other controllers. |
| B-07 | L | Implement file upload for venue photos/videos: accept `multipart/form-data`, store on Azure Blob Storage or S3, return CDN URL. Currently media is URL-only. |
| B-08 | L | Add an `admin/stats` endpoint: total users, venues, sessions, revenue for the admin dashboard. |

---

## Backend — Data & Performance

| # | Effort | Item |
|---|---|---|
| D-01 | S ⚡ | Run Phase 1 migrations: `AddBilingualFieldsAndIndexes` and `AddVenueMediaTables`. Indexes on `sessions.starts_at`, `sessions.Status`, and `match_bookings.requested_by_user_id` will significantly improve query performance. |
| D-02 | S | Add a composite index `(venue_id, starts_at)` on `sessions` to speed up venue-detail session list. |
| D-03 | M | Replace `decimal(65,30)` (EF Core default) on price columns with `decimal(10,2)` — more appropriate for currency, saves storage. Requires a migration with data cast. |
| D-04 | M | Add a `Payments` soft-delete / archival strategy: currently payments are never deleted. Add a periodic cleanup or archive job. |

---

## Flutter — UX

| # | Effort | Item |
|---|---|---|
| F-01 | S ⚡ | `HomeScreen`: Add "All Cities" city filter chip rail (extract distinct cities from the loaded venue list). Already noted in audit as missing. |
| F-02 | S ⚡ | `AdminScreen`: Add empty state widget for "No pending venues" (currently shows a blank list). |
| F-03 | S ⚡ | `NotificationsScreen`: Add error state (currently only shows empty state). |
| F-04 | S | Move the base URL (`http://10.0.2.2:5147`) out of `ApiClient` into `--dart-define=API_BASE_URL=...` so physical device builds don't need a code change. |
| F-05 | M | Add pull-to-refresh on `HomeScreen`, `GamesScreen`, and `NotificationsScreen`. |
| F-06 | M | `VenueDetailScreen`: Show a map pin (using existing `flutter_map`) on the Info tab when `venue.latitude != null`. |
| F-07 | M | Add a skeleton loading shimmer (package: `shimmer`) to replace `CircularProgressIndicator` on venue cards while the list loads. |
| F-08 | M | Persist the last-viewed venue tab (`Info` / `Sessions` / `Book Match`) in session state so navigating back doesn't reset it. |
| F-09 | L | Add deep-link support (`go_router`): `playnow://venue/42`, `playnow://session/123` so FCM notification taps land on the right screen. |
| F-10 | L | Implement paginated infinite-scroll on `GamesScreen` (currently loads all sessions; will be slow with 300+ sessions from seed data). |

---

## Flutter — Localization

| # | Effort | Item |
|---|---|---|
| L-01 | S ⚡ | Extract remaining ~40 hardcoded strings — primarily country names and phone dial codes in `login_screen.dart`. Consider generating the country list from a JSON asset instead of hardcoding strings. |
| L-02 | S | Add `textDirection: TextDirection.rtl` guard on any `Row` that contains icons + text and doesn't auto-flip with `Directionality`. |
| L-03 | M | RTL audit: verify all `EdgeInsets.only(left/right: ...)` are replaced with `EdgeInsetsDirectional.only(start/end: ...)` so padding mirrors correctly in Arabic. |

---

## Flutter — Code Quality

| # | Effort | Item |
|---|---|---|
| C-01 | S ⚡ | Extract a reusable `StatusChip` widget (used in at least 5 screens with duplicated color-mapping logic). |
| C-02 | S | Extract a `ConfirmDialog` helper (used in 8+ places with near-identical dialog code). |
| C-03 | S | Replace `TextEditingController(text: user.email)` in `ProfileScreen` (creates a new controller on every rebuild) with a properly initialized `late final` field. |
| C-04 | M | Extract a `SessionCard` widget shared between `GamesScreen` and `VenueDashboardScreen`. |
| C-05 | M | Add a `BaseScreen` mixin or `LoadableState` base class to standardize the `_loading / _error` state pattern repeated in every screen. |

---

## Testing (Phase 4)

| # | Effort | Item |
|---|---|---|
| T-01 | M ⚡ | Backend: Integration tests for auth flow (register → login → me) using `WebApplicationFactory<Program>` + in-memory SQLite. |
| T-02 | M ⚡ | Backend: Integration tests for session join / cancel flow covering the status transition (`open → full → open`). |
| T-03 | M | Backend: Unit test `ReminderBackgroundService.SendRemindersAsync` with a mocked `AppDbContext` + `IEmailService` to verify the fixed parentheses logic. |
| T-04 | M | Backend: Test ownership guards — verify a `venue` role user cannot `PUT /api/venues/{other_owner_id}`. |
| T-05 | M | Flutter: Widget tests for `ThemeService` (persist/load round-trip via mocked `SharedPreferences`). |
| T-06 | L | Flutter: Integration tests for the booking flow using `flutter_test` + `integration_test` package. |
