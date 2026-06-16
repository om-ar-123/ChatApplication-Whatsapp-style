/**
 * Export report to PDF — emulator screenshots embedded per feature.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import puppeteer from 'puppeteer-core';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const pdfPath = path.join(root, 'CEN306_OMAR_Chat_Project_Report.pdf');
const shotsDir = path.join(root, 'report_assets', 'screenshots');

const BLUE = '#1F4E79';
const BLUE_LIGHT = '#D9EAF7';
const ROW_ALT = '#F4F6F7';

const edgePaths = [
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
];

function findBrowser() {
  for (const p of edgePaths) if (fs.existsSync(p)) return p;
  throw new Error('Edge/Chrome not found');
}

function imgFile(filename, caption) {
  const full = path.join(shotsDir, filename);
  if (!fs.existsSync(full)) return `<p><em>[Missing: ${caption}]</em></p>`;
  const b64 = fs.readFileSync(full).toString('base64');
  return `<figure><img src="data:image/png;base64,${b64}" alt="${caption}"/><figcaption>${caption}</figcaption></figure>`;
}

function coverRow(label, value, alt) {
  const bg = alt ? BLUE_LIGHT : '#fff';
  const bg2 = alt ? '#fff' : BLUE_LIGHT;
  return `<tr><td class="cover-label" style="background:${bg}">${label}</td><td class="cover-value" style="background:${bg2}">${value}</td></tr>`;
}

function tbl(headers, rows) {
  const th = headers.map((h) => `<th>${h}</th>`).join('');
  const body = rows.map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join('')}</tr>`).join('');
  return `<table><tr>${th}</tr>${body}</table>`;
}

function featureGrid(items) {
  const cards = items.map(({ title, desc, file, caption }) => {
    const img = imgFile(file, caption);
    return `<div class="card"><strong>${title}</strong><p>${desc}</p>${img}</div>`;
  }).join('');
  return `<div class="grid">${cards}</div>`;
}

const html = `<!DOCTYPE html><html><head><meta charset="utf-8"/>
<style>
  @page { size: A4; margin: 10mm 8mm; }
  body { font-family: Calibri, Arial, sans-serif; font-size: 8.5pt; color: #1A1A1A; line-height: 1.22; margin: 0; }
  h1 { color: ${BLUE}; font-size: 12pt; margin: 6px 0 3px; page-break-after: avoid; }
  h2 { color: ${BLUE}; font-size: 10pt; margin: 5px 0 2px; page-break-after: avoid; }
  p { margin: 2px 0 4px; }
  table { width: 100%; border-collapse: collapse; margin: 3px 0 5px; font-size: 8pt; }
  th { background: ${BLUE}; color: #fff; padding: 2px 4px; border: 1px solid #2C3E50; }
  td { border: 1px solid #CCCCCC; padding: 2px 4px; vertical-align: top; }
  tbody tr:nth-child(even) td { background: ${ROW_ALT}; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 8px; margin: 4px 0 6px; }
  .card { page-break-inside: avoid; border: 1px solid #e0e0e0; padding: 4px; background: #fafafa; }
  .card p { font-size: 7.5pt; margin: 1px 0 3px; }
  .card strong { font-size: 8pt; color: ${BLUE}; }
  figure { text-align: center; margin: 2px 0; }
  img { max-width: 88px; max-height: 150px; width: auto; height: auto; border: 1px solid #ccc; }
  figcaption { font-size: 7pt; color: #555; font-style: italic; margin-top: 1px; }
  pre { font-family: 'Courier New', monospace; font-size: 7pt; background: #F4F4F4; padding: 4px; }
  .page-break { page-break-before: always; }
  .uni { text-align: center; margin-top: 8px; }
  header.doc { font-size: 7pt; color: #666; text-align: right; margin-bottom: 4px; }
</style></head><body>

<div class="uni" style="margin-top:20px">
  <p style="font-size:14pt;font-weight:bold">İSTANBUL TOPKAPI ÜNİVERSİTESİ</p>
  <p style="font-size:12pt;font-weight:bold">Faculty of Engineering</p>
  <p style="font-size:16pt;font-weight:bold">Project Report</p>
  <p style="margin-top:12px">Adı: CEN306 — Mobile Application Design and Development</p>
  <p>Date: 15/06/2026</p>
  ${tbl(['Name-Surname', 'Signature', 'Student No'], [
    ['OMAR ASLAN', '', '22040102144'],
    ['MALAK MEDHAT', '', '22040102054'],
    ['', '', ''],
  ])}
  <p>Programı: Bilgisayar Mühendisliği (İng.)</p>
  <p style="margin-top:8px;font-size:8pt">(This section will be filled out by the Instructor.)</p>
  ${tbl(['Subject of Evaluation', 'Evaluation Score'], [
    ['Flutter Mobile Application Project — Code Evaluation (70 Points)', ''],
    ['Flutter Mobile Application Project — Project Report Evaluation (30 Points)', ''],
  ])}
  <p style="margin-top:14px;font-weight:bold;color:${BLUE}">CEN306 - Mobile Application Design and Development</p>
  <p style="font-size:12pt;font-weight:bold;color:${BLUE}">Final Exam Project Report</p>
</div>
<table style="margin-top:8px">
${coverRow('Project Title', 'OMAR Chat — WhatsApp-Style Mobile Messaging Application', true)}
${coverRow('Student Name-Surname', 'OMAR ASLAN & MALAK MEDHAT', false)}
${coverRow('Student Number', '22040102144 / 22040102054', true)}
${coverRow('Instructor', 'Dr. Yıldız Karadayı', false)}
${coverRow('Submission Date', '15/06/2026', true)}
</table>
<p style="font-size:8pt;margin-top:6px">Academic Integrity Statement: I confirm that this report and project were prepared by me and that all external sources, libraries, code snippets, and datasets are properly acknowledged.</p>
<div class="page-break"></div>

<header class="doc">OMAR Chat — CEN306 Project Report (Manual Screenshots)</header>

<h1>1. Executive Summary</h1>
<p>OMAR Chat by <strong>OMAR ASLAN</strong> and <strong>MALAK MEDHAT</strong> is a WhatsApp-style Flutter app with direct/group messaging, multi-user group creation, voice messages, simulated calls, block/unblock, sound+TTS notifications, @mention auto-replies, search, status, profile, SQLite persistence (sqflite on Android/iOS), and bundled landscape photos. Screenshots in this report were captured manually on Android.</p>

<h1>2. Main Features</h1>
${tbl(['Feature', 'Description'], [
  ['Chat list & direct messaging', 'Unread badges, text chat, simulated replies'],
  ['Voice messages + replies', 'Record/send voice; contextual voice/text reply'],
  ['Simulated voice/video calls', 'Call UI with timer and controls'],
  ['Block / Unblock one user', 'Block dialog, send prevention, banner, unblock from menu'],
  ['Create multi-user group', 'New group from menu/FAB; name + select members'],
  ['Sound + TTS', 'Alert tone + spoken sender name'],
  ['@Mention auto-reply', 'Group members reply contextually'],
  ['Search', 'Users tab and Messages tab'],
  ['Status & profile', 'Edit profile; 24h status with landscape photo'],
  ['Group media', 'Images, emoji, files, drawing board, mute, chat themes'],
  ['Data persistence', 'SQLite (sqflite) on mobile; JSON fallback on web/desktop'],
])}

<h1>3. Rubric Compliance (100 Points)</h1>
${tbl(['Area', 'Pts', 'Evidence in OMAR Chat'], [
  ['≥5 screens (11 total)', '10', 'Splash, Chat List, Detail, Create Group, Search, Profile, Settings, User Detail, Status, Call, Call History'],
  ['Screen variety', '5', 'List, detail, create/edit, settings screens'],
  ['Navigation', '3', 'Named routes — app.dart'],
  ['UI usability', '2', 'WhatsApp-style layout — §4 screenshots'],
  ['Layer separation', '10', 'presentation / domain / data folders'],
  ['Responsibilities', '5', 'Cubit → UseCase → Repository → DAO'],
  ['Folder structure', '3', '§5 architecture tree'],
  ['SQLite + CRUD', '5', 'sqflite; db_constants.dart; DAO insert/select/update'],
  ['DAO classes', '4', 'MessageDao, ChatDao, UserDao, GroupDao, …'],
  ['Repository', '3', 'MessageRepository, ChatRepository, …'],
  ['Data flow', '3', '§6.4 incoming message example'],
  ['State management', '15', 'flutter_bloc Cubits + StatefulWidget screens'],
  ['Report sections', '30', 'Purpose, architecture, screenshots, challenges — this document'],
])}

<h1>4. Screenshots by Feature</h1>
<h2>4.1 Chat, Voice & Calls</h2>
${featureGrid([
  { title: 'Chat List', desc: 'Unread badges on direct and group chats.', file: '01_chat_list.png', caption: 'Chat List' },
  { title: 'Direct Chat', desc: 'One-to-one messaging with Mohamed.', file: '02_direct_chat.png', caption: 'Direct Chat' },
  { title: 'Simulated Reply', desc: 'Contextual reply + sound/TTS alert.', file: '03_direct_reply.png', caption: 'Direct Reply' },
  { title: 'Voice Messages', desc: 'Record and play voice bubbles.', file: '04_voice_messages.png', caption: 'Voice Messages' },
  { title: 'Voice Call', desc: 'Simulated encrypted voice call.', file: '05_voice_call.png', caption: 'Voice Call' },
  { title: 'Video Call', desc: 'Simulated video call UI.', file: '06_video_call.png', caption: 'Video Call' },
])}

<h2>4.2 Block, Settings, Profile, Search</h2>
${featureGrid([
  { title: 'Block Dialog', desc: 'Confirm before blocking a user.', file: '07_block_dialog.png', caption: 'Block Dialog' },
  { title: 'Block Error', desc: 'Cannot send when user is blocked.', file: '08_block_send_error.png', caption: 'Block Error' },
  { title: 'Blocked Banner', desc: 'Disabled input; unblock from menu.', file: '12_block_banner.png', caption: 'Block Banner' },
  { title: 'Settings', desc: 'Notifications, sound, TTS toggles.', file: '10_settings.png', caption: 'Settings' },
  { title: 'Profile', desc: 'Edit OMAR profile fields.', file: '11_profile.png', caption: 'Profile' },
  { title: 'Status Photo', desc: 'Mountain landscape status.', file: '13_status_landscape.png', caption: 'Status' },
  { title: 'Search Users', desc: 'Find contacts globally.', file: '14_search_users.png', caption: 'Search Users' },
  { title: 'Search Messages', desc: 'Find message text globally.', file: '15_search_messages.png', caption: 'Search Messages' },
])}

<div class="page-break"></div>
<h2>4.3 Group Features & Create Group</h2>
${featureGrid([
  { title: 'Group Chat', desc: 'Project Team with sender names.', file: '17_group_mention_reply.png', caption: 'Group Chat' },
  { title: '@Mention Picker', desc: 'Select member to mention.', file: '16_group_mention_picker.png', caption: '@Mention' },
  { title: 'Mute & Theme', desc: 'Per-chat mute and wallpaper.', file: '18_group_mute_theme.png', caption: 'Mute/Theme' },
  { title: 'Image', desc: 'Send image in group.', file: '19_group_image.png', caption: 'Image' },
  { title: 'Emoji', desc: 'Emoji picker in group.', file: '20_group_emoji.png', caption: 'Emoji' },
  { title: 'Drawing', desc: 'Hand-drawn message.', file: '21_drawing_board.png', caption: 'Drawing' },
  { title: 'Attachments', desc: 'Image, emoji, file, drawing.', file: '22_group_attachments.png', caption: 'Attachments' },
  { title: 'Create Group', desc: 'Menu → New group; name + select members.', file: '09_chat_menu_new_group.png', caption: 'New Group' },
])}

<div class="page-break"></div>
<h1>5. Technical Architecture</h1>
<h2>5.1 Layered Architecture Overview</h2>
<p>Dependencies flow one direction: <strong>UI Layer → Business Layer → Data Layer</strong>. Services and Core support all layers but do not replace the three required layers.</p>
<table><tr><th>Layer</th><th>Folder</th><th>Responsibility</th></tr>
<tr><td><strong>UI Layer (Presentation)</strong></td><td>lib/presentation/</td><td>11 screens, 19 widgets, 7 Cubits — display &amp; input only</td></tr>
<tr><td><strong>Business Layer (Domain)</strong></td><td>lib/domain/</td><td>6 entities, 11 use cases — business rules</td></tr>
<tr><td><strong>Data Layer</strong></td><td>lib/data/</td><td>11 models, 9 DAOs, 8 repositories, sqflite database</td></tr>
<tr><td>Services</td><td>lib/services/</td><td>Sound, TTS, notifications, media, files</td></tr>
<tr><td>Core</td><td>lib/core/</td><td>Constants, theme, routes, utilities</td></tr></table>

<h2>5.2 Project Structure — Folder Structure</h2>
<p>The three rubric-required layers are physically separated into three top-level folders. No screen code in domain/ or data/; no DAO/SQL code in presentation/.</p>
${tbl(['Required layer', 'Folder', 'Subfolders', 'Belongs here'], [
  ['UI Layer', 'lib/presentation/', 'screens/, widgets/, state/', 'Screens, widgets, Cubits — NO SQL/DAO'],
  ['Business Layer', 'lib/domain/', 'entities/, usecases/', 'Entities + use cases — NO widgets/SQL'],
  ['Data Layer', 'lib/data/', 'models/, dao/, repositories/, database/', 'Models, DAOs, repos, sqflite — NO UI'],
])}
<pre style="font-size:6.5pt;background:#F4F4F4;padding:4px;line-height:1.15">lib/
├── main.dart, app.dart
├── presentation/          ═══ UI LAYER ═══
│   ├── screens/           (11: Splash, ChatList, ChatDetail, CreateGroup, Search,
│   │                       Profile, Settings, UserDetail, Status, Call, CallHistory)
│   ├── widgets/           (ChatTile, MessageBubble, ChatInputBar, VoiceMessage, …)
│   └── state/             (ChatListCubit, ChatDetailCubit, GroupCubit, …)
├── domain/                ═══ BUSINESS LAYER ═══
│   ├── entities/          (User, Chat, Message, Group, CallRecord, CallSession)
│   └── usecases/          (SendMessage, ReceiveMessage, BlockUser, CreateGroup, …)
├── data/                  ═══ DATA LAYER ═══
│   ├── models/            (UserModel, MessageModel, ChatModel, … — 11 models)
│   ├── dao/               (UserDao, ChatDao, MessageDao, UnreadDao, … — 9 DAOs)
│   ├── repositories/      (UserRepository, ChatRepository, MessageRepository, … — 8 repos)
│   └── database/          (InMemoryStore + sqflite; JSON fallback on web)
├── services/              (persistence, sound, TTS, media, auto_reply, files)
└── core/                  (db_constants, app_routes, app_theme, utils)</pre>
<p><em>Figure 1. Folder structure with explicit UI / Business / Data layer separation.</em></p>
${tbl(['Call direction', 'Example'], [
  ['UI → Business', 'ChatDetailCubit → SendMessageUseCase'],
  ['Business → Data', 'SendMessageUseCase → MessageRepository → MessageDao'],
  ['NOT allowed', 'Screen imports message_dao.dart directly'],
])}

<h2>5.3 Layer Responsibilities</h2>
<p>UI renders and captures input via Cubits. Business validates rules. Data persists via DAO/Repository. Screens never call SQL directly.</p>

<h1>6. SQLite, DAO & Repository</h1>
<p>sqflite opens omar_chat.db with 11 tables. InMemoryStore dual-writes every CRUD to SQLite on Android/iOS; web/desktop use JSON via PersistenceService. DAOs perform CRUD through store.query(); Repositories map models to domain entities; Use Cases enforce business rules. Screens never call SQL directly.</p>
${tbl(['DAO', 'Table(s)', 'Key methods'], [
  ['UserDao', 'users', 'getAll, getById, update, searchByName'],
  ['ChatDao', 'chats, chat_members', 'insert, getChatsForUser, findDirectChat, updateLastMessage'],
  ['MessageDao', 'messages', 'insert, getByChatId, update, deleteWhere, searchContent'],
  ['GroupDao', 'chats, chat_members, unread_counts', 'createGroup, getMembers'],
  ['AttachmentDao', 'attachments', 'insert, getByMessageId'],
  ['StatusDao', 'statuses', 'insert, getActiveForUser, deleteExpired'],
  ['SettingsDao', 'blocked_users, muted_chats, theme_settings', 'block, unblock, mute, getTheme'],
  ['UnreadDao', 'unread_counts', 'increment, reset, getTotalForUser'],
  ['CallDao', 'call_history', 'insert, getAll, getByChatId'],
])}
${tbl(['Repository', 'Purpose'], [
  ['UserRepository', 'Profiles and contact search'],
  ['ChatRepository', 'Chat list, unread badges, last message'],
  ['MessageRepository', 'Messages with attachments and reply preview'],
  ['GroupRepository', 'Create group and list members'],
  ['AttachmentRepository', 'File/image attachment metadata'],
  ['StatusRepository', '24h status posts'],
  ['SettingsRepository', 'Block/unblock, mute, chat themes'],
  ['CallRepository', 'Simulated call history'],
])}

<h1>7. Screens & State Management</h1>
<p><strong>11 screens:</strong> Splash, Chat List, Chat Detail, Create Group, Search, Profile, Settings, User Detail, Status, Call, Call History.</p>
<p><strong>Cubits:</strong> ChatListCubit, ChatDetailCubit, GroupCubit, ProfileCubit, SettingsCubit, SearchCubit, CallHistoryCubit. <strong>StatefulWidget</strong> used for local UI (input fields, tabs, call timer, member selection).</p>

<h1>8. Technical Challenges & Solutions</h1>
${tbl(['Challenge', 'Solution'], [
  ['sqflite required by rubric', 'Integrated sqflite in InMemoryStore for Android/iOS; web JSON fallback'],
  ['Block one user blocked groups', 'Block check limited to direct chats in SendMessageUseCase'],
  ['Sound + TTS on incoming messages', 'ReceiveMessageUseCase + NotificationSoundService + SpeechService'],
  ['Create group UX unclear', 'New group FAB, helper text, CreateGroupUseCase validation'],
  ['Data survives restart', 'SQLite persistence on mobile; JSON on web'],
])}

<h1>10. Conclusion</h1>
<p>OMAR Chat delivers full WhatsApp-style messaging with layered architecture, nine DAO classes, eight repositories, Cubit state management, SQLite persistence on Android/iOS, and all documented features verified with manual Android screenshots.</p>

<h1>12. Appendix — Screenshot Index</h1>
${tbl(['File', 'Feature'], [
  ['01_chat_list.png', 'Chat List'],
  ['02_direct_chat.png', 'Direct Chat'],
  ['03_direct_reply.png', 'Simulated Reply / Sound+TTS'],
  ['04_voice_messages.png', 'Voice Messages'],
  ['05_voice_call.png', 'Voice Call'],
  ['06_video_call.png', 'Video Call'],
  ['07_block_dialog.png', 'Block Dialog'],
  ['08_block_send_error.png', 'Block Send Error'],
  ['09_chat_menu_new_group.png', 'Create Group Entry'],
  ['10_settings.png', 'Settings'],
  ['11_profile.png', 'Profile'],
  ['12_block_banner.png', 'Block Banner'],
  ['13_status_landscape.png', 'Status Landscape'],
  ['14_search_users.png', 'Search Users'],
  ['15_search_messages.png', 'Search Messages'],
  ['16_group_mention_picker.png', '@Mention Picker'],
  ['17_group_mention_reply.png', '@Mention Reply'],
  ['18_group_mute_theme.png', 'Mute & Theme'],
  ['19_group_image.png', 'Group Image'],
  ['20_group_emoji.png', 'Group Emoji'],
  ['21_drawing_board.png', 'Drawing Board'],
  ['22_group_attachments.png', 'Group Attachments'],
])}
</body></html>`;

const browser = await puppeteer.launch({
  executablePath: findBrowser(),
  headless: 'new',
  args: ['--no-sandbox', '--allow-file-access-from-files'],
});
const page = await browser.newPage();
await page.setContent(html, { waitUntil: 'networkidle0' });
await page.pdf({
  path: pdfPath,
  format: 'A4',
  printBackground: true,
  margin: { top: '10mm', bottom: '10mm', left: '8mm', right: '8mm' },
});
await browser.close();
console.log('PDF written to', pdfPath);
