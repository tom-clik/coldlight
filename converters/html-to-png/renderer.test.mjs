import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { render } from './renderer.mjs';

test('batch element capture, resources, scale and validation', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'coldlight images '));
  try {
    await fs.writeFile(path.join(root, 'style.css'), '#one { width:123px; height:45px; background:rgb(255,0,0) }');
    await fs.writeFile(path.join(root, 'picture.svg'), '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="10"><rect width="20" height="10" fill="blue"/></svg>');
    const htmlFile = path.join(root, 'document.html');
    await fs.writeFile(htmlFile, `<!doctype html><html><head><base href="${pathToFileURL(root + path.sep).href}">
      <link rel="stylesheet" href="style.css"><style>body {margin:0} #two {width:50px;height:30px} @media print {#one {width:100px}}</style></head>
      <body><div id="one">♠</div><div id="two"><img src="picture.svg"></div><div id="colon:id" style="width:11px;height:12px"></div>
      <div id="hidden" hidden></div><div id="duplicate"></div><div id="duplicate"></div></body></html>`);
    const job = { htmlFile, outputFolder: root, images: [
      {id:'one',filename:'images/one.png'}, {id:'two',filename:'images/two.png'},
      {id:'colon:id',filename:'images/punctuation.png'}], options:{scale:2,
        ...(process.env.HTML_TO_PNG_BROWSER ? {executablePath:process.env.HTML_TO_PNG_BROWSER} : {})} };
    const images = await render(job);
    assert.deepEqual(images.map(({width,height}) => [width,height]), [[246,90],[100,60],[22,24]]);
    for (const image of images) {
      const bytes = await fs.readFile(image.path);
      assert.equal(bytes.subarray(1,4).toString(), 'PNG');
    }
    const print = await render({...job, images:[job.images[0]], options:{...job.options,scale:1,media:'print',transparent:true}});
    assert.equal(print[0].width, 100);
    const original = await fs.readFile(images[0].path);
    for (const id of ['missing', 'duplicate', 'hidden']) {
      await assert.rejects(render({...job, images:[job.images[0],{id,filename:'images/fail.png'}]}), /ID must match|Element is hidden/);
      assert.deepEqual(await fs.readFile(images[0].path), original, 'failed batches leave existing captures alone');
    }
    await assert.rejects(render({...job, images:[{id:'one',filename:'../escape.png'}]}), /Invalid relative/);
    await assert.rejects(render({...job, images:[job.images[0],job.images[0]]}), /Duplicate output/);
    await assert.rejects(render({...job, options:{scale:0}}), /scale must/);
    await assert.rejects(render({...job, options:{unknown:1}}), /Unknown renderer/);
    await fs.writeFile(htmlFile, '<link rel="stylesheet" href="missing.css"><div id="one">Test</div>');
    await assert.rejects(render({...job, images:[job.images[0]]}), /Resources failed/);
  } finally {
    await fs.rm(root, {recursive:true,force:true});
  }
});
