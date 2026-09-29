// 写实版离线渲染：node v2/render.mjs [--stills 0,1.5,...] [--scale 0.5] [--out file.mp4]
import { createRequire } from 'module';
import { spawn, execSync } from 'child_process';
import fs from 'fs'; import path from 'path';
const require=createRequire(import.meta.url);
let pw;try{pw=require('playwright')}catch{pw=require('/opt/node22/lib/node_modules/playwright')}
const HERE=path.dirname(new URL(import.meta.url).pathname), ROOT=path.resolve(HERE,'..');
const FF=process.env.FFMPEG||(()=>{try{return execSync('python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"').toString().trim()}catch{return 'ffmpeg'}})();
const arg=(k,d)=>{const i=process.argv.indexOf(k);return i>0?process.argv[i+1]:d};
const scale=arg('--scale','1'), stills=arg('--stills',null), from=+arg('--from','0'), to=+arg('--to','20');
const FPS=30;
const browser=await pw.chromium.launch({args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--allow-file-access-from-files']});
const page=await browser.newPage({viewport:{width:540,height:960}});
page.on('pageerror',e=>console.error('PAGE ERROR:',e.message));
page.on('console',m=>{if(m.type()==='error')console.error('CONSOLE:',m.text())});
await page.goto('file://'+path.join(HERE,'film.html')+`?render&scale=${scale}`);
await page.waitForFunction(()=>window.READY===true,null,{timeout:300000});
if(stills){
  const dir=path.join(ROOT,'out/v2stills');fs.mkdirSync(dir,{recursive:true});
  for(const t of stills.split(',').map(Number)){const s=Date.now();const b=await page.evaluate(t=>window.framePNG(t),t);
    const f=path.join(dir,`t${t.toFixed(2)}.png`);fs.writeFileSync(f,Buffer.from(b,'base64'));console.log('wrote',f,(Date.now()-s)+'ms')}
  await browser.close();process.exit(0)}
const outf=arg('--out',path.join(ROOT,'out/recursion_v2_9x16.mp4')), audio=arg('--audio',path.join(ROOT,'out/recursion_v2_audio.wav'));
const fa=['-y','-loglevel','error','-f','image2pipe','-framerate',String(FPS),'-c:v','mjpeg','-i','-'];
const hasA=fs.existsSync(audio)&&from===0&&to===20;if(hasA)fa.push('-i',audio);
fa.push('-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','slow','-crf','16','-pix_fmt','yuv420p','-profile:v','high','-r',String(FPS));
if(hasA)fa.push('-c:a','aac','-b:a','192k','-shortest');fa.push('-movflags','+faststart',outf);
const ff=spawn(FF,fa,{stdio:['pipe','inherit','inherit']});const done=new Promise(r=>ff.on('close',r));
const t0=Date.now(),f0=Math.round(from*FPS),f1=Math.round(to*FPS);
for(let f=f0;f<f1;f++){const b=await page.evaluate(t=>window.frameJPEG(t,.95),f/FPS);
  if(!ff.stdin.write(Buffer.from(b,'base64')))await new Promise(r=>ff.stdin.once('drain',r));
  if(f%15===0)console.log(`frame ${f}/${f1}  ${((Date.now()-t0)/1000).toFixed(0)}s`)}
ff.stdin.end();const code=await done;await browser.close();console.log(code===0?'done → '+outf:'ffmpeg exit '+code);
