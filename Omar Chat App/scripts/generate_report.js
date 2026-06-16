/**
 * OMAR Chat — CEN306 Report (styled like CEN306_Istanbul_Climate_Report)
 * Run: npm install && node generate_report.js && node export_pdf.js
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, WidthType, PageBreak, Header, Footer, PageNumber,
  ImageRun, BorderStyle, VerticalAlign,
} from 'docx';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDocx = path.join(__dirname, '..', 'CEN306_OMAR_Chat_Project_Report.docx');
const shotsDir = path.join(__dirname, '..', 'report_assets', 'screenshots');

// Istanbul Climate report palette
const BLUE = '1F4E79';
const BLUE_LIGHT = 'D9EAF7';
const ROW_ALT = 'F4F6F7';
const WHITE = 'FFFFFF';
const TEXT = '1A1A1A';
const TEXT_MUTED = '2C3E50';
const BORDER = '2C3E50';
const BORDER_LIGHT = 'CCCCCC';
const CODE_BG = 'F4F4F4';
const CODE_TEXT = '2B2B2B';

const SZ_BODY = 20;   // 10pt
const SZ_H1 = 28;
const SZ_H2 = 24;

function run(text, opts = {}) {
  return new TextRun({
    text,
    font: opts.mono ? 'Courier New' : 'Calibri',
    size: opts.size ?? SZ_BODY,
    bold: opts.bold ?? false,
    italics: opts.italics ?? false,
    color: opts.color ?? TEXT,
  });
}

function para(children, opts = {}) {
  return new Paragraph({
    alignment: opts.align,
    spacing: { before: opts.before ?? 0, after: opts.after ?? 120 },
    shading: opts.shading ? { fill: opts.shading } : undefined,
    indent: opts.indent ? { left: opts.indent } : undefined,
    children: Array.isArray(children) ? children : [children],
  });
}

function h1(text) {
  return para(run(text, { size: SZ_H1, bold: true, color: BLUE }), { after: 140, before: 200 });
}

function h2(text) {
  return para(run(text, { size: SZ_H2, bold: true, color: BLUE }), { after: 100, before: 160 });
}

function p(text) {
  return para(run(text));
}

function pb() {
  return new Paragraph({ children: [new PageBreak()] });
}

function borders(outer = BORDER, inner = BORDER_LIGHT) {
  return {
    top: { style: BorderStyle.SINGLE, size: 1, color: outer },
    bottom: { style: BorderStyle.SINGLE, size: 1, color: outer },
    left: { style: BorderStyle.SINGLE, size: 1, color: outer },
    right: { style: BorderStyle.SINGLE, size: 1, color: outer },
  };
}

function coverCell(text, isLabel) {
  return new TableCell({
    width: { size: isLabel ? 33 : 67, type: WidthType.PERCENTAGE },
    shading: { fill: isLabel ? BLUE_LIGHT : WHITE },
    borders: borders(isLabel ? BORDER : BORDER_LIGHT, BORDER_LIGHT),
    margins: { top: 100, bottom: 100, left: 140, right: 140 },
    verticalAlign: VerticalAlign.CENTER,
    children: [para(run(text, { bold: true, color: isLabel ? TEXT : TEXT_MUTED }), { after: 40 })],
  });
}

function coverTable(rows) {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: rows.map(([label, value]) =>
      new TableRow({ children: [coverCell(label, true), coverCell(value, false)] }),
    ),
  });
}

function headerCell(text, widthPct) {
  return new TableCell({
    width: { size: widthPct, type: WidthType.PERCENTAGE },
    shading: { fill: BLUE },
    borders: borders(),
    margins: { top: 80, bottom: 80, left: 100, right: 100 },
    verticalAlign: VerticalAlign.CENTER,
    children: [para(run(text, { bold: true, color: WHITE }), { align: AlignmentType.CENTER, after: 40 })],
  });
}

function dataCell(text, widthPct, rowIndex) {
  return new TableCell({
    width: { size: widthPct, type: WidthType.PERCENTAGE },
    shading: { fill: rowIndex % 2 === 0 ? ROW_ALT : WHITE },
    borders: borders(BORDER_LIGHT, BORDER_LIGHT),
    margins: { top: 80, bottom: 80, left: 100, right: 100 },
    children: [para(run(String(text), { color: TEXT }), { after: 40 })],
  });
}

function table(headers, rows, widths) {
  const w = widths ?? headers.map(() => Math.floor(100 / headers.length));
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [
      new TableRow({ children: headers.map((h, i) => headerCell(h, w[i])) }),
      ...rows.map((r, ri) =>
        new TableRow({ children: r.map((c, i) => dataCell(c, w[i], ri)) }),
      ),
    ],
  });
}

function codeBlock(lines) {
  return lines.map((line) =>
    para(run(line, { mono: true, size: 18, color: CODE_TEXT }), {
      shading: CODE_BG,
      indent: 360,
      after: 20,
    }),
  );
}

function loadShot(key) {
  if (!fs.existsSync(shotsDir)) return null;
  const files = fs.readdirSync(shotsDir);
  const emu = files.find((x) => x.includes(key) && x.includes('emulator'));
  if (emu) return path.join(shotsDir, emu);
  const f = files.find((x) => x.includes(key));
  return f ? path.join(shotsDir, f) : null;
}

function shotFile(filename, caption, w = 100, h = 175) {
  const fp = path.join(shotsDir, filename);
  if (!fs.existsSync(fp)) return [p(`[Screenshot: ${caption}]`)];
  return [
    para([new ImageRun({ data: fs.readFileSync(fp), transformation: { width: w, height: h }, type: 'png' })], {
      align: AlignmentType.CENTER,
      after: 20,
    }),
    para(run(caption, { italics: true, color: '555555', size: 16 }), {
      align: AlignmentType.CENTER,
      after: 60,
    }),
  ];
}

function shotPair(left, right, w = 95, h = 165) {
  const cell = (item) => {
    const fp = path.join(shotsDir, item.file);
    if (!fs.existsSync(fp)) {
      return new TableCell({
        width: { size: 50, type: WidthType.PERCENTAGE },
        children: [p(`[${item.caption}]`)],
      });
    }
    return new TableCell({
      width: { size: 50, type: WidthType.PERCENTAGE },
      children: [
        para([new ImageRun({ data: fs.readFileSync(fp), transformation: { width: w, height: h }, type: 'png' })], {
          align: AlignmentType.CENTER,
          after: 16,
        }),
        para(run(item.caption, { italics: true, color: '555555', size: 16 }), {
          align: AlignmentType.CENTER,
          after: 40,
        }),
      ],
    });
  };
  return [
    new Table({
      width: { size: 100, type: WidthType.PERCENTAGE },
      rows: [new TableRow({ children: [cell(left), cell(right)] })],
    }),
  ];
}

function shotPara(key, caption, w = 130, h = 240) {
  const fp = loadShot(key);
  if (!fp) return [p(`[Screenshot: ${caption}]`)];
  return [
    para([new ImageRun({ data: fs.readFileSync(fp), transformation: { width: w, height: h }, type: 'png' })], {
      align: AlignmentType.CENTER,
      after: 40,
    }),
    para(run(`Figure ${caption}`, { italics: true, color: '555555', size: 18 }), {
      align: AlignmentType.CENTER,
      after: 100,
    }),
  ];
}

// ─── Page 1: University header + project cover (single page) ───
const headerPage = [
  para(run('İSTANBUL TOPKAPI ÜNİVERSİTESİ', { size: 32, bold: true }), { align: AlignmentType.CENTER, after: 100 }),
  para(run('Faculty of Engineering', { size: 28, bold: true }), { align: AlignmentType.CENTER, after: 100 }),
  para(run('Project Report', { size: 36, bold: true }), { align: AlignmentType.CENTER, after: 160 }),
  p('Adı: CEN306 — Mobile Application Design and Development'),
  p('Date: 15/06/2026'),
  para('', { after: 40 }),
  p('Students or Team Members Who Prepared the Project'),
  table(['Name-Surname', 'Signature', 'Student No'], [
    ['OMAR ASLAN', '', '22040102144'],
    ['MALAK MEDHAT', '', '22040102054'],
    ['', '', ''],
  ], [40, 30, 30]),
  para('', { after: 40 }),
  p('Programı: Bilgisayar Mühendisliği (İng.)'),
  para('', { after: 40 }),
  p('(This section will be filled out by the Instructor.)'),
  table(['Subject of Evaluation', 'Evaluation Score'], [
    ['Flutter Mobile Application Project — Code Evaluation (70 Points)', ''],
    ['Flutter Mobile Application Project — Project Report Evaluation (30 Points)', ''],
  ], [70, 30]),
  para('', { after: 80 }),
  para(run('CEN306 - Mobile Application Design and Development', { size: 22, bold: true, color: BLUE }), {
    align: AlignmentType.CENTER,
    after: 40,
  }),
  para(run('Final Exam Project Report', { size: 28, bold: true, color: BLUE }), {
    align: AlignmentType.CENTER,
    after: 100,
  }),
  coverTable([
    ['Project Title', 'OMAR Chat — WhatsApp-Style Mobile Messaging Application'],
    ['Student Name-Surname', 'OMAR ASLAN & MALAK MEDHAT'],
    ['Student Number', '22040102144 / 22040102054'],
    ['Student Signature', ''],
    ['Course Name', 'CEN306 - Mobile Application Design and Development'],
    ['Instructor', 'Dr. Yıldız Karadayı'],
    ['Submission Date', '15/06/2026'],
    ['GitHub / Source Code Link', '[Add repository URL]'],
    ['Demo Video YouTube Link', '[Add YouTube link]'],
    ['Application Name', 'OMAR Chat'],
  ]),
  para('', { after: 40 }),
  p('Academic Integrity Statement: I confirm that this report and project were prepared by me and that all external sources, libraries, code snippets, and datasets are properly acknowledged.'),
  pb(),

  // ─── 1. Executive Summary ───
  h1('1. Executive Summary'),
  p('OMAR Chat is a Flutter messaging application inspired by WhatsApp, developed for CEN306 by OMAR ASLAN and MALAK MEDHAT. It demonstrates direct and group chat, multi-user group creation, voice messages with contextual voice replies, photo status and profile images (including a bundled landscape photo), per-user block/unblock, sound + TTS notifications, @mention auto-replies, and full data persistence across app restarts.'),
  p('The project uses layered architecture (UI / Business / Data / Services), DAO + Repository pattern, Cubit state management, and SQLite via sqflite on Android/iOS (JSON fallback on web and desktop). All chat data, messages, blocks, statuses, and profile changes persist across app restarts.'),
  table(['Item', 'Short answer'], [
    ['Application name', 'OMAR Chat'],
    ['Problem addressed', 'Need for a structured, feature-rich chat app demonstrating mobile architecture patterns'],
    ['Target users', 'University students, project teams (demo user: OMAR)'],
    ['Core technologies', 'Flutter/Dart, SQLite/sqflite, flutter_bloc, flutter_tts, just_audio, flutter_local_notifications'],
    ['Main contribution', 'Full WhatsApp-style UX with sound/TTS alerts, @mention replies, 11 screens, and clean layered architecture'],
  ], [30, 70]),

  h1('2. Project Introduction'),
  h2('2.1 Project Purpose'),
  p('OMAR Chat was developed to demonstrate CEN306 learning outcomes: layered design, persistent data storage, state management, and polished UI comparable to modern messaging apps. It simulates a multi-user environment where OMAR (user ID 1) interacts with seeded contacts through direct chats, groups, status, and calls.'),
  h2('2.2 Scope of the Project'),
  p('Included: direct/group messaging, create new multi-user groups, voice messages with voice replies, message edit/delete, @mentions, sound + TTS notifications, search, status (24h) with default landscape photo, profile photo (gallery + bundled asset), per-user block/unblock, full data persistence, block/mute, themes, simulated calls, call history, 11 screens. Out of scope: real backend server, WebRTC, push notification server, end-to-end encryption.'),
  h2('2.3 Target Users and Usage Scenario'),
  p('A student opens OMAR Chat, sees unread badges on the chat list, opens a group chat, types "@Ahmed can we meet tomorrow?" — Ahmed replies contextually; OMAR hears a notification sound and TTS says "Ahmed sent you a message".'),
  h2('2.4 Main Features'),
  table(['Feature', 'Description', 'Related Screen(s)'], [
    ['Direct & group messaging', 'Text, voice, files, images, drawings, emoji', 'Chat Detail'],
    ['Create multi-user group', 'Name group, select members, open new group chat', 'Create Group, Chat List'],
    ['Voice messages & replies', 'Record/send voice; simulated contextual voice reply', 'Chat Detail'],
    ['Simulated voice/video calls', 'Call UI with timer, mute, end controls', 'Call'],
    ['Sound + TTS alerts', 'Alert tone and spoken sender name on incoming messages', 'Settings / all chats'],
    ['@Mention auto-reply', 'Mentioned group members reply based on message content', 'Chat Detail (group)'],
    ['Block / Unblock user', 'Block one user only; unblock to restore messaging', 'Chat Detail, User Detail'],
    ['Data persistence', 'All chats/messages/settings saved on close; restored on reopen', 'All screens'],
    ['Profile & status photos', 'Gallery picker + default mountain landscape asset', 'Profile, Status'],
    ['Search users & messages', 'Global user list and message content search', 'Search'],
    ['Mute chat & themes', 'Per-chat mute and wallpaper themes', 'Chat Detail (group)'],
    ['Drawing board & attachments', 'Sketch messages; send images and files', 'Chat Detail'],
  ], [22, 48, 30]),

  h1('3. Requirements and Use Cases'),
  h2('3.1 Functional Requirements'),
  table(['ID', 'Functional Requirement', 'Priority', 'Implemented'], [
    ['FR-01', 'Send/receive messages in direct and group chats', 'High', 'Yes'],
    ['FR-02', 'Edit (10 min) and delete messages (for all: 5 min)', 'High', 'Yes'],
    ['FR-03', 'Sound + TTS notification on incoming messages', 'High', 'Yes'],
    ['FR-04', '@Mention users in groups; contextual auto-reply', 'High', 'Yes'],
    ['FR-05', 'Block/unblock individual users; restore messaging', 'High', 'Yes'],
    ['FR-06', 'Voice record, send, and receive contextual voice reply', 'High', 'Yes'],
    ['FR-07', 'Persist all data across app restart', 'High', 'Yes'],
    ['FR-08', 'Profile photo and photo status (incl. default landscape)', 'Medium', 'Yes'],
    ['FR-09', 'SQLite schema with DAO and Repository', 'High', 'Yes'],
    ['FR-10', 'Search, mute, status, simulated calls', 'Medium', 'Yes'],
    ['FR-11', 'Create new multi-user group chat with named title', 'High', 'Yes'],
  ], [10, 52, 14, 24]),
  h2('3.2 Non-Functional Requirements'),
  table(['Category', 'Requirement', 'How It Is Addressed'], [
    ['Usability', 'WhatsApp-like navigation', 'Green theme, chat list, bubbles, bottom input bar'],
    ['Performance', 'Fast UI refresh', 'Cubit + async DAO; SQLite on mobile; JSON cache on web'],
    ['Reliability', 'Handle errors gracefully', 'Block checks, try/catch on services, empty input guards'],
    ['Maintainability', 'Layered separation', 'UI / Domain / Data / Services — no DB calls from screens'],
  ], [18, 32, 50]),
  h2('3.3 Use Cases'),
  table(['Use Case', 'Actor', 'Main Flow', 'Expected Result'], [
    ['UC-01: Send message', 'OMAR', 'Type and send in chat', 'Message stored; unread updated'],
    ['UC-02: Receive alert', 'OMAR', 'Ahmed replies in direct chat', 'Sound + TTS: "Ahmed sent you a message"'],
    ['UC-03: @Mention reply', 'OMAR', '@Ahmed hello in group', 'Ahmed replies contextually'],
    ['UC-04: Block user', 'OMAR', 'Block Ahmed in chat menu', 'Only Ahmed blocked; others unaffected'],
    ['UC-05: Unblock user', 'OMAR', 'Unblock from menu or User Detail', 'Messaging restored both ways'],
    ['UC-06: Send voice', 'OMAR', 'Tap mic, record, send in direct/group', 'Voice stored; peer replies with voice'],
    ['UC-07: Persist data', 'OMAR', 'Send messages, close app, reopen', 'All data restored as before'],
    ['UC-08: Create group', 'OMAR', 'Menu/FAB → New group → name + select members → Create', 'Group appears in chat list; group chat opens'],
  ], [22, 10, 38, 30]),
  h2('3.4 Rubric Compliance Summary (100 Points)'),
  p('This table maps the official CEN306 scoring rubric to OMAR Chat implementation and report sections.'),
  table(['Rubric area', 'Points', 'How OMAR Chat satisfies it'], [
    ['A1: ≥5 meaningful screens (11 screens)', '10', 'Splash, Chat List, Chat Detail, Create Group, Search, Profile, Settings, User Detail, Status, Call, Call History'],
    ['A2: Screen variety (list/detail/edit/settings)', '5', 'Chat list, chat detail, create group, profile edit, settings'],
    ['A3: Navigation structure', '3', 'Named routes in app.dart; consistent back navigation'],
    ['A4: UI layout and usability', '2', 'WhatsApp-style theme; screenshots §4.3'],
    ['B1: Layer separation UI/Business/Data', '10', 'lib/presentation, domain, data folders — §5'],
    ['B2: Responsibility distribution', '5', 'Screens use Cubits → Use Cases → Repositories → DAOs'],
    ['B3: Folder structure', '3', '§5.2 folder tree'],
    ['B4: Extensibility', '2', 'Repository pattern; new features via use cases'],
    ['C1: SQLite + CRUD', '5', 'sqflite package; tables in db_constants.dart; DAO CRUD — §6'],
    ['C2: DAO usage', '4', '9 DAO classes (MessageDao, ChatDao, UserDao, …) — §6.2'],
    ['C3: Repository usage', '3', 'Repositories abstract DAOs — §6.3'],
    ['C4: Data flow', '3', 'Use Case → Repository → DAO → SQLite — §6.4'],
    ['D1–D4: State management (Cubit)', '15', 'flutter_bloc Cubits; StatefulWidget on screens — §7.3'],
    ['Report: Structure', '5', 'Sections 1–12; header template; tables'],
    ['Report: Purpose & scope', '5', '§1–§2'],
    ['Report: Architecture & SQLite', '10', '§5–§7; DAO/Repository/SQLite tables explained'],
    ['Report: Screenshots', '5', '§4.3 manual screenshots with explanations'],
    ['Report: Challenges', '5', '§9 challenges and solutions'],
  ], [28, 10, 62]),

  pb(),
  h1('4. User Interface Design and Screens'),
  h2('4.1 UI Design Approach'),
  p('Material Design with WhatsApp-inspired palette: app bar #008069, accent #25D366, chat background #ECE5DD. Reusable widgets include ChatTile, MessageBubble, MentionText, ChatInputBar, EmojiPickerPanel, and UnreadBadge.'),
  h2('4.2 Navigation Flow'),
  p('Splash → Chat List → Chat Detail / Search / Status / Profile / Settings / Create Group. Chat List exposes **New group** from the overflow menu and a dedicated **New group** FAB. Create Group → enter name, select members, tap Create → returns to Chat List and opens the new group chat. Chat Detail → Call. User Detail → Message or Call. Named routes registered in app.dart.'),
  h2('4.3 Screenshots by Feature (Manual Captures)'),
  p('All screenshots below were taken manually on the Android device running OMAR Chat. Each image is placed only under the feature it demonstrates. File names are stored in report_assets/screenshots/.'),
  h2('4.3.1 Chat List & Direct Messaging'),
  ...shotPair(
    { file: '01_chat_list.png', caption: 'Chat List — unread badges' },
    { file: '02_direct_chat.png', caption: 'Direct Chat — Mohamed' },
  ),
  p('Chat List shows direct and group chats with unread badges. Direct Chat supports text, attachments, emoji, and voice.'),
  ...shotPair(
    { file: '03_direct_reply.png', caption: 'Simulated contextual reply' },
    { file: '04_voice_messages.png', caption: 'Voice messages' },
  ),
  p('ReceiveMessageUseCase triggers sound + TTS on incoming messages. Voice messages use record + just_audio packages.'),
  h2('4.3.2 Simulated Calls'),
  ...shotPair(
    { file: '05_voice_call.png', caption: 'Voice call UI' },
    { file: '06_video_call.png', caption: 'Video call UI' },
  ),
  h2('4.3.3 Block & Unblock'),
  ...shotPair(
    { file: '07_block_dialog.png', caption: 'Block confirmation' },
    { file: '08_block_send_error.png', caption: 'Send blocked error' },
  ),
  ...shotPair(
    { file: '12_block_banner.png', caption: 'Blocked banner + disabled input' },
    { file: '10_settings.png', caption: 'Settings toggles' },
  ),
  p('Block applies to one user only in direct chats. Unblock restores messaging from Chat Detail menu.'),
  h2('4.3.4 Profile & Status'),
  ...shotPair(
    { file: '11_profile.png', caption: 'Profile edit screen' },
    { file: '13_status_landscape.png', caption: 'Status — landscape photo' },
  ),
  h2('4.3.5 Search'),
  ...shotPair(
    { file: '14_search_users.png', caption: 'Search — Users tab' },
    { file: '15_search_messages.png', caption: 'Search — Messages tab' },
  ),
  h2('4.3.6 Group Chat Features'),
  ...shotPair(
    { file: '17_group_mention_reply.png', caption: 'Group chat + @mention reply' },
    { file: '16_group_mention_picker.png', caption: '@Mention picker' },
  ),
  ...shotPair(
    { file: '18_group_mute_theme.png', caption: 'Mute & chat theme' },
    { file: '19_group_image.png', caption: 'Image attachment' },
  ),
  ...shotPair(
    { file: '20_group_emoji.png', caption: 'Emoji messages' },
    { file: '21_drawing_board.png', caption: 'Drawing board' },
  ),
  ...shotFile('22_group_attachments.png', 'Group — images, emoji, file, drawing combined'),
  h2('4.4 Latest Feature — Create Multi-User Group'),
  ...shotFile('09_chat_menu_new_group.png', 'New group entry — Chat List menu'),
  p('The latest feature lets OMAR create a new group with multiple users. Open Chat List → overflow menu → **New group** (or the **New group** FAB). On the Create Group screen: enter a group name, select one or more contacts (OMAR is added automatically as admin), then tap **Create Group**. GroupDao saves the chat, members, and unread rows to SQLite (sqflite on mobile); the new group appears on the chat list and opens immediately. The menu screenshot also shows Mohamed marked as blocked on the chat list — block applies only to direct chat, not group creation.'),
  table(['Screenshot file', 'Feature demonstrated'], [
    ['01_chat_list.png', 'Chat list & unread badges'],
    ['02_direct_chat.png', 'Direct messaging'],
    ['03_direct_reply.png', 'Simulated reply + sound/TTS'],
    ['04_voice_messages.png', 'Voice messages'],
    ['05_voice_call.png / 06_video_call.png', 'Simulated calls'],
    ['07–08, 12_*.png', 'Block / unblock one user'],
    ['09_chat_menu_new_group.png', 'Create multi-user group (entry)'],
    ['10_settings.png', 'Notifications, sound, TTS toggles'],
    ['11_profile.png', 'Profile editing'],
    ['13_status_landscape.png', 'Status with landscape photo'],
    ['14–15_*.png', 'User and message search'],
    ['16–22_*.png', 'Group @mention, mute, theme, media, emoji, drawing'],
  ], [35, 65]),

  h1('5. Technical Architecture'),
  h2('5.1 Overall Layered Architecture'),
  p('OMAR Chat implements strict layered architecture. Dependencies flow in one direction only: UI Layer → Business Layer → Data Layer. The Presentation layer (screens and Cubits) never calls SQL or DAO classes directly. The Business layer (use cases) enforces rules such as block checks, edit windows, and notification logic. The Data layer (DAOs and repositories) handles SQLite persistence via sqflite. Platform services (sound, TTS, media) and shared constants (core/) support all layers but are not substitutes for the three required layers.'),
  table(['Layer', 'Folder path', 'Responsibility', 'Depends on'], [
    ['UI Layer (Presentation)', 'lib/presentation/', 'Screens, widgets, Cubit state — display data and capture input', 'Business Layer (via use cases)'],
    ['Business Layer (Domain)', 'lib/domain/', 'Entities and use cases — business rules and validation', 'Data Layer (via repositories)'],
    ['Data Layer', 'lib/data/', 'Models, DAO, Repository, SQLite database access', 'SQLite (sqflite) / JSON fallback'],
    ['Services (supporting)', 'lib/services/', 'Notifications, sound, TTS, media, file storage', 'Called by Business/UI — not a replacement layer'],
    ['Core (supporting)', 'lib/core/', 'Constants, theme, routes, utilities', 'Shared by all layers'],
  ], [18, 18, 38, 26]),
  h2('5.2 Project Structure — Folder Structure'),
  p('The three rubric-required layers are mapped to three separate top-level folders under lib/. No screen file exists inside domain/ or data/, and no DAO or SQL code exists inside presentation/. The table below defines this separation explicitly before the full folder tree.'),
  table(['Required layer', 'Physical folder', 'Subfolders / key files', 'What belongs here'], [
    ['UI Layer (Presentation Layer)', 'lib/presentation/', 'screens/ (11 screens), widgets/ (19 widgets), state/ (7 Cubits)', 'All Flutter UI: layouts, navigation, user input, BlocBuilder rebuilds. Must NOT contain SQL, DAO, or repository code.'],
    ['Business Layer (Domain Layer)', 'lib/domain/', 'entities/ (6 entities), usecases/ (11 use cases)', 'Pure business logic: SendMessage, BlockUser, CreateGroup, etc. Must NOT render widgets or access the database directly.'],
    ['Data Layer', 'lib/data/', 'models/ (11 models), dao/ (9 DAOs), repositories/ (8 repositories), database/', 'Persistence only: CRUD via DAO classes, entity mapping via repositories, sqflite in InMemoryStore. Must NOT contain UI widgets.'],
  ], [22, 18, 28, 32]),
  p('Figure 1 — Complete lib/ folder tree with layer labels. Each entry shows the file role. Source code is not included in this report; only structure and responsibilities are documented.'),
  ...codeBlock([
    'lib/',
    '├── main.dart                         — App entry point; initializes database and runs OmarChatApp',
    '├── app.dart                          — MaterialApp, named routes, MultiBlocProvider, lifecycle save',
    '│',
    '├── presentation/                     ═══ UI LAYER (Presentation Layer) ═══',
    '│   ├── screens/                      — Full-page UI (11 screens); one folder per screen',
    '│   │   ├── splash/                   — SplashScreen: branding, auto-navigate to Chat List',
    '│   │   ├── chat_list/                — ChatListScreen: unread badges, New group FAB, navigation hub',
    '│   │   ├── chat_detail/              — ChatDetailScreen: messaging, voice, @mentions, block menu',
    '│   │   ├── create_group/             — CreateGroupScreen: group name + multi-select members',
    '│   │   ├── search/                   — SearchScreen: Users tab and Messages tab',
    '│   │   ├── profile/                  — ProfileScreen: edit profile, gallery/default landscape photo',
    '│   │   ├── settings/                 — SettingsScreen: notifications, sound, TTS toggles',
    '│   │   ├── user_detail/              — UserDetailScreen: contact info, call, block/unblock',
    '│   │   ├── status/                   — StatusScreen: 24h text/photo status posts',
    '│   │   ├── call/                     — CallScreen: simulated voice/video call UI',
    '│   │   └── call_history/             — CallHistoryScreen: past calls list',
    '│   ├── widgets/                      — Reusable UI components (ChatTile, MessageBubble, …)',
    '│   │   ├── chat_tile.dart            — Chat list row with unread badge',
    '│   │   ├── message_bubble.dart       — Sent/received message bubble',
    '│   │   ├── chat_input_bar.dart       — Text input, emoji, attach, mic, draw buttons',
    '│   │   ├── voice_message_widget.dart — Voice bubble with play/stop',
    '│   │   ├── mention_picker.dart       — @Mention member picker (group chats)',
    '│   │   └── … (14 more widgets)       — EmojiPicker, DrawingBoard, UnreadBadge, etc.',
    '│   └── state/                        — Cubit state management (flutter_bloc)',
    '│       ├── chat_list_cubit.dart      — Chat list loading and refresh',
    '│       ├── chat_detail_cubit.dart    — Messages, send, edit, delete',
    '│       ├── group_cubit.dart          — Create group form state',
    '│       ├── search_cubit.dart         — User and message search',
    '│       ├── profile_cubit.dart        — Profile edit state',
    '│       ├── settings_cubit.dart       — Settings toggles state',
    '│       └── call_history_cubit.dart   — Call history list state',
    '│',
    '├── domain/                           ═══ BUSINESS LAYER (Domain Layer) ═══',
    '│   ├── entities/                     — Pure Dart domain objects (no Flutter imports)',
    '│   │   ├── user.dart                 — User entity (name, email, avatar, online)',
    '│   │   ├── chat.dart                 — Chat entity (direct/group, last message)',
    '│   │   ├── message.dart              — Message entity (content, type, reply, flags)',
    '│   │   ├── group.dart                — Group member entity',
    '│   │   ├── call_record.dart          — Call history record entity',
    '│   │   └── call_session.dart         — Active call session entity',
    '│   └── usecases/                     — Single-responsibility business operations (11 use cases)',
    '│       ├── send_message_usecase.dart     — Send text/voice; block check (direct only)',
    '│       ├── receive_message_usecase.dart  — Incoming message; sound + TTS + auto-reply',
    '│       ├── edit_message_usecase.dart     — Edit within 10-minute window',
    '│       ├── delete_message_usecase.dart   — Delete for me / for all (5 min)',
    '│       ├── block_user_usecase.dart       — Block/unblock one user pair',
    '│       ├── create_group_usecase.dart     — Validate name + members; create group',
    '│       ├── create_chat_usecase.dart      — Open or create direct chat',
    '│       ├── mute_chat_usecase.dart        — Mute/unmute per chat',
    '│       ├── search_messages_usecase.dart  — Global message content search',
    '│       ├── unread_counter_usecase.dart   — Mark chat read; update badges',
    '│       └── save_call_usecase.dart        — Record simulated call to history',
    '│',
    '├── data/                             ═══ DATA LAYER ═══',
    '│   ├── models/                       — Database mapping objects (toMap / fromMap)',
    '│   │   ├── user_model.dart           — users table mapping',
    '│   │   ├── chat_model.dart           — chats table mapping',
    '│   │   ├── message_model.dart        — messages table mapping',
    '│   │   ├── group_model.dart          — chat_members table mapping',
    '│   │   ├── attachment_model.dart     — attachments table mapping',
    '│   │   ├── status_model.dart         — statuses table mapping',
    '│   │   ├── unread_counter_model.dart — unread_counts table mapping',
    '│   │   └── … (4 more models)         — blocked_user, muted_chat, theme, call_record',
    '│   ├── dao/                          — Data Access Objects — CRUD per SQLite table (9 DAOs)',
    '│   │   ├── user_dao.dart             — users: getAll, getById, update, search',
    '│   │   ├── chat_dao.dart             — chats + chat_members: query(), getChatsForUser',
    '│   │   ├── message_dao.dart          — messages: insert, getByChatId, search',
    '│   │   ├── group_dao.dart            — createGroup, getMembers, unread init',
    '│   │   ├── unread_dao.dart           — unread_counts: increment, reset, getTotal',
    '│   │   ├── settings_dao.dart         — blocked_users, muted_chats, theme_settings',
    '│   │   ├── status_dao.dart           — statuses: insert, getActive, deleteExpired',
    '│   │   ├── attachment_dao.dart       — attachments: insert, getByMessageId',
    '│   │   └── call_dao.dart             — call_history: insert, getAll',
    '│   ├── repositories/                 — Aggregate DAOs; map models → domain entities (8 repos)',
    '│   │   ├── user_repository.dart      — UserDao → User entity',
    '│   │   ├── chat_repository.dart      — ChatDao + UnreadDao → Chat list with badges',
    '│   │   ├── message_repository.dart   — MessageDao + AttachmentDao → Message entity',
    '│   │   ├── group_repository.dart     — GroupDao → group creation',
    '│   │   ├── settings_repository.dart  — SettingsDao → block/mute/theme',
    '│   │   ├── status_repository.dart    — StatusDao → status posts',
    '│   │   ├── call_repository.dart      — CallDao → call history',
    '│   │   └── attachment_repository.dart— AttachmentDao → file metadata',
    '│   └── database/                     — SQLite connection and unified store API',
    '│       ├── app_database.dart         — Singleton; exposes InMemoryStore',
    '│       └── in_memory_store.dart      — sqflite on Android/iOS; JSON fallback on web',
    '│',
    '├── services/                         — Platform services (NOT a rubric layer; supports UI/Business)',
    '│   ├── persistence_service.dart      — JSON save/load fallback for web/desktop',
    '│   ├── notification_sound_service.dart — Alert tone on incoming messages',
    '│   ├── speech_service.dart           — Text-to-speech: "{Name} sent you a message"',
    '│   ├── local_notification_service.dart — Android/iOS push notifications',
    '│   ├── media_service.dart            — Voice record (record) and playback (just_audio)',
    '│   ├── auto_reply_service.dart       — Contextual text/voice simulated replies',
    '│   └── file_storage.dart             — Cross-platform file read/write',
    '│',
    '└── core/                             — Shared constants and utilities',
    '    ├── constants/db_constants.dart   — SQLite CREATE TABLE statements (11 tables)',
    '    ├── constants/app_routes.dart     — Named route strings',
    '    ├── constants/app_assets.dart     — Bundled mountain_landscape.png path',
    '    ├── theme/app_theme.dart          — WhatsApp-style green theme',
    '    └── utils/                        — Date formatting, validators, route args',
  ]),
  p('Figure 1. Simplified project folder structure. The three required layers — UI Layer (presentation/), Business Layer (domain/), and Data Layer (data/) — are physically separated. Screens and Cubits live only in presentation/; use cases and entities live only in domain/; DAOs, repositories, and models live only in data/.'),
  table(['Layer transition', 'Allowed call direction', 'Example in OMAR Chat'], [
    ['UI → Business', 'Screen/Cubit calls Use Case', 'ChatDetailCubit → SendMessageUseCase.execute()'],
    ['Business → Data', 'Use Case calls Repository', 'SendMessageUseCase → MessageRepository.send()'],
    ['Data → SQLite', 'Repository calls DAO; DAO calls InMemoryStore', 'MessageDao.insert() → store.insert("messages", …) → sqflite'],
    ['NOT allowed', 'UI → DAO or UI → SQL directly', 'No screen imports message_dao.dart'],
  ], [18, 28, 54]),
  h2('5.3 Responsibilities of Each Layer'),
  table(['Layer', 'Key responsibility', 'Must NOT do'], [
    ['UI Layer (presentation/)', 'Render screens/widgets; Cubits call use cases; BlocBuilder rebuilds UI', 'Import or call DAO, Repository, or SQL directly'],
    ['Business Layer (domain/)', 'Validate rules (block, edit window, group name); orchestrate repositories', 'Build widgets; write SQL; play sounds directly'],
    ['Data Layer (data/)', 'DAO CRUD on SQLite tables; Repository maps Model → Entity', 'UI layout; business validation; notification display'],
    ['Services (lib/services/)', 'Platform APIs: sound, TTS, notifications, voice record, files', 'Replace Business or Data layer responsibilities'],
    ['Core (lib/core/)', 'Shared constants (db_constants, routes, theme colors)', 'Store business logic or database queries'],
  ], [22, 44, 34]),

  pb(),
  h1('6. Data Layer: SQLite, DAO, and Repository'),
  h2('6.1 SQLite Database Design (sqflite)'),
  p('OMAR Chat uses the sqflite package on Android/iOS. Database file: omar_chat.db. Table CREATE statements are defined in lib/core/constants/db_constants.dart and executed in InMemoryStore._initSqlite() on first launch. DAO classes perform INSERT, SELECT, UPDATE, and DELETE through a unified store API. On web, the same DAO/Repository code uses a JSON-backed fallback.'),
  table(['Table', 'Purpose'], [
    ['users', 'Accounts, profile, online status'],
    ['chats', 'Direct/group threads, last message'],
    ['chat_members', 'User–chat membership'],
    ['messages', 'Content, type, reply, edit/delete flags'],
    ['attachments', 'Files linked to messages'],
    ['statuses', '24h status posts'],
    ['theme_settings', 'Per-chat wallpaper'],
    ['blocked_users / muted_chats / unread_counts / call_history', 'Settings and call records'],
  ], [28, 72]),
  h2('6.2 DAO Design'),
  p('Nine DAO classes encapsulate all SQL access. Each DAO calls InMemoryStore.insert(), query(), update(), updateWhere(), or deleteWhere() — never raw SQL from UI or use cases. ChatDao and UnreadDao use the unified query() API instead of direct list access.'),
  table(['DAO class', 'Table(s)', 'Key methods', 'CRUD'], [
    ['UserDao', 'users', 'getAll, getById, update, searchByName', 'SELECT, UPDATE'],
    ['ChatDao', 'chats, chat_members', 'insert, getById, getChatsForUser, findDirectChat, updateLastMessage', 'INSERT, SELECT, UPDATE'],
    ['MessageDao', 'messages', 'insert, getByChatId, getById, update, deleteWhere, searchContent', 'INSERT, SELECT, UPDATE, DELETE'],
    ['GroupDao', 'chats, chat_members, unread_counts', 'createGroup, getMembers, addMember', 'INSERT, SELECT'],
    ['AttachmentDao', 'attachments', 'insert, getByMessageId', 'INSERT, SELECT'],
    ['StatusDao', 'statuses', 'insert, getActiveForUser, deleteExpired', 'INSERT, SELECT, DELETE'],
    ['SettingsDao', 'blocked_users, muted_chats, theme_settings', 'blockUser, unblockUser, isMuted, getTheme', 'INSERT, SELECT, DELETE'],
    ['UnreadDao', 'unread_counts', 'increment, reset, getCount, getTotalForUser', 'INSERT, UPDATE, SELECT'],
    ['CallDao', 'call_history', 'insert, getAll, getByChatId', 'INSERT, SELECT'],
  ], [18, 22, 38, 22]),
  h2('6.3 Repository Design'),
  p('Eight repository classes sit between use cases and DAOs. Each repository maps data models to domain entities and may combine multiple DAOs. Screens and Cubits call use cases only; use cases call repositories — never DAOs directly from the UI layer.'),
  table(['Repository', 'DAO(s) used', 'Domain purpose'], [
    ['UserRepository', 'UserDao', 'User profiles, contact search'],
    ['ChatRepository', 'ChatDao, GroupDao, UnreadDao, SettingsDao, UserDao', 'Chat list, unread badges, last message'],
    ['MessageRepository', 'MessageDao, AttachmentDao, UserDao', 'Send/receive messages with reply preview and attachments'],
    ['GroupRepository', 'GroupDao, ChatDao', 'Create group, list members'],
    ['AttachmentRepository', 'AttachmentDao', 'File/image attachment metadata'],
    ['StatusRepository', 'StatusDao, UserDao', '24h status posts with user info'],
    ['SettingsRepository', 'SettingsDao', 'Block/unblock, mute, per-chat themes'],
    ['CallRepository', 'CallDao', 'Simulated call history records'],
  ], [22, 28, 50]),
  table(['Model class', 'SQLite table', 'Entity mapped to'], [
    ['UserModel', 'users', 'User'],
    ['ChatModel', 'chats', 'Chat'],
    ['MessageModel', 'messages', 'Message'],
    ['GroupModel / ChatMemberModel', 'chat_members', 'GroupMember'],
    ['AttachmentModel', 'attachments', 'Attachment'],
    ['StatusModel', 'statuses', 'Status'],
    ['BlockedUserModel / MutedChatModel / ThemeSettingModel', 'blocked_users, muted_chats, theme_settings', 'Block/Mute/Theme settings'],
    ['UnreadCounterModel', 'unread_counts', 'Unread count per chat'],
    ['CallRecordModel', 'call_history', 'CallRecord'],
  ], [28, 22, 50]),
  h2('6.4 Data Flow Example — Incoming Message'),
  table(['Step', 'Layer', 'Action'], [
    ['1', 'ReceiveMessageUseCase', 'Insert message; increment unread'],
    ['2', 'NotificationSoundService', 'Play alert tone'],
    ['3', 'LocalNotificationService', 'Show push notification (mobile)'],
    ['4', 'SpeechService', 'Speak "{Name} sent you a message"'],
    ['5', 'ChatDetailCubit', 'Refresh UI message list'],
  ], [8, 32, 60]),
  h2('6.5 Data Persistence Across App Restarts'),
  p('On Android/iOS, sqflite opens omar_chat.db and persists every INSERT/UPDATE/DELETE immediately through InMemoryStore dual-write (in-memory lists + SQLite). On web and desktop without sqflite, the same DAO/Repository API serializes to JSON via PersistenceService. OmarChatApp registers WidgetsBindingObserver to flush JSON on app pause. On first launch, seed data is inserted once. This preserves messages, blocks, mutes, statuses, profile avatar paths, unread counts, call history, and newly created groups across restarts.'),
  table(['Stored data', 'Persistence mechanism'], [
    ['Messages, chats, attachments', 'SQLite (sqflite) on mobile; JSON file on web/desktop fallback'],
    ['Blocked users, muted chats, themes', 'Same SQLite tables / JSON snapshot'],
    ['User profile & avatar path', 'users table / JSON snapshot'],
    ['Notification/sound/TTS toggles', 'SharedPreferences keys'],
    ['Voice recording files', 'App documents directory (paths stored in attachments table)'],
  ], [40, 60]),

  h1('7. Implementation Details'),
  h2('7.1 Flutter Widgets and Screens'),
  p('The app implements 11 screens and 19+ reusable widgets. ChatDetailScreen integrates ChatInputBar (text, emoji, attach, mic, draw), MentionPicker for groups, block/unblock menu, and blocked-state banner. ProfileScreen and StatusScreen support gallery images and the bundled mountain_landscape.png asset via AppAssets.'),
  table(['Screen', 'State approach', 'Primary features demonstrated'], [
    ['Splash', 'StatefulWidget', 'Branding splash; auto-navigate to Chat List'],
    ['Chat List', 'ChatListCubit + BlocBuilder', 'Unread badges, block icon, New group FAB, navigation hub'],
    ['Chat Detail', 'ChatDetailCubit + StatefulWidget', 'Messaging, voice, @mentions, block/unblock, themes'],
    ['Create Group', 'GroupCubit + StatefulWidget', 'Name group, multi-select members, Create Group action'],
    ['Search', 'SearchCubit + StatefulWidget', 'Users tab and Messages tab global search'],
    ['Profile', 'ProfileCubit + StatefulWidget', 'Edit profile, gallery photo, default landscape avatar'],
    ['Settings', 'SettingsCubit + StatefulWidget', 'Notifications, sound alerts, TTS toggles'],
    ['User Detail', 'StatefulWidget', 'View contact, call, message, block/unblock'],
    ['Status', 'StatefulWidget + StatusRepository', 'Text/photo status, default landscape, 24h expiry'],
    ['Call', 'StatefulWidget', 'Simulated voice/video call UI with timer and controls'],
    ['Call History', 'CallHistoryCubit + BlocBuilder', 'Past voice/video calls with missed/outgoing flags'],
  ], [18, 22, 60]),
  h2('7.2 Navigation and Routing'),
  p('Named routes in app.dart with RouteSettings arguments. MultiBlocProvider at app root supplies Cubits to all screens.'),
  h2('7.3 State Management'),
  p('Shared application state uses flutter_bloc Cubits at lib/presentation/state/. Local UI state (text fields, tabs, recording timer, call duration) stays in StatefulWidget screens. Cubits call domain use cases; use cases call repositories. UI rebuilds via BlocBuilder / context.read after each emit.'),
  table(['Cubit', 'Screen(s)', 'Use case(s) called'], [
    ['ChatListCubit', 'Chat List', 'LoadChats, block refresh'],
    ['ChatDetailCubit', 'Chat Detail', 'SendMessage, ReceiveMessage, EditMessage, DeleteMessage'],
    ['GroupCubit', 'Create Group', 'CreateGroupUseCase'],
    ['SearchCubit', 'Search', 'SearchUsers, SearchMessages'],
    ['ProfileCubit', 'Profile', 'UpdateProfile'],
    ['SettingsCubit', 'Settings', 'UpdateSettings'],
    ['CallHistoryCubit', 'Call History', 'LoadCallHistory'],
  ], [22, 22, 56]),
  table(['StatefulWidget screen', 'Local state managed'], [
    ['SplashScreen', 'Animation timer, navigation delay'],
    ['ChatDetailScreen', 'Input focus, emoji panel, mention picker visibility'],
    ['CreateGroupScreen', 'Group name field, member checkbox selection'],
    ['SearchScreen', 'Tab controller (Users / Messages)'],
    ['CallScreen', 'Call timer, mute/end button state'],
    ['StatusScreen', 'Gallery picker, caption field'],
  ], [30, 70]),
  h2('7.4 Validation, Error Handling, and User Feedback'),
  table(['Situation', 'Handling', 'User feedback'], [
    ['Empty message', 'Ignored in sendText', 'No action'],
    ['Blocked user (direct)', 'SendMessageUseCase throws', 'Error snackbar; input disabled'],
    ['Unblock user', 'SettingsDao removes block row', 'Banner removed; messaging enabled'],
    ['Voice permission denied', 'startRecording returns false', 'Mic button inactive'],
    ['Create group missing name/members', 'CreateGroupUseCase / GroupCubit validation', 'Helper text + disabled Create button'],
    ['Muted chat', 'Skip notifications', 'Mute icon on chat tile'],
  ], [25, 35, 40]),
  h2('7.5 Important Code Files (no source code in report)'),
  table(['File', 'Purpose'], [
    ['persistence_service.dart', 'JSON save/load fallback for web and desktop'],
    ['in_memory_store.dart', 'Unified store: sqflite on mobile, JSON fallback; dual-write on CRUD'],
    ['app_assets.dart', 'Bundled mountain_landscape.png path for profile/status'],
    ['block_user_usecase.dart', 'Block/unblock single user pair'],
    ['settings_dao.dart', 'hasBlocked(), isBlocked(), duplicate block prevention'],
    ['receive_message_usecase.dart', 'Incoming alerts; voice/text simulated replies'],
    ['send_message_usecase.dart', 'Send with block check (direct chats only)'],
    ['auto_reply_service.dart', 'generateVoiceReply() for contextual voice captions'],
    ['media_service.dart', 'Voice recording (record) and playback (just_audio)'],
    ['notification_sound_service.dart', 'Plays message_notification.wav'],
    ['create_group_usecase.dart', 'Validates group name and member list (OMAR + ≥1 contact)'],
    ['group_dao.dart', 'Inserts group chat, chat_members, and unread_counts rows'],
    ['create_group_screen.dart', 'UI: name field, member checkboxes, Create action'],
  ], [45, 55]),
  h2('7.6 Voice Message Implementation'),
  p('Voice messages use the record package (AAC .m4a) saved to the app documents folder. Attachments link file paths in the attachments table. VoiceMessageWidget plays audio via just_audio. After OMAR sends a voice message, ReceiveMessageUseCase simulates a contextual voice reply.'),
  ...shotFile('04_voice_messages.png', 'Voice messages in direct chat'),
  ...shotFile('03_direct_reply.png', 'Contextual text reply after send'),
  table(['Step', 'Component', 'Action'], [
    ['1', 'ChatInputBar', 'User taps mic to start/stop recording'],
    ['2', 'MediaService', 'Saves .m4a to app documents directory'],
    ['3', 'SendMessageUseCase', 'Inserts message type voice + attachment row'],
    ['4', 'ReceiveMessageUseCase', 'Simulates peer voice reply with caption'],
    ['5', 'VoiceMessageWidget', 'Play/stop toggle for sender and receiver'],
  ], [8, 28, 64]),
  h2('7.7 Block and Unblock Implementation'),
  p('Blocking stores a directed pair in blocked_users. Block check applies to direct chats only. Unblock removes the row and restores messaging.'),
  ...shotFile('07_block_dialog.png', 'Block user confirmation'),
  ...shotFile('12_block_banner.png', 'Blocked banner and disabled input'),
  table(['Rule', 'Implementation'], [
    ['Block one user only', 'blockUser() inserts single pair; no global flag'],
    ['Prevent duplicate blocks', 'SettingsDao checks existing row before insert'],
    ['Group chat unaffected', 'Block check skipped when chat_type is group'],
    ['Restore messaging', 'unblockUser() deletes pair; ChatListCubit refreshed'],
  ], [30, 70]),
  h2('7.8 Profile Photo and Status Photo'),
  p('Gallery picker and bundled mountain_landscape.png via AppAssets. Profile and Status screens support both options.'),
  ...shotFile('11_profile.png', 'Profile screen'),
  ...shotFile('13_status_landscape.png', 'Status with mountain landscape photo'),
  h2('7.9 Create Multi-User Group (Latest Feature)'),
  p('This is the most recently added feature. OMAR can create a brand-new group chat with multiple users without using pre-seeded groups only. Implementation spans CreateGroupScreen (UI), GroupCubit (state), CreateGroupUseCase (business rules), and GroupDao (persistence).'),
  ...shotFile('09_chat_menu_new_group.png', 'Create Multi-User Group — New group menu entry'),
  table(['Step', 'User action / component', 'Result'], [
    ['1', 'Chat List → menu **New group** or **New group** FAB', 'Opens Create Group screen'],
    ['2', 'Enter group name in text field', 'Create button enabled when name + members set'],
    ['3', 'Check one or more contacts in list', 'Selected chips shown; OMAR added automatically'],
    ['4', 'Tap **Create** (app bar) or **Create Group** (bottom)', 'GroupCubit.createGroup() runs'],
    ['5', 'CreateGroupUseCase + GroupDao', 'New row in chats (type group), chat_members for each user, unread_counts initialized'],
    ['6', 'PersistenceService auto-save', 'Group survives app restart (SQLite on mobile)'],
    ['7', 'ChatListCubit.loadChats() + navigation', 'Group on chat list; Chat Detail opens as group chat'],
  ], [8, 42, 50]),
  table(['Validation rule', 'Where enforced'], [
    ['Group name required', 'CreateGroupUseCase, GroupCubit, CreateGroupScreen'],
    ['At least one other member selected', 'CreateGroupUseCase (total members ≥ 2 including OMAR)'],
    ['Broadcast message optional', 'Separate action — does not replace group creation'],
  ], [40, 60]),
  h2('7.10 Data Persistence Implementation'),
  p('InMemoryStore.initialize() opens sqflite on Android/iOS (omar_chat.db) and loads all 11 tables into memory lists for fast query(). Every insert(), update(), and deleteWhere() dual-writes to SQLite. On web or when sqflite is unavailable (desktop fallback), the same API persists to JSON via PersistenceService. OmarChatApp registers WidgetsBindingObserver to flush JSON on app pause/detached. ChatDao and UnreadDao use store.query() for filtered reads — consistent with the DAO pattern required by the rubric.'),

  h1('8. Testing and Quality Assurance'),
  table(['ID', 'Feature', 'Expected', 'Result'], [
    ['T-01', 'Send/receive message', 'Message appears in chat', 'Pass'],
    ['T-02', 'Sound + TTS', 'Hear tone + sender announcement', 'Pass'],
    ['T-03', 'Group @mention', 'Mentioned user replies', 'Pass'],
    ['T-04', 'Block user (direct)', 'Send fails; input disabled; others OK', 'Pass'],
    ['T-05', 'Unblock user', 'Messaging restored after unblock', 'Pass'],
    ['T-06', 'Voice send/receive', 'Voice bubble + simulated voice reply', 'Pass'],
    ['T-07', 'Default landscape photo', 'Profile/status shows bundled image', 'Pass'],
    ['T-08', 'Data persistence', 'Data unchanged after app restart', 'Pass'],
    ['T-09', 'Group chat while user blocked', 'Group send still works', 'Pass'],
    ['T-10', 'Create multi-user group', 'Named group saved; opens in chat list', 'Pass'],
    ['T-11', 'Windows / Edge / Android', 'App launches on target platform', 'Pass'],
  ], [8, 28, 38, 26]),

  h1('9. Challenges, Design Decisions, and Solutions'),
  h2('9.1 Key Technical Challenges'),
  table(['Challenge', 'Solution'], [
    ['Data lost on app restart', 'sqflite dual-write on mobile; JSON fallback on web/desktop'],
    ['Blocking one user blocked group sends', 'Block check limited to direct chats only'],
    ['No unblock UI', 'Block/Unblock in Chat Detail menu and User Detail screen'],
    ['sqflite unavailable on web', 'InMemoryStore with same DAO/Repository API + JSON persistence'],
    ['Voice reply simulation', 'Demo voice asset + contextual text caption in reply bubble'],
    ['Create group button unclear', 'Dedicated Create action, helper text, New group FAB on Chat List'],
  ], [35, 65]),
  h2('9.2 Key Design Decisions'),
  table(['Decision', 'Reason'], [
    ['Cubit over setState', 'Shared state across 11 screens; testable use cases'],
    ['Repository pattern', 'UI never touches SQL; easy storage backend swap'],
    ['Separate sound + TTS services', 'Independent toggles in Settings'],
  ], [35, 65]),

  h1('10. Conclusion and Future Work'),
  h2('10.1 Summary'),
  p('OMAR Chat meets CEN306 requirements with layered architecture, nine DAO classes, eight repositories, Cubit state management, 11 screens, multi-user group creation, sound/TTS notifications, @mention auto-replies, voice messaging with voice replies, per-user block/unblock, default landscape profile/status photos, and SQLite persistence (sqflite on Android/iOS; JSON fallback on web).'),
  h2('10.2 Future Improvements'),
  table(['Improvement', 'Approach'], [
    ['Cloud sync', 'Firebase Firestore + Cloud Messaging'],
    ['Real calls', 'WebRTC / Agora SDK'],
    ['Authentication', 'Firebase Auth or custom JWT API'],
  ], [30, 70]),

  pb(),
  h1('11. References'),
  table(['Source', 'Type', 'How it was used'], [
    ['Flutter documentation', 'Official', 'Widgets, navigation, assets'],
    ['flutter_bloc', 'Package', 'Cubit state management'],
    ['sqflite', 'Package', 'SQLite on mobile'],
    ['flutter_local_notifications / flutter_tts / just_audio / record', 'Packages', 'Alerts, sound, voice record/playback'],
  ], [35, 20, 45]),

  h1('12. Appendices'),
  h2('Appendix A: Screenshot Index (Manual Captures)'),
  p('All images from report_assets/screenshots/ — mapped in SCREENSHOT_MAP.md.'),
  table(['Feature', 'Screenshot file'], [
    ['Chat list', '01_chat_list.png'],
    ['Direct chat', '02_direct_chat.png'],
    ['Simulated reply / sound+TTS', '03_direct_reply.png'],
    ['Voice messages', '04_voice_messages.png'],
    ['Voice call', '05_voice_call.png'],
    ['Video call', '06_video_call.png'],
    ['Block dialog', '07_block_dialog.png'],
    ['Block send error', '08_block_send_error.png'],
    ['Create group (menu entry)', '09_chat_menu_new_group.png'],
    ['Settings', '10_settings.png'],
    ['Profile', '11_profile.png'],
    ['Block banner', '12_block_banner.png'],
    ['Status landscape', '13_status_landscape.png'],
    ['Search users', '14_search_users.png'],
    ['Search messages', '15_search_messages.png'],
    ['@Mention picker', '16_group_mention_picker.png'],
    ['@Mention reply', '17_group_mention_reply.png'],
    ['Mute & chat theme', '18_group_mute_theme.png'],
    ['Group image', '19_group_image.png'],
    ['Group emoji', '20_group_emoji.png'],
    ['Drawing board', '21_drawing_board.png'],
    ['Group attachments', '22_group_attachments.png'],
  ], [40, 60]),
  h2('Appendix C: Complete Feature List'),
  table(['#', 'Feature', 'Description'], [
    ['1', 'Direct & group messaging', 'Text, emoji, reply, edit, delete, attachments, drawing'],
    ['2', 'Voice messages', 'Record, send, play; simulated voice reply with caption'],
    ['3', 'Sound + TTS notifications', 'Alert tone + spoken sender name on incoming messages'],
    ['4', 'Group @mention auto-reply', 'Mentioned members reply contextually'],
    ['5', 'Create multi-user group', 'Name group, select members, persist and open chat'],
    ['6', 'Block / unblock user', 'Block one contact; unblock restores messaging'],
    ['7', 'Data persistence', 'All data saved on close; restored on reopen'],
    ['8', 'Profile photo', 'Gallery or default mountain landscape asset'],
    ['9', 'Photo/text status', '24h status with gallery or default landscape'],
    ['10', 'Search', 'Global user and message search'],
    ['11', 'Mute chat', 'Suppress notifications per chat'],
    ['12', 'Chat themes', 'Default, Lion, Sea wallpapers'],
    ['13', 'Simulated calls', 'Voice/video call UI + call history'],
    ['14', 'Unread badges', 'Per-chat and total unread summary'],
    ['15', 'Layered architecture', 'UI / Business / Data / Services separation'],
  ], [6, 22, 72]),
  h2('Appendix B: Repository and Submission Links'),
  table(['Item', 'Link / note'], [
    ['Source code repository', '[Add repository URL]'],
    ['Demo video', '[Add YouTube URL]'],
    ['Source code zip', 'lib/ folder + pubspec.yaml only (OMAR_Chat_SourceCode.zip)'],
  ], [30, 70]),
];

const doc = new Document({
  styles: { default: { document: { run: { font: 'Calibri', size: SZ_BODY } } } },
  sections: [{
    properties: { page: { margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    headers: {
      default: new Header({
        children: [para(run('OMAR Chat — CEN306 Project Report', { size: 16, color: '666666', italics: true }), {
          align: AlignmentType.RIGHT,
          after: 0,
        })],
      }),
    },
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ children: [PageNumber.CURRENT], size: 18, color: '666666' })],
          }),
        ],
      }),
    },
    children: headerPage,
  }],
});

const buffer = await Packer.toBuffer(doc);
fs.writeFileSync(outDocx, buffer);
console.log('Report written to', outDocx);
