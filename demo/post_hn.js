// Post Show HN — ejecutar con Node.js + Playwright
// npm install playwright && npx playwright install chromium
//
// Uso:
//   $env:HN_USER="tu_usuario"; $env:HN_PASS="tu_password"; node post_hn.js
//
// El script abre HN en modo visible para que puedas revisar antes de enviar.
// Cambia HEADLESS a true si quieres que corra sin ventana.

const { chromium } = require('playwright');

const HEADLESS = false;

const TITLE =
  'Show HN: AntCrew – AI agents that analyze COBOL production incidents with human approval gates';

const URL = 'https://github.com/iagop03/cobol-insurance-demo';

const TEXT = `\
Most COBOL incident triage still happens with grep and tribal knowledge. \
A P1 at 2 AM means someone with 20 years of experience reading call chains \
by hand.

AntCrew indexes your COBOL corpus (programs + copybooks) into SQLite, then \
runs an agent loop that:
1. Finds the programs related to the incident description
2. Traces CALL chains and shared copybooks across subdirectories
3. Drafts an impact report with the exact lines to change
4. Gates every LLM decision behind a human approval checkpoint before \
writing anything

The approval gate is the key bit — the agent can't modify code without \
explicit confirmation at each step. All decisions are logged to an \
append-only TraceLog for audit.

Demo: I built a realistic insurance policy system (~35 COBOL programs, 5 \
business areas, DB2 embedded SQL) as a public corpus. It has three \
intentional bugs, including a MOD(months, 12) wrap that miscalculates \
late-payment penalties after 12 months.

Running \`antcrew cobol-incident\` on the requirements doc finds REHPOL.cbl \
in ~30s, traces it through MOVPOL → VALDAT, and points to the exact line.

Repo with the corpus: https://github.com/iagop03/cobol-insurance-demo

Would love feedback from anyone working in mainframe modernization or \
legacy system maintenance.`;

async function main() {
  const user = process.env.HN_USER;
  const pass = process.env.HN_PASS;
  if (!user || !pass) {
    console.error('Set HN_USER and HN_PASS environment variables first.');
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: HEADLESS });
  const page = await browser.newPage();

  // Login
  console.log('Logging in to Hacker News...');
  await page.goto('https://news.ycombinator.com/login');
  await page.fill('input[name="acct"]', user);
  await page.fill('input[name="pw"]', pass);
  await page.click('input[type="submit"]');
  await page.waitForURL('https://news.ycombinator.com/**');
  console.log('Logged in.');

  // Navigate to submit
  await page.goto('https://news.ycombinator.com/submit');
  await page.fill('input[name="title"]', TITLE);
  await page.fill('input[name="url"]',   URL);
  await page.fill('textarea[name="text"]', TEXT);

  console.log('\nForm filled. Review the browser window.');
  console.log('Press ENTER here to submit, or Ctrl+C to abort.');
  await new Promise(resolve => process.stdin.once('data', resolve));

  await page.click('input[type="submit"]');
  await page.waitForTimeout(2000);
  console.log('Submitted. Current URL:', page.url());

  await browser.close();
}

main().catch(err => { console.error(err); process.exit(1); });
