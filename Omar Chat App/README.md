# OMAR Chat

WhatsApp-style Flutter messaging app built for the **CEN306** university course by **OMAR ASLAN** (22040102144) and **MALAK MEDHAT** (22040102054). OMAR Chat demonstrates layered architecture, DAO + Repository pattern, Cubit state management, full data persistence, and 11 meaningful screens.

## Features

### Messaging
- Direct and group messaging with unread badges and total unread summary
- Message edit (10 min window) and delete (for me / for all within 5 min)
- Reply to messages with quote preview
- **Voice messages** — record with mic, send in direct or group chat; recipient replies with a contextual **voice message**
- File/image attachments, drawing board input, built-in emoji picker
- **@Mentions in group chats** — type `@` to pick a member; mentions are highlighted

### Notifications & Alerts
- **Sound notification** — alert tone when any user sends you a message
- **Text-to-speech** — speaks the sender name (e.g. *"Ahmed sent you a message"*)
- Local push notifications on Android/iOS; separate mention alerts in groups
- Mute individual chats to suppress alerts

### Block / Unblock
- **Block one user only** — other contacts are not affected
- Block from **Chat Detail** menu or **User Detail** screen
- **Unblock** restores send/receive messaging with that user
- Group chats still work when you block a member (block applies to direct messaging only)

### Data Persistence
- **All data saved on app close** — messages, chats, blocks, statuses, profile, unread counts, call history
- **Android/iOS:** SQLite via `sqflite` (`omar_chat.db`); DAO classes persist through `InMemoryStore` dual-write to SQLite
- **Web / desktop without SQLite:** JSON via `PersistenceService` (SharedPreferences on web, local file elsewhere)
- Settings toggles (notifications, sound, TTS) also persist in SharedPreferences

### Profile & Status Photos
- Set profile photo from gallery or **default mountain landscape** bundled asset
- Post **text or photo status** (24h expiry); use gallery or default landscape for photo status

### Smart Replies (Simulated)
- **Direct chats** — contextual text or **voice reply** ~2 seconds after you send
- **Group @mentions** — each mentioned member replies based on your message

### Create Multi-User Group (latest feature)

Create a **new group chat with multiple users** (not only the pre-seeded groups):

1. Open **Chat List**
2. Tap **New group** — use the white **New group** FAB or **⋮ menu → New group**
3. Enter a **group name** (required)
4. Check **one or more contacts** (you are added automatically as admin)
5. Tap **Create** (app bar) or **Create Group** (bottom button)
6. The new group appears on the chat list and opens for messaging; data is saved on close

**Note:** The optional “broadcast to selected users” section sends direct messages only — it does **not** create a group.

### Social & Discovery
- User search and global/in-chat message search
- Per-chat background themes (Default, Lion, Sea)
- Profile and user detail screens

### Calls
- Simulated voice and video call UI
- Call history screen

## Architecture

OMAR Chat uses three physically separated layers under `lib/` (see **§5.2 Project Structure — Folder Structure** in the report):

| Layer | Folder | Contains |
|-------|--------|----------|
| **UI Layer (Presentation)** | `lib/presentation/` | `screens/` (11 screens), `widgets/` (19 widgets), `state/` (7 Cubits) |
| **Business Layer (Domain)** | `lib/domain/` | `entities/` (6 entities), `usecases/` (11 use cases) |
| **Data Layer** | `lib/data/` | `models/` (11 models), `dao/` (9 DAOs), `repositories/` (8 repos), `database/` (sqflite) |

Supporting folders: `lib/services/` (sound, TTS, media, notifications) and `lib/core/` (constants, theme, routes).

**Call direction:** UI → Business (use cases) → Data (repositories → DAOs → SQLite). Screens never import DAO classes directly.

## SQLite Tables

`users`, `chats`, `chat_members`, `messages`, `attachments`, `statuses`, `theme_settings`, `blocked_users`, `muted_chats`, `unread_counts`, `call_history`

Runtime storage uses **sqflite** (SQLite) on Android/iOS via DAO classes; web uses a JSON-backed fallback with the same Repository/DAO API. Schema: `lib/core/constants/db_constants.dart`.

## Screens

1. Splash · 2. Chat List · 3. Chat Detail · 4. Create Group · 5. Search · 6. Profile · 7. Settings · 8. User Detail · 9. Status · 10. Call · 11. Call History

## Getting Started

```bash
flutter pub get
flutter run -d edge
```

| Platform | Command |
|----------|---------|
| Windows | `flutter run -d windows` |
| Edge / Chrome | `flutter run -d edge` |
| Android | `flutter run -d android` |

Demo user: **OMAR** (ID `1`) — see `DbConstants.currentUserId`.

### Try Key Features

1. **Voice** — open a chat, tap mic, record, tap stop → peer replies with voice message
2. **Block** — Chat Detail menu → Block user → try sending (disabled) → Unblock to restore
3. **Persistence** — send messages, close app completely, reopen → data unchanged
4. **Default photo** — Profile → *Use default landscape photo* · Status → *Default landscape photo*
5. **Create group** — Chat List → **New group** FAB (or menu → New group) → enter group name → check members → **Create Group** → opens the new group chat

## Dependencies

`flutter_bloc`, `record`, `just_audio`, `image_picker`, `file_picker`, `permission_handler`, `flutter_local_notifications`, `flutter_tts`, `shared_preferences`, `path_provider`, `sqflite`, `intl`, `uuid`, `equatable`

## Report

- `CEN306_OMAR_Chat_Project_Report.pdf` (submission) / `.docx` (editable)
- **GitHub:** https://github.com/om-ar-123/ChatApplication-Whatsapp-style.git
- **Demo video:** https://youtu.be/NMbdp9CBy3g
- Regenerate: `scripts\build_report.bat`

## License

Educational project — CEN306 coursework.
