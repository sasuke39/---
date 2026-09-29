// 可续跑的逐帧渲染：帧存为 out/v3frames/fNNNN.jpg，已存在的跳过；全部完成后编码为 MP4 并混入音轨。
// 用法：node v3/render_frames.mjs
import { createRequire } from 'module';
import { execSync, spawnSync } from 'child_process';
import fs from 'fs'; import path from 'path';
const require=createRequire(import.meta.url);
let pw;try{pw=require('playwright')}catch{pw=require('/opt/node22/lib/node_modules/playwright')}
const HERE=path.dirname(new URL(import.meta.url).pathname), ROOT=path.resolve(HERE,'..');
const FF=process.env.FFMPEG||execSync('python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"').toString().trim();
const FPS=30,TOTAL=600,DIR=path.join(ROOT,'out/v3frames');fs.mkdirSync(DIR,{recursive:true});
const name=f=>path.join(DIR,`f${String(f).padStart(4,'0')}.jpg`);
const todo=[];for(let f=0;f<TOTAL;f++)if(!fs.existsSync(name(f)))todo.push(f);
console.log(`${TOTAL-todo.length} frames exist, ${todo.length} to render`);
if(todo.length){
  const browser=await pw.chromium.launch({args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--allow-file-access-from-files']});
  const page=await browser.newPage({viewport:{width:540,height:960}});
  page.on('pageerror',e=>{console.error('PAGE ERROR:',e.message);process.exit(1)});
  await page.goto('file://'+path.join(HERE,'film.html')+'?render&scale=1');
  await page.waitForFunction(()=>window.READY===true,null,{timeout:300000});
  const t0=Date.now();
  for(const [k,f] of todo.entries()){const b=await page.evaluate(t=>window.frameJPEG(t,.95),f/FPS);
    const tmp=name(f)+'.tmp';fs.writeFileSync(tmp,Buffer.from(b,'base64'));fs.renameSync(tmp,name(f));
    if(k%15===0)console.log(`frame ${f} (${k+1}/${todo.length})  ${((Date.now()-t0)/1000).toFixed(0)}s`)}
  await browser.close();
}
const out=path.join(ROOT,'out/recursion_v3_9x16.mp4'),audio=path.join(ROOT,'out/recursion_v3_audio.wav');
const r=spawnSync(FF,['-y','-loglevel','error','-framerate',String(FPS),'-i',path.join(DIR,'f%04d.jpg'),'-i',audio,
  '-c:v','libx264','-preset','slow','-crf','20','-maxrate','14M','-bufsize','28M','-pix_fmt','yuv420p','-profile:v','high',
  '-c:a','aac','-b:a','192k','-shortest','-movflags','+faststart',out],{stdio:'inherit'});
console.log(r.status===0?'done → '+out:'ffmpeg exit '+r.status);
