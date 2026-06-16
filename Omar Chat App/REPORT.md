# OMAR Chat — Full Project Report

**Course:** CEN306  
**Project:** OMAR Chat — WhatsApp-Style Mobile Messaging Application  
**Technology:** Flutter / Dart  
**Version:** 1.0.0  
**Architecture:** Layered (Presentation → Domain → Data)  
**State Management:** flutter_bloc (Cubit pattern)

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Project Objectives](#2-project-objectives)
3. [Functional Requirements](#3-functional-requirements)
4. [System Architecture](#4-system-architecture)
5. [Database Design](#5-database-design)
6. [Application Screens](#6-application-screens)
7. [Features & Business Rules](#7-features--business-rules)
8. [State Management](#8-state-management)
9. [Services Layer](#9-services-layer)
10. [User Interface Design](#10-user-interface-design)
11. [Project Structure](#11-project-structure)
12. [Dependencies](#12-dependencies)
13. [Installation & Running](#13-installation--running)
14. [Demo Data](#14-demo-data)
15. [Platform Notes (Web vs Mobile)](#15-platform-notes-web-vs-mobile)
16. [Testing Checklist](#16-testing-checklist)
17. [Conclusion](#17-conclusion)
18. [Appendix — Code Map](#18-appendix--code-map)

---

## 1. Introduction

**OMAR Chat** is a cross-platform messaging application inspired by WhatsApp. It was developed as a university coursework project to demonstrate professional mobile application development practices required by the CEN306 rubric:

- At least **5 meaningful screens**
- **Layered architecture** (separation of UI, business logic, and data)
- **Persistent data storage** with DAO and Repository patterns
- **Proper state management** (Cubit / BLoC)
- Rich messaging features comparable to modern chat apps

The application supports direct (1-to-1) chats, group chats, message attachments, user search, status updates, blocking, muting, per-chat themes, simulated voice/video calls, call history, **sound + TTS notifications** on incoming messages, and **group @mention auto-replies**.

The logged-in demo user is **OMAR** (user ID `1`). All interactions are performed from this account.

---

## 2. Project Objectives

| Objective                      | Implementation                                                                |
| ------------------------------ | ----------------------------------------------------------------------------- |
| Build a WhatsApp-style chat UI | Green theme, chat bubbles, wallpaper, input bar, unread badges                |
| Layered architecture           | `presentation/`, `domain/`, `data/`, `services/`, `core/`                     |
| Data persistence               | SQLite schema defined; DAO + Repository pattern; in-memory store for web demo |
| State management               | 6 Cubit classes with Equatable states                                         |
| Business rules in use cases    | Edit/delete time windows, block/mute logic, unread counters                   |
| Group messaging                | Create groups, add members, group chat view                                   |
| Media & attachments            | Images, files, voice messages, drawing board                                  |
| Search                         | User search + global/in-chat message search                                   |
| Status feature                 | Text and photo statuses with 24-hour expiry                                   |
| Notifications                  | Sound alert + local notifications + TTS on incoming messages (mobile)         |
| @Mentions & auto-reply         | Group mention picker; mentioned users reply based on message content          |
| Simulated calls                | Voice and video call UI with timer and controls; call history                 |

---

## 3. Functional Requirements

### 3.1 Messaging

- Send and receive text messages in direct and group chats
- Reply to a specific message (quote preview)
- Edit own messages within **10 minutes**
- Delete messages **for me** or **for all** (sender only, within **5 minutes**)
- Send emojis via built-in emoji picker (bottom sheet)
- **@Mention group members** — autocomplete picker; highlighted mentions in bubbles
- Attach photos and documents
- Record and send voice messages (mobile/desktop)
- Draw and send images from drawing board

### 3.2 Chats & Groups

- View chat list sorted by last message time
- Display unread count per chat and total unread summary
- **Create new multi-user groups** — name the group, select one or more contacts, tap Create Group (Chat List → New group FAB or menu)
- OMAR is added automatically as group admin; at least one other member is required
- New groups are persisted, appear on the main chat list, and open immediately after creation
- Group member selection shows chips and helper text when name or members are missing
- Open direct chat from user search or user profile

### 3.3 Users & Profiles

- View user profile (name, email, job title, bio, online status)
- Edit own profile (OMAR)
- Block/unblock users (prevents messaging)
- Mute/unmute individual chats

### 3.4 Search

- Search users by name, email, or job title
- Search messages globally or within a specific chat

### 3.5 Status

- View active statuses from all users (24-hour expiry)
- Post text status or photo status with optional caption
- View status details in a dialog

### 3.6 Settings

- Toggle notifications on/off
- Toggle **sound alerts** on/off
- Toggle text-to-speech on/off (announces sender name)
- App version information

### 3.7 Notifications & Incoming Alerts

When any user sends a message **to OMAR**, the app:
1. Plays a short **notification sound** (`assets/sounds/message_notification.wav`)
2. Shows a **local notification** (Android/iOS): *"{Name} sent you a message"*
3. Speaks via **TTS**: *"{Name} sent you a message"*

In group chats, if OMAR is @mentioned, the alert says *"{Name} mentioned you in {Group}"*.

Alerts are suppressed when notifications are disabled, sound/TTS toggled off, or the chat is muted.

### 3.8 Simulated Replies

- **Direct chat:** After OMAR sends, the other user auto-replies after ~2 seconds using `AutoReplyService` (context-aware keywords).
- **Group @mention:** Each mentioned member replies sequentially with a delay, using the text after `@Name` to generate a contextual response.

### 3.9 Calls (Simulated)

- Voice call screen with ringing → connecting → connected flow
- Video call screen with simulated feeds and controls
- Mute, speaker, video on/off, flip camera, end call
- Accessible from chat header and user profile

### 3.10 Call History

- View past voice and video call records
- Shows contact name, call type, duration, and timestamp

---

## 4. System Architecture

The project follows a **4-layer architecture** with clear dependency direction:

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│  Screens · Widgets · Cubits (UI + local state)          │
└────────────────────────┬────────────────────────────────┘
                         │ calls
┌────────────────────────▼────────────────────────────────┐
│                      DOMAIN                              │
│  Entities · Use Cases (business rules)                   │
└────────────────────────┬────────────────────────────────┘
                         │ calls
┌────────────────────────▼────────────────────────────────┐
│                       DATA                               │
│  Models · DAOs · Repositories · Database                 │
└────────────────────────┬────────────────────────────────┘
                         │ uses
┌────────────────────────▼────────────────────────────────┐
│                     SERVICES                             │
│  Notifications · TTS · Media · File upload/download      │
└─────────────────────────────────────────────────────────┘

         CORE (constants, theme, utilities) — shared by all layers
```

### 4.1 Presentation Layer

- **Screens:** Full-page UI (`lib/presentation/screens/`)
- **Widgets:** Reusable components (`lib/presentation/widgets/`)
- **Cubits:** State holders that call use cases and repositories

### 4.2 Domain Layer

- **Entities:** Pure Dart objects (`User`, `Chat`, `Message`, `Group`)
- **Use Cases:** Single-responsibility business operations (9 use cases)

### 4.3 Data Layer

- **Models:** Database/API mapping objects with `toMap()` / `fromMap()`
- **DAOs:** Data Access Objects — CRUD per table (8 DAO classes)
- **Repositories:** Aggregate DAOs and map models to domain entities (7 repositories)
- **Database:** `AppDatabase` facade over `InMemoryStore` (simulated persistence)

### 4.4 Services Layer

Platform capabilities isolated from business logic: notifications, speech, audio recording, file picking.

### 4.5 Design Patterns Used

| Pattern            | Where                                            |
| ------------------ | ------------------------------------------------ |
| Repository         | `lib/data/repositories/`                         |
| DAO                | `lib/data/dao/`                                  |
| Use Case           | `lib/domain/usecases/`                           |
| Cubit (BLoC)       | `lib/presentation/state/`                        |
| Singleton          | `AppDatabase.instance`, `InMemoryStore.instance` |
| Facade             | `AppDatabase` over storage backend               |
| Conditional import | `file_storage.dart` (IO vs Web)                  |

---

## 5. Database Design

### 5.1 Schema Overview

The canonical SQLite schema is defined in `lib/core/constants/db_constants.dart`. The application uses **10 tables**:

| Table            | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| `users`          | User accounts (name, email, job, avatar, bio, online)    |
| `chats`          | Chat threads (direct or group, last message, timestamps) |
| `chat_members`   | Many-to-many link between users and chats                |
| `messages`       | Message content, type, reply, edit/delete flags          |
| `attachments`    | Files linked to messages (images, voice, documents)      |
| `statuses`       | User status posts with 24h expiry                        |
| `theme_settings` | Per-chat wallpaper/theme                                 |
| `blocked_users`  | Block relationships between users                        |
| `muted_chats`    | Mute state per chat                                      |
| `unread_counts`  | Per-user unread count per chat                           |

### 5.2 Entity Relationship (Simplified)

```
users ─────┬──── chat_members ──── chats
           │                           │
           ├──── messages ──────────────┤
           │         │
           │    attachments
           │
           ├──── statuses
           ├──── blocked_users
           └──── unread_counts

chats ──── theme_settings
chats ──── muted_chats
```

### 5.3 Key Fields — `messages`

| Column                | Type    | Description                                 |
| --------------------- | ------- | ------------------------------------------- |
| `message_type`        | TEXT    | `text`, `voice`, `file`, `image`, `drawing` |
| `reply_to_message_id` | INTEGER | FK to quoted message                        |
| `is_edited`           | INTEGER | 1 if edited                                 |
| `is_deleted`          | INTEGER | 1 if deleted                                |
| `is_for_all`          | INTEGER | 1 if deleted for everyone                   |

### 5.4 Storage Implementation

For **course demonstration on Chrome (web)**, the app uses an **in-memory simulated database** (`InMemoryStore`) because `sqflite` does not run in the browser. The DAO and Repository layers are unchanged — they call the same API (`insert`, `query`, `update`, `deleteWhere`) against the in-memory store.

For **Android/iOS**, the architecture supports SQLite via `sqflite` (dependency included). The schema in `db_constants.dart` documents the intended production database.

**Note:** In-memory data resets when the browser tab is refreshed.

---

## 6. Application Screens

The application contains **11 screens** (9 required + call + call history):

| #   | Screen           | Route           | Description                                           |
| --- | ---------------- | --------------- | ----------------------------------------------------- |
| 1   | **Splash**       | `/`             | App logo, auto-navigates to chat list after 2 seconds |
| 2   | **Chat List**    | `/chats`        | Main page — all chats and groups with unread badges   |
| 3   | **Chat Detail**  | `/chat-detail`  | Message thread, input bar, attachments, calls         |
| 4   | **Create Group** | `/create-group` | Name group, multi-select members, Create Group action; optional broadcast (direct only) |
| 5   | **Search**       | `/search`       | Find users and messages                               |
| 6   | **Profile**      | `/profile`      | Edit OMAR's profile and avatar                        |
| 7   | **Settings**     | `/settings`     | Notifications and TTS toggles                         |
| 8   | **User Detail**  | `/user-detail`  | View another user's info, message/call actions        |
| 9   | **Status**       | `/status`       | View and post text/photo statuses                     |
| 10  | **Call**         | `/call`         | Simulated voice or video call UI                      |
| 11  | **Call History** | `/call-history` | Past voice/video call records                         |

### Navigation Flow

```
Splash → Chat List
              ├── Chat Detail → (Call Screen)
              ├── Create Group → Chat Detail
              ├── Search → User Detail / Chat Detail
              ├── Status
              ├── Profile
              └── Settings (via menu)
```

Named routes are registered in `lib/app.dart` with `RouteSettings` passed correctly for argument parsing (`lib/core/utils/route_args.dart`).

---

## 7. Features & Business Rules

### 7.1 Use Cases

| Use Case        | File                           | Rule                                                       |
| --------------- | ------------------------------ | ---------------------------------------------------------- |
| Send Message    | `send_message_usecase.dart`    | Block check; update last message; increment unread          |
| Receive Message | `receive_message_usecase.dart` | Incoming alerts (sound, push, TTS); simulate direct/group replies |
| Edit Message    | `edit_message_usecase.dart`    | Sender only; within 10 minutes                             |
| Delete Message  | `delete_message_usecase.dart`  | For-all: sender only, within 5 min                         |
| Create Chat     | `create_chat_usecase.dart`     | Reuse existing direct chat if present                      |
| Create Group    | `create_group_usecase.dart`    | Group name required; OMAR + ≥1 selected member; GroupDao saves chat, members, unread |
| Block User      | `block_user_usecase.dart`      | Bidirectional send prevention                              |
| Mute Chat       | `mute_chat_usecase.dart`       | Suppress notifications                                     |
| Unread Counter  | `unread_counter_usecase.dart`  | Increment on receive; reset on open                        |
| Search Messages | `search_messages_usecase.dart` | Global and per-chat search                                 |

### 7.2 Time Windows

Defined in `DbConstants` and enforced in `DateTimeUtils`:

| Action         | Window                    |
| -------------- | ------------------------- |
| Edit message   | **10 minutes** after send |
| Delete for all | **5 minutes** after send  |

### 7.3 Message Types

| Type    | Constant      | UI                   |
| ------- | ------------- | -------------------- |
| Text    | `typeText`    | Bubble with text     |
| Voice   | `typeVoice`   | Voice message widget |
| File    | `typeFile`    | Attachment preview   |
| Image   | `typeImage`   | Image preview        |
| Drawing | `typeDrawing` | Image preview        |

### 7.4 Block & Mute

- **Block:** `SendMessageUseCase` checks `SettingsRepository.isBlocked()` before sending
- **Mute:** Notifications skipped when chat is muted
- UI indicators: block icon and mute icon on chat tiles

### 7.5 Status Expiry

Statuses expire **24 hours** after creation (`expires_at` compared to current UTC time in `StatusDao.getActive()`).

---

## 8. State Management

Six **Cubit** classes manage UI state using `flutter_bloc` and `equatable`:

| Cubit             | Responsibility                                       |
| ----------------- | ---------------------------------------------------- |
| `ChatListCubit`   | Chat list, total unread, refresh on return           |
| `ChatDetailCubit` | Messages, reply/edit targets, recording, attachments |
| `SearchCubit`     | User and message search results                      |
| `GroupCubit`      | Member selection, group creation, broadcast          |
| `ProfileCubit`    | Current or viewed user profile                       |
| `SettingsCubit`   | Notification and TTS preferences                     |

Cubits are provided at app root in `lib/app.dart` via `MultiBlocProvider`. Screens consume state with `BlocBuilder` / `BlocConsumer`.

**Example flow — send message:**

```
ChatInputBar.onSend
  → ChatDetailCubit.sendText()
    → SendMessageUseCase.execute()
      → MessageRepository.insert()
        → MessageDao.insert()
          → InMemoryStore.insert('messages', ...)
    → ChatDetailCubit.load()  // refresh UI
```

---

## 9. Services Layer

| Service             | File                                             | Purpose                                     |
| ------------------- | ------------------------------------------------ | ------------------------------------------- |
| Local Notifications | `local_notification_service.dart`                | Android/iOS message alerts (skipped on web) |
| Notification Sound  | `notification_sound_service.dart`                | Plays alert tone on incoming messages       |
| Text-to-Speech      | `speech_service.dart`                            | Speaks "{Name} sent you a message"          |
| Auto Reply          | `auto_reply_service.dart`                        | Context-aware simulated replies             |
| Media               | `media_service.dart`                             | Voice recording and playback                |
| Upload/Download     | `upload_download_service.dart`                   | Image/file picker; web blob store           |
| File Storage        | `file_storage_io.dart` / `file_storage_web.dart` | Platform-specific file paths                |
| Web Blob Store      | `web_blob_store.dart`                            | In-memory file storage for web              |

---

## 10. User Interface Design

### 10.1 Theme

WhatsApp-inspired color palette (`lib/core/constants/app_colors.dart`):

| Color           | Hex       | Usage                     |
| --------------- | --------- | ------------------------- |
| App Bar         | `#008069` | Top bars, group avatars   |
| Accent          | `#25D366` | Send button, unread badge |
| Chat Background | `#ECE5DD` | Chat wallpaper base       |
| Sent Bubble     | `#D9FDD3` | Outgoing messages         |
| Received Bubble | `#FFFFFF` | Incoming messages         |

### 10.2 Key UI Components

| Widget               | Purpose                                          |
| -------------------- | ------------------------------------------------ |
| `ChatTile`           | Chat list row with avatar, preview, time, unread |
| `MessageBubble`      | Sent/received message with ticks and timestamp   |
| `ChatInputBar`       | Text input, emoji, attach, mic/send              |
| `EmojiPickerPanel`   | Categorized emoji grid (bottom sheet)            |
| `ChatWallpaper`      | Themed chat background                           |
| `ProfileAvatar`      | Letter avatar or image (web-aware)               |
| `MediaImage`         | Cross-platform image display                     |
| `DrawingBoardWidget` | Full-screen drawing canvas                       |
| `DateSeparator`      | "Today", "Yesterday" labels                      |
| `UnreadBadge`        | Green circle with count                          |

### 10.3 Chat Themes

Per-chat themes: **Default**, **Lion** (warm brown), **Sea** (light blue). Selected via theme picker dialog in chat menu.

---

## 11. Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp, routes, Bloc providers
├── core/
│   ├── constants/               # Colors, strings, routes, SQL schema
│   ├── navigation/              # Route observer
│   ├── theme/                   # AppTheme
│   └── utils/                   # Dates, validators, route args
├── domain/
│   ├── entities/                # User, Chat, Message, Group, CallSession
│   └── usecases/                # 9 business use cases
├── data/
│   ├── database/                # AppDatabase, InMemoryStore
│   ├── dao/                     # 8 DAO classes
│   ├── models/                  # 10 data models
│   └── repositories/            # 7 repository classes
├── presentation/
│   ├── screens/                 # 10 screens
│   ├── state/                   # 6 Cubit classes
│   └── widgets/                 # 18+ reusable widgets
└── services/                    # Platform services
```

**Total Dart files:** 94

---

## 12. Dependencies

| Package                     | Version   | Purpose                   |
| --------------------------- | --------- | ------------------------- |
| flutter_bloc                | ^9.1.1    | Cubit state management    |
| equatable                   | ^2.0.7    | Value equality for states |
| sqflite                     | ^2.4.2    | SQLite (mobile)           |
| path_provider               | ^2.1.5    | App documents directory   |
| flutter_local_notifications | ^19.2.1   | Push-style local alerts   |
| flutter_tts                 | ^4.2.2    | Text-to-speech            |
| image_picker                | ^1.1.2    | Gallery/camera images     |
| file_picker                 | ^9.2.3    | Document picker           |
| permission_handler          | ^12.0.0+1 | Runtime permissions       |
| just_audio                  | ^0.10.4   | Audio playback            |
| record                      | ^6.0.0    | Voice recording           |
| intl                        | ^0.20.2   | Date/time formatting      |
| shared_preferences          | ^2.5.3    | Settings persistence      |
| uuid                        | ^4.5.1    | Unique identifiers        |

---

## 13. Installation & Running

### Prerequisites

- Flutter SDK (stable channel, Dart ^3.12)
- Chrome (for web demo) or Android Studio / Xcode (for mobile)

### Commands

```bash
# Install dependencies
flutter pub get

# Run on Chrome (web demo)
flutter run -d chrome

# Run on Android emulator/device
flutter run -d android

# Run on Windows desktop
flutter run -d windows
```

### Hot Reload

- `r` — hot reload
- `R` — hot restart (required after structural changes)
- `q` — quit

---

## 14. Demo Data

On first launch, `InMemoryStore._seedAll()` populates:

### Users (8)

| ID  | Name                    | Role              |
| --- | ----------------------- | ----------------- |
| 1   | **OMAR** (current user) | Software Engineer |
| 2   | Mohamed                 | UI Designer       |
| 3   | Ahmed                   | Backend Developer |
| 4   | Sara                    | Business Analyst  |
| 5   | Ali                     | Project Manager   |
| 6   | Layla                   | QA Engineer       |
| 7   | Youssef                 | DevOps Engineer   |
| 8   | Nour                    | Product Owner     |

### Chats (6)

- 4 direct chats (Mohamed, Ahmed, Layla, Youssef)
- 2 group chats (Project Team, CEN306 Study Group)

### Messages (9)

Pre-seeded conversation snippets across all chats.

### Statuses (8)

One status per user with captions; expire after 24 hours.

### Unread Counts

OMAR has unread messages in all 6 chats (demo badges).

---

## 15. Platform Notes (Web vs Mobile)

| Feature             | Web (Chrome)                  | Android / iOS  |
| ------------------- | ----------------------------- | -------------- |
| Database            | In-memory (resets on refresh) | SQLite capable |
| Local notifications | Skipped                       | Supported      |
| Text-to-speech      | Skipped                       | Supported      |
| Voice recording     | Limited                       | Supported      |
| Image/file attach   | Web blob store                | File system    |
| Status photos       | In-memory images              | File paths     |
| Calls               | Simulated UI                  | Simulated UI   |
| Emoji picker        | Bottom sheet                  | Bottom sheet   |

Web adaptations use `kIsWeb` checks and conditional imports (`file_storage.dart`, `platform_file_image.dart`).

---

## 16. Testing Checklist

Use this list to verify all rubric features during demo or grading:

- [ ] App launches from splash to chat list
- [ ] Chat list shows unread counts and total unread banner
- [ ] Open direct chat and send a text message
- [ ] Send emoji via emoji button (bottom sheet opens)
- [ ] Attach photo or document in chat
- [ ] Long-press message → Reply / Edit / Delete
- [ ] Edit message within 10 minutes (shows edited label)
- [ ] Delete for all within 5 minutes
- [ ] Create a new group — appears on main chat list
- [ ] Search for a user by name
- [ ] Open user profile → Message / Call / Video
- [ ] Post text status and photo status
- [ ] View another user's status
- [ ] Mute and unmute a chat
- [ ] Block a user (send should fail)
- [ ] Change chat theme (lion / sea)
- [ ] Simulated voice call (ringing → timer → end)
- [ ] Simulated video call (controls work)
- [ ] Direct chat: receive reply with **sound + TTS** (*"Ahmed sent you a message"*)
- [ ] Group chat: **@mention** a user and receive contextual auto-reply
- [ ] Settings: toggle notifications, **sound**, and TTS
- [ ] Edit OMAR profile

---

## 17. Conclusion

OMAR Chat successfully implements a full-featured WhatsApp-style messaging application that meets and exceeds CEN306 coursework requirements:

- **11 screens** with meaningful navigation and state
- **Layered architecture** with clear separation of concerns
- **DAO + Repository** data access pattern across 10 tables
- **9 use cases** encapsulating business rules
- **Cubit state management** for reactive UI
- **Rich messaging** including media, voice, drawing, emoji, reply, edit, delete
- **Social features** including status, groups, search, block, mute
- **Simulated calls** for voice and video
- **Cross-platform** support with web-specific adaptations

The codebase is organized for maintainability and demonstrates industry-standard Flutter development patterns suitable for academic evaluation and future extension (real backend, WebRTC calls, persistent SQLite on all platforms).

---

## 18. Appendix — Code Map

| Report Topic        | Source Location                                         |
| ------------------- | ------------------------------------------------------- |
| App entry & routes  | `lib/main.dart`, `lib/app.dart`                         |
| SQL schema          | `lib/core/constants/db_constants.dart`                  |
| In-memory DB & seed | `lib/data/database/in_memory_store.dart`                |
| DAOs                | `lib/data/dao/*.dart`                                   |
| Repositories        | `lib/data/repositories/*.dart`                          |
| Use cases           | `lib/domain/usecases/*.dart`                            |
| Cubits              | `lib/presentation/state/*.dart`                         |
| Screens             | `lib/presentation/screens/`                             |
| Widgets             | `lib/presentation/widgets/`                             |
| Services            | `lib/services/`                                         |
| Theme & colors      | `lib/core/theme/`, `lib/core/constants/app_colors.dart` |
| Date/time rules     | `lib/core/utils/date_time_utils.dart`                   |
| Call simulation     | `lib/presentation/screens/call/call_screen.dart`        |
| Emoji picker        | `lib/presentation/widgets/emoji_picker_panel.dart`      |

---

_Report generated for OMAR Chat — CEN306 Course Project._

**Deliverables:** `CEN306_OMAR_Chat_Project_Report.docx` and `CEN306_OMAR_Chat_Project_Report.pdf` (with embedded app screenshots in Section 4).
