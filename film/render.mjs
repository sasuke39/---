// 离线渲染：逐帧截取 canvas → ffmpeg 编码为 1080x1920 H.264 MP4
// 用法：
//   node film/render.mjs                    渲染完整视频到 out/recursion_9x16.mp4
//   node film/render.mjs --stills 0,2,4.5   只导出指定时间点的静帧（PNG，out/stills/）
import { createRequire } from 'module';
import { spawn, execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const require = createRequire(import.meta.url);
let pw;
try { pw = require('playwright'); } catch { pw = require('/opt/node22/lib/node_modules/playwright'); }

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const FPS = 30, DUR = 20;
const FF = process.env.FFMPEG || (() => {
  try { return execSync('python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"').toString().trim(); }
  catch { return 'ffmpeg'; }
})();

const args = process.argv.slice(2);
const stillsArg = args.includes('--stills') ? args[args.indexOf('--stills') + 1] : null;

const browser = await pw.chromium.launch({ args: ['--disable-web-security'] });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
page.on('pageerror', e => console.error('PAGE ERROR:', e.message));
await page.goto('file://' + path.join(ROOT, 'film/recursion.html') + '?render');
await page.waitForFunction(() => window.READY === true, null, { timeout: 60000 });

if (stillsArg) {
  const dir = path.join(ROOT, 'out/stills');
  fs.mkdirSync(dir, { recursive: true });
  for (const t of stillsArg.split(',').map(Number)) {
    const b64 = await page.evaluate(t => window.framePNG(t), t);
    const f = path.join(dir, `t${t.toFixed(2)}.png`);
    fs.writeFileSync(f, Buffer.from(b64, 'base64'));
    console.log('wrote', f);
  }
  await browser.close();
  process.exit(0);
}

const audio = path.join(ROOT, 'out/recursion_audio.wav');
const out = path.join(ROOT, 'out/recursion_9x16.mp4');
const ffArgs = ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-'];
if (fs.existsSync(audio)) ffArgs.push('-i', audio);
ffArgs.push('-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p', '-profile:v', 'high', '-r', String(FPS));
if (fs.existsSync(audio)) ffArgs.push('-c:a', 'aac', '-b:a', '192k', '-shortest');
ffArgs.push('-movflags', '+faststart', out);
const ff = spawn(FF, ffArgs, { stdio: ['pipe', 'inherit', 'inherit'] });
const done = new Promise(r => ff.on('close', r));

const total = FPS * DUR, t0 = Date.now();
for (let f = 0; f < total; f++) {
  const b64 = await page.evaluate(t => window.frameJPEG(t, 0.95), f / FPS);
  if (!ff.stdin.write(Buffer.from(b64, 'base64'))) await new Promise(r => ff.stdin.once('drain', r));
  if (f % 30 === 0) console.log(`frame ${f}/${total}  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
}
ff.stdin.end();
const code = await done;
await browser.close();
console.log(code === 0 ? `done → ${out}` : `ffmpeg exited ${code}`);
