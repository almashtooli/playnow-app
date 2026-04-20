# PlayNow — Seed Data

## How to seed

```bash
# From the API project directory
cd D:\Projects\PlayNow\PlayNow\PlayNow.API

# Apply the migration first (see below), then:
dotnet run -- seed
```

Running it twice is safe — the second run prints `✓ Already seeded — skipping.`

---

## Credentials

| Role | Email pattern | Password |
|---|---|---|
| Admin | `admin@playnow.test` | `Admin123!` |
| Venue owners | `owner01@playnow.test` … `owner20@playnow.test` | `Owner123!` |
| Players | `player001@playnow.test` … `player200@playnow.test` | `Player123!` |

---

## Data summary

| Entity | Count | Notes |
|---|---|---|
| Users (admin) | 1 | `admin@playnow.test` |
| Users (venue owners) | 20 | `owner01–20@playnow.test` |
| Users (players) | 200 | `player001–200@playnow.test` |
| Venues | 50 | 20 active (isActive=true), 30 inactive pending admin approval |
| Pitches | ~100 | 1–3 per venue; surfaces: Turf/Grass/Indoor; sizes: 5/7/11-a-side |
| Sessions | ~300 | Over next 14 days, slots at 16:00/18:00/20:00/22:00 |
| Session-player bookings | ~800 | ~20% full, ~30% half-full, ~20% minimal, ~30% empty |

All monetary values in JD (3–12 JD per player per session).

---

## Neighborhoods covered (Amman)

| Neighborhood | Arabic | Venues |
|---|---|---|
| Abdoun | عبدون | 5 |
| Sweifieh | السويفية | 5 |
| Jabal Amman | جبل عمان | 5 |
| Shmeisani | الشميساني | 5 |
| Khalda | خلدا | 5 |
| Dabouq | دابوق | 5 |
| Marj El Hamam | مرج الحمام | 5 |
| 7th Circle | الدوار السابع | 5 |
| Tla' Al-Ali | تلاع العلي | 5 |
| University St. | شارع الجامعة | 5 |

Coordinates are clustered around 31.95°N, 35.89°E (central Amman) with ±0.002° random jitter.

---

## Bilingual fields

All venues include both English and Arabic for:
- `name` / `name_ar`
- `city` / `city_ar`
- `address` / `address_ar`
- `description` / `description_ar`

All pitches include `name` / `name_ar`.

---

## Migration required

Before seeding, run the EF migration that adds the bilingual columns and performance indexes:

```bash
cd D:\Projects\PlayNow\PlayNow\PlayNow.API

# Generate migration (review output matches the expected diff below)
dotnet ef migrations add AddBilingualFieldsAndIndexes

# Apply to DB
dotnet ef database update
```

### Expected migration diff
- `venues`: add columns `name_ar`, `city_ar`, `address_ar`, `description_ar` (all `longtext nullable`)
- `pitches`: add column `name_ar` (`longtext nullable`)
- `sessions`: add index on `starts_at`, index on `Status`
- `match_bookings`: add index on `requested_by_user_id`
