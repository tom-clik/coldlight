import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

// Keep the browser installation alongside this converter, shared by Lucee users.
process.env.PLAYWRIGHT_BROWSERS_PATH ??= path.join(path.dirname(fileURLToPath(import.meta.url)), '.browsers');

export async function render(job) {
  const options = { width: 1200, height: 900, scale: 2, media: 'screen', transparent: false,
    timeout: 60, ...job.options };
  const allowed = ['width', 'height', 'scale', 'media', 'transparent', 'timeout', 'executablePath'];
  for (const key of Object.keys(job.options ?? {})) {
    if (!allowed.includes(key)) throw new Error(`Unknown renderer option: ${key}`);
  }
  for (const key of ['width', 'height', 'scale', 'timeout']) {
    if (typeof options[key] !== 'number' || !Number.isFinite(options[key]) || options[key] <= 0)
      throw new Error(`${key} must be a positive number`);
  }
  if (!Number.isInteger(options.width) || !Number.isInteger(options.height))
    throw new Error('Viewport width and height must be integers');
  if (!['screen', 'print'].includes(options.media) || typeof options.transparent !== 'boolean')
    throw new Error('Invalid media or transparent option');
  if (!Array.isArray(job.images)) throw new Error('images must be an array');
  const root = await fs.realpath(job.outputFolder);
  const names = new Set();
  const items = job.images.map(item => {
    if (typeof item.id !== 'string' || !item.id.trim()) throw new Error('Every image needs an ID');
    const filename = item.filename;
    if (typeof filename !== 'string' || !filename.endsWith('.png') ||
        /[\\:\x00-\x1f]/.test(filename) || path.posix.isAbsolute(filename) ||
        filename.split('/').some(part => !part || part === '..' || part === '.'))
      throw new Error(`Invalid relative PNG filename: ${filename}`);
    const output = path.join(root, filename);
    const key = process.platform === 'win32' ? output.toLowerCase() : output;
    if (names.has(key)) throw new Error(`Duplicate output filename: ${filename}`);
    names.add(key);
    return { id: item.id, filename, path: output };
  });
  if (!items.length) return [];
  let browser;
  let timer;
  let expired = false;
  const work = async () => {
    browser = await chromium.launch({ headless: true, timeout: options.timeout * 1000,
      executablePath: options.executablePath,
      // The input is a trusted local publication; allow its local CSS and font files.
      args: ['--allow-file-access-from-files'] });
    if (expired) {
      await browser.close();
      throw new Error('HTML image batch timed out');
    }
    const page = await browser.newPage({ viewport: { width: options.width, height: options.height },
      deviceScaleFactor: options.scale, reducedMotion: 'reduce' });
    page.setDefaultTimeout(options.timeout * 1000);
    await page.emulateMedia({ media: options.media });
    const resourceErrors = [];
    const relevant = request => ['stylesheet', 'font', 'image'].includes(request.resourceType());
    page.on('requestfailed', request => {
      if (relevant(request)) resourceErrors.push(`${request.url()}: ${request.failure()?.errorText}`);
    });
    page.on('response', response => {
      if (relevant(response.request()) && response.status() >= 400)
        resourceErrors.push(`${response.url()}: HTTP ${response.status()}`);
    });
    await page.goto(pathToFileURL(path.resolve(job.htmlFile)).href, { waitUntil: 'load' });
    // Load lazy images too; font readiness is checked again after images settle.
    await page.evaluate(async () => {
      await Promise.all([...document.images].map(async image => {
        image.loading = 'eager';
        if (image.currentSrc || image.src) await image.decode();
      }));
      await document.fonts.ready;
      if ([...document.fonts].some(font => font.status === 'error'))
        throw new Error('A document font failed to load');
    });
    if (resourceErrors.length) throw new Error(`Resources failed to load:\n${resourceErrors.join('\n')}`);
    const captures = [];
    // Validate all IDs before taking screenshots or writing output.
    for (const item of items) {
      const selector = await page.evaluate(id => `#${CSS.escape(id)}`, item.id);
      const element = page.locator(selector);
      if (await element.count() !== 1) throw new Error(`ID must match exactly one element: ${item.id}`);
      if (!await element.isVisible()) throw new Error(`Element is hidden: ${item.id}`);
      captures.push({ item, element });
    }
    const buffers = [];
    for (const { item, element } of captures) {
      const png = await element.screenshot({ type: 'png', animations: 'disabled',
        omitBackground: options.transparent, scale: 'device' });
      buffers.push({ item, png });
    }
    // No output is replaced unless every capture succeeds.
    for (const { item, png } of buffers) {
      if (expired) throw new Error('HTML image batch timed out');
      await fs.mkdir(path.dirname(item.path), { recursive: true });
      const parent = await fs.realpath(path.dirname(item.path));
      const relative = path.relative(root, parent);
      if (relative.startsWith('..' + path.sep) || relative === '..' || path.isAbsolute(relative))
        throw new Error(`Output folder escapes through a symbolic link: ${item.filename}`);
      // Refuse symlink files as well as directory escapes.
      const existing = await fs.lstat(item.path).catch(error => {
        if (error.code !== 'ENOENT') throw error;
        return null;
      });
      if (existing?.isSymbolicLink()) throw new Error(`Output is a symbolic link: ${item.filename}`);
      await fs.writeFile(item.path, png);
      item.width = png.readUInt32BE(16);
      item.height = png.readUInt32BE(20);
    }
    return items;
  };
  try {
    return await Promise.race([work(), new Promise((_, reject) => {
      timer = setTimeout(() => { expired = true; reject(new Error('HTML image batch timed out')); }, options.timeout * 1000);
    })]);
  } finally {
    clearTimeout(timer);
    if (browser) await browser.close();
  }
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  try {
    const job = JSON.parse(await fs.readFile(process.argv[2], 'utf8'));
    const images = await render(job);
    process.stdout.write(JSON.stringify({ ok: true, images }));
  } catch (error) {
    process.stdout.write(JSON.stringify({ ok: false, error: error.message }));
    process.exitCode = 1;
  }
}
