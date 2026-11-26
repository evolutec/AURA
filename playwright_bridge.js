const { chromium } = require('playwright');
const readline = require('readline');

let browser = null;

function send(msg) {
  process.stdout.write(JSON.stringify(msg) + '\n');
}

const rl = readline.createInterface({ input: process.stdin });
const pending = new Map();

rl.on('line', (line) => {
  if (!line.trim()) return;
  const req = JSON.parse(line);
  const { id, action, ...args } = req;
  handle(id, action, args).then(
    (res) => send({ id, ok: true, ...res }),
    (err) => send({ id, ok: false, error: String(err) }),
  );
});

async function handle(id, action, args) {
  switch (action) {
    case 'launch': {
      const port = args.port || 9333;
      browser = await chromium.launch({
        headless: true,
        args: [`--remote-debugging-port=${port}`],
      });
      await browser.newPage();
      return { status: 'launched' };
    }
    case 'close': {
      if (browser) {
        await browser.close();
        browser = null;
      }
      return { status: 'closed' };
    }
    case 'navigate': {
      if (!browser) return { error: 'no_browser' };
      const p = await browser.newPage();
      await p.goto(args.url, { timeout: args.timeout || 30000 });
      return { url: p.url(), title: await p.title() };
    }
    case 'click': {
      if (!browser) return { error: 'no_browser' };
      const p = await browser.contexts()[0].pages()[0];
      const el = p.locator(args.selector || args.text).first();
      await el.click();
      return { clicked: args.selector || args.text };
    }
    case 'fill': {
      if (!browser) return { error: 'no_browser' };
      const p = await browser.contexts()[0].pages()[0];
      await p.locator(args.selector || '#q').fill(args.text);
      return { filled: args.selector || '#q' };
    }
    case 'evaluate': {
      if (!browser) return { error: 'no_browser' };
      const p = await browser.contexts()[0].pages()[0];
      const res = await p.evaluate(args.script);
      return { result: String(res) };
    }
    case 'screenshot': {
      if (!browser) return { error: 'no_browser' };
      const p = await browser.contexts()[0].pages()[0];
      const buf = await p.screenshot({ fullPage: args.fullPage === 'true' });
      return { base64: buf.toString('base64') };
    }
    case 'wait_for': {
      if (!browser) return { error: 'no_browser' };
      const p = await browser.contexts()[0].pages()[0];
      await p.waitForTimeout(args.ms || 1000);
      return { status: 'ok' };
    }
    default:
      return { error: `unknown_action:${action}` };
  }
}

process.on('SIGTERM', async () => {
  if (browser) await browser.close();
  process.exit(0);
});

send({ status: 'ready' });
