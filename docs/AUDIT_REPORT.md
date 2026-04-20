# PlayNow — Audit Report
_Generated: 2026-04-18_

---

## Executive Summary — Top 10 Critical Issues

| # | Severity | Issue | Location |
|---|---|---|---|
| 1 | CRITICAL | Hardcoded secrets (DB password, JWT key, Gmail password) in appsettings.json | `appsettings.json:3,6,22` |
| 2 | CRITICAL | CORS AllowAnyOrigin + AllowAnyMethod + AllowAnyHeader | `Program.cs:90-98` |
| 3 | CRITICAL | Logic error in ReminderBackgroundService — missing parentheses breaks time-window filter | `ReminderBackgroundService.cs:45` |
| 4 | HIGH | Missing index on `sessions.starts_at` (queried constantly) | `AppDbContext`, `SessionsController.cs:48,52` |
| 5 | HIGH | Null-bang `!` on User claims in every controller — throws NullReferenceException if claim missing | `AuthController.cs:93,118`, `SessionsController.cs:31`, `VenuesController.cs:24,109,199`, `MatchBookingsController.cs:30`, `NotificationsController.cs:23` |
| 6 | HIGH | Duplicate `List()` method in PitchesController (lines 23-57 and 58-77, same route) | `PitchesController.cs:23-77` |
| 7 | HIGH | Firebase credentials path hardcoded as relative `"firebase-adminsdk.json"` | `AuthController.cs:139` |
| 8 | MEDIUM | JWT key is a weak placeholder, only ~48 chars (recommended ≥ 64 for HS256) | `appsettings.json:6` |
| 9 | MEDIUM | Missing ownership check on `PUT /api/venues/{id}` — any venue-role user can edit any venue | `VenuesController.cs` |
| 10 | MEDIUM | 214 hardcoded `Text('...')` strings in Flutter; ~40 genuine untranslated strings (mostly country names/phone hints) | `login_screen.dart`, `admin_screen.dart`, etc. |

---

## 1. Backend Audit

### 1.1 Controllers & Routes

#### AuthController (`Controllers/AuthController.cs`)
| Route | Auth | Issues |
|---|---|---|
| `POST /api/auth/register` | Public | No null check on user after creation |
| `POST /api/auth/login` | Public | ✓ |
| `GET /api/auth/me` | `[Authorize]` | Null-bang on claim (line 93) |
| `PUT /api/auth/profile` | `[Authorize]` | Null-bang on claim (line 118) |
| `POST /api/auth/phone-login` | Public | ✓ |
| `DELETE /api/auth/delete/{id}` | `[Authorize(Roles="admin")]` | ✓ |

#### SessionsController (`Controllers/SessionsController.cs`)
| Route | Auth | Issues |
|---|---|---|
| `GET /api/sessions` | Public | Pagination ✓; missing index on `starts_at` |
| `GET /api/sessions/{id}` | Public | ✓ |
| `POST /api/sessions` | `venue,admin` | ✓ |
| `POST /api/sessions/{id}/cancel` | `venue,admin` | ✓ |
| `POST /api/sessions/{id}/join` | `player,admin` | Null-bang on claim (line 31) |
| `POST /api/sessions/{id}/cancel-join` | `player,admin` | ✓ |
| `POST /api/sessions/{id}/checkin/{userId}` | `venue,admin` | ✓ |
| `GET /api/sessions/my-bookings` | `player,venue,admin` | ✓ |
| `GET /api/sessions/{id}/players` | `venue,admin` | ✓ |

#### VenuesController (`Controllers/VenuesController.cs`)
| Route | Auth | Issues |
|---|---|---|
| `GET /api/venues` | Public | Pagination ✓ |
| `GET /api/venues/{id}` | Public | ✓ |
| `POST /api/venues` | `venue,admin` | No ownership enforced yet (single venue per owner implied but not checked) |
| `PUT /api/venues/{id}` | `venue,admin` | **Missing ownership check** — any venue-role user can edit any venue |
| `POST /api/venues/{id}/activate` | `admin` | ✓ |
| `POST /api/venues/{id}/deactivate` | `admin` | ✓ |
| `DELETE /api/venues/{id}` | `admin` | ✓ |
| `GET /api/venues/my` | `venue,admin` | Null-bang on claim (line 199) |

Line 124-125: `if (venue == null)` immediately after `new Venue { … }` — always false, dead code.

