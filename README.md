# APX Task Management

A production-ready Flutter task management app built on **Clean Architecture**, with
GetX (state, DI, routing), Dio, Dartz `Either`, SharedPreferences, Firebase Cloud
Messaging and ScreenUtil-driven responsive Material 3 UI.

---

## Running it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Demo mode (no backend required)

The app ships with an in-memory mock API — 24 tasks across all six statuses, five
users, comments, and a working login — so every screen is explorable without a
server:

```bash
flutter run --dart-define=USE_MOCK_API=true
```

In demo mode any email with a 6+ character password signs in. Status changes and
comment edits persist for the lifetime of the process, exactly like a real server.

### Pointing at a backend

`ApiConstants.baseUrl` defaults to `https://www.apxapi.somee.com/`. Override per
build:

```bash
flutter run --dart-define=BASE_URL=https://api.your-host.com/api/v1
```

Other build-time flags: `ENABLE_NETWORK_LOGS`, `ENABLE_ANALYTICS`.

---

## Architecture

```
lib/
├── core/                          # Cross-cutting, feature-agnostic
│   ├── bindings/                  # InitialBinding (shared auth graph)
│   ├── constants/                 # AppConfig, ApiConstants, StorageKeys, AppStrings
│   ├── errors/                    # Exceptions, Failures, ErrorHandler
│   ├── network/                   # ApiClient, interceptors, NetworkInfo, mock API
│   ├── notifications/             # FCM + local notifications, channels, payloads
│   ├── routes/                    # AppRoutes, AppPages
│   ├── services/                  # SessionManager, Theme, Analytics, Logger
│   ├── storage/                   # StorageService, TokenStorage
│   ├── theme/                     # AppTheme, AppColors, AppTextStyles
│   ├── usecases/                  # UseCase contract
│   ├── utils/                     # Formatters, validators, JWT, extensions, UI helpers
│   └── widgets/                   # AppButton, AppTextField, AppLoader, StatusChip…
│
├── features/
│   ├── splash/                    # domain + presentation
│   ├── auth/                      # data + domain + presentation
│   ├── tasks/                     # data + domain + presentation
│   ├── task_details/              # data + domain + presentation
│   ├── comments/                  # data + domain + presentation
│   └── profile/                   # data + domain + presentation
│
├── firebase_options.dart
└── main.dart
```

### The dependency rule

```
presentation  →  domain  ←  data
 (controllers)   (entities,    (models, datasources,
                  repositories   repository impls)
                  interfaces,
                  use cases)
```

`domain` imports nothing from `data` or Flutter. Data sources throw
`AppException`s; repositories convert them to `Failure`s via `ErrorHandler`, so
**every repository method returns `Future<Either<Failure, T>>`** and no exception
ever reaches a controller.

### Two documented deviations

1. **`UserEntity` is a shared kernel.** It lives in `features/auth/domain` and is
   reused by tasks (assignee/reporter) and comments (author). Duplicating it per
   feature would mean converting between identical shapes at every boundary.
2. **`splash` has no `data` layer.** It orchestrates the auth domain and owns no
   data of its own; an empty folder for symmetry would be cargo cult.

### Models are DTOs, not entities

Models do **not** extend entities. Each exposes `toEntity()`. This keeps
`json_serializable` out of the domain layer and lets models absorb real-world
JSON messiness (key aliases, ids arriving as `int` or `String`, dates as strings)
without polluting domain types. Malformed records in a list are skipped rather
than failing the whole page.

---

## Authentication flow

`SplashController` → `ResolveStartupRouteUseCase` → `CheckSessionUseCase`:

| Token state | Action |
|---|---|
| Missing | → Login |
| Present but expired | Clear the session, → Login (with an explanatory snackbar) |
| Present and valid | → Home |

Expiry is decided by `TokenStorage`, which prefers the server's `expiresIn` and
falls back to the JWT `exp` claim (`JwtDecoder`), applying a 30-second leeway so a
token cannot die mid-request. Opaque (non-JWT) tokens with no discoverable expiry
are treated as valid — the server stays the authority and a 401 corrects us.

`SessionManager` is the single authority on "who is signed in". It stores the user
as a raw JSON map rather than a typed entity, because `core` must not depend on a
feature package.

---

## Network layer

`ApiClient` builds the Dio instance and installs, in order:

| Interceptor | Responsibility |
|---|---|
| `AuthInterceptor` | Attaches the bearer token; on 401 performs a **single-flight** silent refresh and replays the request once; forces logout when unrecoverable |
| `ApiInterceptor` | Default headers, locale, null-query stripping, bounded retry for idempotent requests on connection errors |
| `LoggerInterceptor` | Pretty request/response/error logs with redacted auth headers, muted in release |
| `MockInterceptor` | Only when `USE_MOCK_API=true` — short-circuits with demo data |

Status handling lives in `ErrorHandler`: 400/409/422 → `ValidationFailure` (with
per-field errors), 401 → `UnauthorizedFailure` + forced logout, 403 →
`ForbiddenFailure`, 404 → `NotFoundFailure`, 5xx → `ServerFailure`, timeouts →
`TimeoutFailure`, offline → `NetworkFailure`.

