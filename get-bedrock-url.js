const { chromium } = require('playwright');

function log(message) {
  console.log(`[NODE INFO] ${message}`);
}

function error(message) {
  console.error(`[NODE ERROR] ${message}`);
}

(async () => {
  try {
    log("Starting Playwright");

    const browser = await chromium.launch({
      headless: true,
      channel: 'chrome'
    });

    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      viewport: { width: 1280, height: 800 }
    });

    const page = await context.newPage();

    await page.goto('https://www.minecraft.net/en-us/download/server/bedrock', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    await page.waitForSelector('a[href*="bedrock-server"][href$=".zip"]', {
      timeout: 15000
    });

    const link = await page
      .locator('a[href*="bedrock-server"][href$=".zip"]')
      .first()
      .getAttribute('href');

    if (!link) {
      error("No download link found");
      process.exit(1);
    }

    log(`Found download URL: ${link}`);

    await browser.close();

  } catch (err) {
    error(err.message);
    process.exit(1);
  }
})();