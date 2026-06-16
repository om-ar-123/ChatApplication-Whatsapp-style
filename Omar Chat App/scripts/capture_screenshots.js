/**
 * Captures OMAR Chat screenshots from the running web server.
 * Prerequisite: flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import puppeteer from 'puppeteer-core';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(__dirname, '..', 'report_assets', 'screenshots');
const baseUrl = process.env.APP_URL || 'http://127.0.0.1:7357';

const edgePaths = [
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
];

function findBrowser() {
  for (const p of edgePaths) if (fs.existsSync(p)) return p;
  throw new Error('Edge/Chrome not found');
}

async function snap(page, name) {
  const file = path.join(outDir, `${name}.png`);
  await page.screenshot({ path: file, fullPage: false });
  console.log('Saved', file);
  return file;
}

async function wait(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function tap(page, x, y) {
  await page.mouse.click(x, y);
  await wait(1200);
}

async function waitForFlutter(page, timeout = 45000) {
  await page.goto(baseUrl, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(3000);
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const ready = await page.evaluate(() => {
      const semantics = document.querySelectorAll('[role="button"], [role="text"], flt-semantics');
      const canvas = document.querySelector('canvas, flt-glass-pane');
      return semantics.length > 5 || !!canvas;
    });
    if (ready) break;
    await wait(500);
  }
  // Allow splash (2s) + chat list load
  await wait(3500);
}

async function openMenu(page, itemIndex) {
  // overflow menu (three dots) top-right
  await tap(page, 360, 48);
  await wait(400);
  // menu items start ~y 120, step ~48
  await tap(page, 280, 120 + itemIndex * 48);
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: findBrowser(),
    headless: false,
    args: [
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--use-angle=swiftshader',
      '--enable-webgl',
      '--window-size=390,844',
    ],
    defaultViewport: { width: 390, height: 844, deviceScaleFactor: 2 },
  });
  const page = await browser.newPage();
  await waitForFlutter(page);

  await snap(page, '01_splash_or_loading');
  await wait(2500);
  await snap(page, '02_chat_list');

  // First direct chat tile (Mohamed)
  await tap(page, 195, 230);
  await snap(page, '03_chat_detail_direct');

  await page.keyboard.press('Escape').catch(() => {});
  await tap(page, 30, 48); // back if available
  await wait(800);
  await snap(page, '02_chat_list_return');

  // Group chat tile (~4th item)
  await tap(page, 195, 360);
  await snap(page, '04_chat_detail_group');

  await tap(page, 30, 48);
  await wait(800);

  // Search icon in app bar
  await tap(page, 300, 48);
  await snap(page, '05_search');
  await tap(page, 30, 48);
  await wait(600);

  // Status camera icon
  await tap(page, 255, 48);
  await snap(page, '06_status');
  await tap(page, 30, 48);
  await wait(600);

  // Menu -> Settings (index 3: group, calls, status, profile, settings -> settings is 4)
  await openMenu(page, 4);
  await snap(page, '07_settings');
  await tap(page, 30, 48);
  await wait(600);

  await openMenu(page, 3);
  await snap(page, '08_profile');
  await tap(page, 30, 48);
  await wait(600);

  // FAB search -> pick user
  await tap(page, 350, 780);
  await wait(1000);
  await tap(page, 195, 220);
  await snap(page, '09_user_detail');
  await tap(page, 30, 48);
  await wait(600);

  await openMenu(page, 0);
  await snap(page, '10_create_group');

  await browser.close();
  console.log('Done. Screenshots in', outDir);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