#### PitchesController (`Controllers/PitchesController.cs`)
- **CRITICAL**: Two `List()` methods defined (lines 23-57 and 58-77) with identical routes — second shadows first.
- `POST /api/pitches`, `PUT /api/pitches/{id}`, `DELETE /api/pitches/{id}` all have `[Authorize(Roles="venue,admin")]` but **no ownership check** (any venue owner can mutate any pitch).

#### MatchBookingsController (`Controllers/MatchBookingsController.cs`)
- All endpoints have appropriate authorization. Ownership validation present. ✓

#### NotificationsController (`Controllers/NotificationsController.cs`)
- All endpoints have `[Authorize]`. Ownership checks present. ✓
- Null-bang on claim at line 23.

### 1.2 N+1 Queries & Async

**Good** — all list queries use `.Include()` / `.ThenInclude()`:
- `SessionsController.cs:44-45` — includes Pitch → Venue ✓
- `SessionsController.cs:96` — includes SessionPlayers → User ✓
- `VenuesController.cs:34, 75` — includes Owner ✓

**No `.Result` or `.Wait()` found** ✓

**Logic bug (not N+1 but data correctness)**:  
`ReminderBackgroundService.cs:45`:
```csharp
// BUG: missing parentheses — second OR operand has no time-window constraint
Where(s => s.StartsAt >= windowStart && s.StartsAt < windowEnd
         && s.Status == "open" || s.Status == "full")
// Should be:
Where(s => s.StartsAt >= windowStart && s.StartsAt < windowEnd
         && (s.Status == "open" || s.Status == "full"))
```
Current code returns **all** `Status == "full"` sessions regardless of time window.

### 1.3 Missing Indexes

| Table | Column | Why Needed |
|---|---|---|
| `sessions` | `starts_at` | Filtered in every session list query and the reminder service |
| `sessions` | `status` | Frequently filtered (`open`, `full`, `cancelled`) |
| `match_bookings` | `requested_by_user_id` | Filtered in `GetVenueRequests` |

Indexes that already exist (confirmed in `AppDbContextModelSnapshot.cs`):
- `device_tokens.user_id`
- `payments.session_id`, `payments.user_id`
- `pitches.venue_id`
- `session_players.user_id`
- `sessions.created_by`, `sessions.pitch_id`
- `user_roles.role_id`
- `venues.owner_user_id`
- `app_notifications.(user_id, is_read)` (composite)

### 1.4 DTOs vs Schema Alignment

| Entity | Status | Notes |
|---|---|---|
| User | ✓ | `AuthDtos.cs` maps all user-facing fields correctly |
| Venue | ✓ | `VenueDtos.cs` includes all columns including lat/lon |
| Session | ✓ | Full alignment |
| Pitch | ✓ | Full alignment |
| MatchBooking | ✓ | Full alignment |
| Notification | ✓ | Full alignment |

No DTO/schema mismatches found beyond missing bilingual fields (planned in Phase 1).

---

## 2. Frontend Audit

### 2.1 Screen Inventory

```
lib/screens/
├── admin/
│   ├── add_venue_screen.dart
│   └── admin_screen.dart
├── auth/
│   ├── login_screen.dart
│   └── register_screen.dart
├── games/
│   └── games_screen.dart
├── home/
│   ├── home_screen.dart
│   └── venue_detail_screen.dart
├── landing_screen.dart
├── main_screen.dart
├── match_booking/
│   ├── book_match_screen.dart
│   └── my_match_bookings_screen.dart
├── notifications/
│   └── notifications_screen.dart
├── profile/
│   ├── my_bookings_screen.dart
│   └── profile_screen.dart
└── venue/
    ├── create_session_screen.dart
    ├── my_venue_screen.dart
    ├── session_players_screen.dart
    ├── venue_dashboard_screen.dart
    └── venue_match_requests_screen.dart
```

### 2.2 `context.read` in `build()` — None Found ✓

All `context.read<T>()` calls are in `initState`, handlers, or named callback methods. ✓

### 2.3 `dispose()` Coverage

`dispose()` is implemented in all `StatefulWidget`s that create `TextEditingController`, `ScrollController`, or `AnimationController`. No leaks found. ✓

### 2.4 FutureBuilder / StreamBuilder

Not used — project uses service ChangeNotifier pattern throughout. ✓

### 2.5 Loading / Error / Empty States

- `HomeScreen` — `EmptyVenuesState`, `ErrorState` widgets present ✓
- `GamesScreen` — error and empty checks present ✓
- Missing: `AdminScreen` has no empty state for pending venues list
- Missing: `NotificationsScreen` has no error state