Concurrency note: if ten requests 401 simultaneously, exactly one refresh call is
made and the rest await it. The refresh itself uses a bare Dio instance so it can
never re-enter the 401 handler.

### API contract assumed

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/login` | `{email, password}` → `{token, refreshToken, expiresIn, user}` |
| POST | `/auth/refresh` | `{refreshToken}` → `{token, …}` |
| POST | `/auth/logout` | |
| GET | `/auth/me` | |
| GET | `/tasks?status=&page=&limit=&search=` | → `{data: [], meta: {page, limit, total, totalPages}}` |
| GET | `/tasks/{id}` | |
| PATCH | `/tasks/{id}/status` | `{status}` |
| GET/POST | `/tasks/{id}/comments` | POST body `{body}` |
| PATCH/DELETE | `/comments/{id}` | |
| GET/PATCH | `/profile`, `/profile/notification-settings` | |
| POST | `/devices/fcm-token` | `{token, platform}` |

Both bare bodies and `{data: …, meta: …}` envelopes are accepted, and pagination
metadata is read from `meta`, `pagination` or the root with common key aliases.

---

## Task workflow

The transition table lives in the `TaskStatus` enum — in the domain, not the UI:

```
New → In Progress → Ready For Testing → Testing → Done
                 (any status) → Rejected
```

One step forward, or straight to Rejected from anywhere. **Rejected is terminal**;
relax `TaskStatus.allowedTransitions` if the product later needs a reopen action.
`UpdateTaskStatusUseCase` re-validates the transition before any request — the UI
only offers legal targets, but a use case must not trust its caller.

`StatusSelector` is the reusable component: it renders the legal next steps plus a
pipeline progress bar, works inline or as a bottom sheet, and knows nothing about
tasks, controllers or the network.

---

## Dashboard & pagination

One `TaskListController` per status tab, registered with the status as its GetX
tag. Each tab owns its page cursor, scroll position and error state, so switching
tabs never refetches loaded data, and tabs are lazy — a tab's first page is only
requested when the user opens it.

- Infinite scroll triggers one viewport before the end.
- A failed **first** page becomes a full-screen error; a failed **later** page
  becomes a retry footer, so page 3 failing never blanks a working list.
- Duplicate ids are filtered when appending, in case records shift between pages.
- After a status change, the task is removed from its old tab and the destination
  tab is marked stale (reloaded on arrival) instead of refetching all six.

> Controllers expose `reload()`, not `refresh()` — `GetxController.refresh()`
> already means "notify listeners", and shadowing it would break GetX's own
> change propagation.

---

## Comments

Chat-style timeline grouped by day, with the current user's comments right-aligned.
Sending is **optimistic**: the bubble appears immediately in a pending state and is
reconciled — or marked failed with a retry action — when the server answers.
Deleting removes the bubble immediately and restores it at its exact index if the
request fails. Edit and delete are offered only on your own comments (the server
remains the authority).

---

## Push notifications

`NotificationService` handles all three lifecycle states:

| State | Path |
|---|---|
| Foreground | `FirebaseMessaging.onMessage` → local notification rendered on Android (iOS presents natively) |
| Background | `onMessageOpenedApp` → deep-link to the task |
| Terminated | `getInitialMessage()` captured at startup, replayed by the splash flow **after** the user is known to be signed in |

Five channels (`task_comments_v1`, `task_status_v1`, `task_assignments_v1`,
`task_created_v1`, `general_v1`) are created at boot. Expected data payload:

```json
{ "type": "comment_added", "taskId": "142", "commentId": "1042",
  "title": "…", "body": "…" }
```

`type` is one of `comment_added`, `status_changed`, `task_assigned`,
`task_created`. Per-category mute toggles from the profile screen are honoured
before a notification is rendered.

### Firebase setup

`lib/firebase_options.dart` ships with **placeholders**, and
`DefaultFirebaseOptions.hasValidConfiguration` reports `false`, so `main()` skips
`Firebase.initializeApp` and the app runs normally with push and analytics
disabled. To enable:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then uncomment the `com.google.gms.google-services` plugin lines in
`android/settings.gradle.kts` and `android/app/build.gradle.kts`.

Android is already configured with the required permissions, the FCM default
channel meta-data, `minSdk 23`, and **core library desugaring** (required by
`flutter_local_notifications`). iOS has the `remote-notification` background mode.

---

## Local storage

`StorageService` wraps SharedPreferences; `TokenStorage` owns credentials only.
Stored: access token, refresh token, expiry, user JSON, theme mode, notification
settings, last-registered FCM token. A normal sign-out clears credentials and user
data but **keeps** preferences (theme, notification settings).

---

## Verification status

- `flutter analyze` — **no issues**.
- Domain rules (status transitions, priority parsing, pagination) verified by 36
  assertions, all passing.
- `test/widget_test.dart` contains the equivalent suite as proper unit tests.
  `flutter test` could not run in this environment: the harness fails to open its
  localhost websocket (`503 … not upgraded to websocket`) before any test loads —
  an environment/proxy issue unrelated to the code. Run it on your machine.
