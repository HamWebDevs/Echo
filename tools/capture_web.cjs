// Requires Playwright and Chromium. Captures the actual Godot build, not mockups.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const root = path.resolve(__dirname, '..');
  const output = path.join(root, 'artifacts', 'store');
  fs.mkdirSync(output, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || (fs.existsSync('/usr/bin/chromium') ? '/usr/bin/chromium' : undefined),
    headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader'],
  });
  const errors = [];
  try {
  for (const screen of ['home', 'game', 'daily', 'results', 'collection', 'pal', 'settings', 'supporter']) {
    const page = await browser.newPage({ viewport: { width: 540, height: 960 }, deviceScaleFactor: 2 });
    await page.route('http://127.0.0.1:8765/', async route => {
      const response = await route.fetch();
      let body = await response.text();
      body = body.replace(/const GODOT_CONFIG = (.*);/, (_, source) => {
        const config = JSON.parse(source);
        config.args = ['--', '--capture=' + screen];
        return 'const GODOT_CONFIG = ' + JSON.stringify(config) + ';';
      });
      await route.fulfill({ response, body });
    });
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    page.on('pageerror', error => errors.push(String(error)));
    const ready = page.waitForEvent('console', { predicate: message => message.text().includes('CAPTURE_OK'), timeout: 45000 });
    await page.goto('http://127.0.0.1:8765/');
    await ready;
    await page.screenshot({ path: path.join(output, screen + '.png') });
    console.log('Captured', screen);
    await page.close();
  }
  if (process.argv.includes('--video')) {
    for (const [name, mode] of [['echoes', 'endless'], ['daily', 'daily'], ['one-more-run', 'retry']]) {
      const context = await browser.newContext({ viewport: { width: 540, height: 960 }, recordVideo: { dir: output, size: { width: 540, height: 960 } } });
      const page = await context.newPage();
      await page.route('http://127.0.0.1:8765/', async route => {
        const response = await route.fetch();
        let body = await response.text();
        body = body.replace(/const GODOT_CONFIG = (.*);/, (_, source) => {
          const config = JSON.parse(source);
          config.args = ['--', '--showcase=' + mode];
          return 'const GODOT_CONFIG = ' + JSON.stringify(config) + ';';
        });
        await route.fulfill({ response, body });
      });
      const ready = page.waitForEvent('console', { predicate: message => message.text().includes('SHOWCASE_READY'), timeout: 45000 });
      await page.goto('http://127.0.0.1:8765/');
      await ready;
      const video = page.video();
      await page.waitForTimeout(15000);
      await context.close();
      await video.saveAs(path.join(output, name + '-raw.webm'));
      console.log('Recorded', name);
    }
  }
  fs.writeFileSync(path.join(output, 'browser-errors.json'), JSON.stringify(errors, null, 2));
  if (errors.length) throw new Error(errors.join('\n'));
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