### 2.6 ApiClient

- Base URL `http://10.0.2.2:5147/api` — hardcoded for Android emulator. Will fail on physical devices without config change. Flag for Phase 5 (move to env/config).
- Singleton pattern ✓
- 15s timeout ✓
- Bearer token injection ✓
- Error hierarchy (`NetworkException`, `TimeoutException`, `ApiException`) ✓

---

## 3. Translatable Strings Inventory

### 3.1 Statistics

| Metric | Count |
|---|---|
| Total `Text('…')` literals found | ~214 |
| Already using `AppL10n.of(context)` | ~80% of screens |
| Genuine untranslated strings needing ARB keys | ~40 |

### 3.2 Top 20 Files by Hardcoded String Density

| Rank | File | Approx. Count | Notes |
|---|---|---|---|
| 1 | `screens/auth/login_screen.dart` | 40+ | Country names + dial codes + phone hint |
| 2 | `screens/admin/admin_screen.dart` | 25+ | Status labels, action buttons |
| 3 | `screens/games/games_screen.dart` | 20+ | Session display labels |
| 4 | `screens/home/home_screen.dart` | 15+ | Filter/sort labels |
| 5 | `screens/auth/register_screen.dart` | 12+ | Form labels |
| 6 | `screens/venue/my_venue_screen.dart` | 10+ | Venue management labels |
| 7 | `screens/venue/create_session_screen.dart` | 8+ | Form labels |
| 8 | `screens/profile/my_bookings_screen.dart` | 8+ | Status chips |
| 9 | `screens/home/venue_detail_screen.dart` | 7+ | Detail labels |
| 10 | `screens/venue/venue_dashboard_screen.dart` | 6+ | Dashboard labels |
| 11 | `screens/match_booking/book_match_screen.dart` | 5+ | Form labels |
| 12 | `screens/profile/profile_screen.dart` | 5+ | Section headers |
| 13 | `screens/venue/session_players_screen.dart` | 4 | Column headers |
| 14 | `screens/notifications/notifications_screen.dart` | 4 | Empty state text |
| 15 | `screens/match_booking/my_match_bookings_screen.dart` | 3 | Status labels |
| 16 | `screens/venue/venue_match_requests_screen.dart` | 3 | Action labels |
| 17 | `screens/admin/add_venue_screen.dart` | 2 | Form labels |
| 18 | `screens/landing_screen.dart` | 2 | CTA text |
| 19 | `screens/main_screen.dart` | 1 | Nav label |
| 20 | `lib/widgets/` (various) | 5 | Shared widget labels |

### 3.3 Specific Hardcoded Strings to Extract

**login_screen.dart (country list — lines ~25-55):**
All country display names (`Jordan`, `Saudi Arabia`, `UAE`, etc.) and phone hint `"7x xxx xxxx"`, OTP mask `"······"`.

**admin_screen.dart:**
`"Pending Venues"`, `"Active"`, `"Inactive"`, `"Activate"`, `"Deactivate"`, `"No pending venues"`.

**games_screen.dart:**
Session status chips (`"open"`, `"full"`, `"cancelled"`, `"completed"`), `"players"`, `"JD"` suffix.

**home_screen.dart:**
`"Sort by"`, `"Distance"`, `"Price"`, `"Rating"`, `"Filter"`, `"All Cities"`.

---

## 4. Full Database Schema

### Tables

#### `users`
| Column | Type | Nullable | Notes |
|---|---|---|---|
| Id | int | NO | PK, AUTO_INCREMENT |
| Email | longtext | NO | |
| password_hash | longtext | NO | BCrypt hash |
| full_name | longtext | YES | |
| Phone | longtext | YES | |
| is_deleted | tinyint(1) | NO | default 0 |
| created_at | datetime(6) | NO | |

#### `roles`
| Column | Type | Nullable |
|---|---|---|
| Id | int | NO |
| Name | longtext | NO |

#### `user_roles`
| Column | Type | Notes |
|---|---|---|
| user_id | int | FK → users.Id CASCADE |
| role_id | int | FK → roles.Id CASCADE |
PK: `(user_id, role_id)`. Index: `role_id`.

#### `venues`
| Column | Type | Nullable | Notes |
|---|---|---|---|
| Id | int | NO | PK |
| owner_user_id | int | NO | FK → users.Id CASCADE. Indexed. |
| Name | longtext | NO | |
| City | longtext | YES | |
| Address | longtext | YES | |
| description | longtext | YES | |
| is_active | tinyint(1) | NO | default 0 |
| is_deleted | tinyint(1) | NO | default 0 |
| created_at | datetime(6) | NO | |
| image_url | longtext | YES | |
| Latitude | double | YES | |
| Longitude | double | YES | |

