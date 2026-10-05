# HTML element images from Lucee

This converter loads one HTML document in headless Chromium and captures a batch
of elements by their literal HTML IDs. One browser and page are used per batch.
The complete document supplies the original CSS, fonts, inheritance and layout.

## Installation

Install Node.js 20 or later on the Lucee host. From this directory run:

```text
npm ci
npm run install-browser
```

On Linux, install Chromium's system libraries too (the dependency installation
may require an administrator):

```text
npm run install-browser -- --with-deps
```

The installation script puts Chromium in this directory's ignored `.browsers`
folder. The Lucee service account needs read/execute access here and write access
to its temporary and output directories. `PLAYWRIGHT_BROWSERS_PATH` can override
the browser location for both installation and rendering. Re-run installation
after changing the pinned Playwright version. No browser is downloaded during
an image conversion. The default bundled Chromium keeps rendering consistent;
`executablePath` can select a separately installed compatible browser.

## Main ColdLight component

Use the initialized `coldlight.coldlight` component after the final HTML has been built,
including the document's `<head>` and linked stylesheets. `saveImages` accepts a
Jsoup Document or an HTML string. It parses a copy and sets a temporary
`<base>` URL; it does not alter the caller's document or its `data-image` attributes.

```cfml
batch = [
    {id:"division", filename:"images/table-division.png"},
    {id:"total1", filename:"images/table-total1.png"}
];
results = publisher.saveImages(
    document = htmlDocument,
    images = batch,
    outputFolder = expandPath("/publications/book/"),
    baseUrl = "http://localhost:8089/publications/book/book.html",
    nodePath = "C:/Program Files/nodejs/node.exe",
    options = {width:1200, scale:2}
);
```

For marked tables, build the same batch with:

```cfml
batch = publisher.tableImageBatch(htmlDocument);
```

This selects `table[data-image]` and generates `images/table-{id}.png`. The old
attribute value is only a marker, not an output filename. IDs must be present and
contain only letters, digits, underscores or hyphens for this naming helper.
Its optional `folder` argument defaults to `images`. Explicit batches accept
other literal IDs, including punctuation, because they are escaped as selectors.

For other elements or selection rules, use the generic helper:

```cfml
// Every element marked with data-image; images/image-{id}.png.
batch = publisher.imageBatch(htmlDocument);

// Large tables selected by class; images/table-{id}.png.
batch = publisher.imageBatch(
    node=htmlDocument, selector="table.large", folder="images", prefix="table"
);
```

`imageBatch` accepts any Jsoup CSS selector, output folder and filename prefix.
An empty prefix produces `{id}.png`. `tableImageBatch` is a convenience wrapper
for `selector="table[data-image]"` and `prefix="table"`. No Bridge plugin is
required for any image conversion. `publisher` above is your initialized
ColdLight instance (for example, `application.coldLight`).

`baseUrl` is the absolute original document URL, or its directory URL ending in
`/`. A `file:///.../` URL can be used for local assets. All relative resources are
resolved against this URL; any existing `<base>` is replaced in the snapshot.
The output folder must exist. Filenames are relative to it, use `/` separators,
and end in `.png`; child directories are created. Existing output PNGs are replaced.

Each returned item contains `id`, `filename`, absolute `path`, and pixel `width`
and `height`, in batch order. An empty batch returns `[]` without starting Node.

## Generic converter

Other callers can use the lower-level converter without initializing ColdLight:

```cfml
converter = new coldlight.converters.htmlToPng("/usr/bin/node");
results = converter.convert(html, batch, outputFolder, {scale:2});
```

The HTML string must contain an absolute `<base href="...">` if it references
relative resources. The converter passes a temporary JSON job to Node using
`cfexecute` with an argument array, and removes its temporary files in `finally`.
It raises `coldlight.htmlToPng` for renderer errors, including missing/duplicate
IDs, hidden elements and failed stylesheet, font or image requests.

## Options and rendering behaviour

| Option | Default | Meaning |
| --- | --- | --- |
| `width`, `height` | `1200`, `900` | Viewport dimensions in CSS pixels, determining wrapping and responsive CSS. |
| `scale` | `2` | Device scale; doubles PNG dimensions without changing CSS layout. |
| `media` | `screen` | `screen` or `print` CSS media. Chromium does not implement Prince pagination. |
| `transparent` | `false` | Omit the default browser background; explicit CSS backgrounds remain. |
| `timeout` | `60` | Maximum seconds for the complete batch, with a further 15 seconds allowed by Lucee for process cleanup. |
| `executablePath` | omitted | Optional absolute path to a compatible browser executable. |

The renderer waits for page load, image decoding and `document.fonts.ready`.
Animations are disabled during screenshots. Every ID is validated and every
capture completes before output files are written. A filesystem write failure
can still leave a partially written batch. Captures are held in memory until
that point, so split very large exports into smaller batches.

Element captures include borders and padding, but not margins or overflowing
content outside the element's box. Use a containing wrapper when that content
must be included. Captures remain in the original page layout; overlays can
obscure the target. Lazy images are eagerly decoded. Application-specific async
JavaScript completion is not inferred; supply finished publication HTML.

This is for trusted publication HTML: JavaScript runs and local file resources
are permitted. It is not an endpoint for arbitrary uploaded HTML or URLs.

## Verification

The sample script `sample/generate_images.cfm?file=relative/path/to/book.html`
reads a finished HTML file (relative to the sample script), finds every
`[data-image]` element and captures only missing PNGs. Here the attribute value
is the actual output filename, relative to the HTML document's directory;
it must stay within that directory. For example, `data-image="images/chart.png"`
creates `images/chart.png` beside the document. Existing files are left alone.
Elements without IDs receive temporary IDs, and the source HTML is not rewritten.
The JSON response lists generated images and skipped paths. Set the environment
variables `nodeExecutable` and optionally `chromiumExecutable` for the host;
the sample also detects the usual Windows Chrome installation.

Run `npm test` here for real-browser rendering and validation checks. Run
`/coldlight/testing/testHtmlImages.cfm` through Lucee for the main component
and process integration, including Jsoup preservation and HTML string input.
The Lucee test uses the usual Windows Node path or `/usr/bin/node`; adjust it
if the host uses a different installation location. It uses installed Chrome on
Windows when available. Set `HTML_TO_PNG_BROWSER` to a browser executable to run
the Node tests with an existing browser instead of the bundled Chromium.

References: [Playwright screenshots](https://playwright.dev/docs/screenshots),
[Lucee cfexecute](https://docs.lucee.org/reference/tags/execute.html).