#### `pitches`
| Column | Type | Nullable | Notes |
|---|---|---|---|
| Id | int | NO | PK |
| venue_id | int | NO | FK → venues.Id CASCADE. Indexed. |
| Name | longtext | YES | |
| Surface | longtext | YES | |
| Size | longtext | YES | |
| is_active | tinyint(1) | NO | default 0 |

#### `sessions`
| Column | Type | Nullable | Notes |
|---|---|---|---|
| Id | int | NO | PK |
| pitch_id | int | NO | FK → pitches.Id CASCADE. Indexed. |
| created_by | int | NO | FK → users.Id CASCADE. Indexed. |
| starts_at | datetime(6) | NO | **NO INDEX** |
| ends_at | datetime(6) | NO | |
| max_players | int | NO | |
| price_per_player | decimal(65,30) | NO | |
| Status | longtext | NO | **NO INDEX** |
| created_at | datetime(6) | NO | |

#### `session_players`
| Column | Type | Nullable | Notes |
|---|---|---|---|
| session_id | int | NO | FK → sessions.Id CASCADE |
| user_id | int | NO | FK → users.Id CASCADE. Indexed. |
| Status | longtext | NO | |
| joined_at | datetime(6) | NO | |
| position | varchar | YES | Added migration 20260413204042 |
PK: `(session_id, user_id)`.

#### `payments`
| Column | Type | Nullable |
|---|---|---|
| Id | int | NO |
| user_id | int | NO |
| session_id | int | NO |
| Amount | decimal(65,30) | NO |
| Status | longtext | NO |
| created_at | datetime(6) | NO |
Indexes: `session_id`, `user_id`.

#### `device_tokens`
| Column | Type | Nullable |
|---|---|---|
| Id | int | NO |
| user_id | int | NO |
| Token | longtext | NO |
| created_at | datetime(6) | NO |
Index: `user_id`.

#### `match_bookings`
| Column | Type | Nullable | Notes |
|---|---|---|---|
| Id | int | NO | PK |
| requested_by_user_id | int | NO | FK → users.Id CASCADE. **NO INDEX** |
| pitch_id | int | NO | FK → pitches.Id CASCADE. Indexed. |
| team_size | int | NO | |
| teams_count | int | NO | |
| requested_starts_at | datetime(6) | NO | |
| requested_ends_at | datetime(6) | NO | |
| proposed_starts_at | datetime(6) | YES | |
| proposed_ends_at | datetime(6) | YES | |
| offered_price_per_player | decimal(65,30) | YES | |
| Notes | longtext | YES | |
| Status | longtext | NO | |
| session_id | int | YES | FK → sessions.Id SET NULL. Indexed. |
| created_at | datetime(6) | NO | |

#### `app_notifications`
| Column | Type | Nullable |
|---|---|---|
| Id | int | NO |
| user_id | int | NO |
| Title | longtext | NO |
| Body | longtext | NO |
| Type | longtext | NO |
| is_read | tinyint(1) | NO |
| reference_id | int | YES |
| reference_type | longtext | YES |
| created_at | datetime(6) | NO |
Index: `(user_id, is_read)` composite.

---

## 5. Security Summary

| Issue | Severity | Location |
|---|---|---|
| DB password, JWT key, Gmail password in plain text | CRITICAL | `appsettings.json:3,6,22` |
| `AllowAnyOrigin()` CORS | CRITICAL | `Program.cs:90-98` |
| Firebase credentials file hardcoded relative path | HIGH | `AuthController.cs:139` |
| JWT signing key weak placeholder, ~48 chars | MEDIUM | `appsettings.json:6` |
| BCrypt work factor implicit (default 10) — not configurable | LOW | All password hashes |
| No rate limiting on auth endpoints | MEDIUM | `AuthController` |
| No account lockout after failed logins | MEDIUM | `AuthController` |
| No refresh token mechanism | LOW | Auth flow |

---

## 6. Phase 3 Prep — Bilingual Fields Missing from DB

Columns needed for Phase 1 seeding + Phase 3 localization (not yet in schema):

| Table | Missing Columns |
|---|---|
| `venues` | `name_ar`, `city_ar`, `address_ar`, `description_ar` |
| `pitches` | `name_ar` |

These will be added via EF migration in Phase 1.
