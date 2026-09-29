# 递归 RECURSION

一部 20 秒的竖屏（9:16）科幻短片，讲的是人类在极度发达的 AI 之下的未来。

镜头钻进一只人类的眼睛，依次经过会呼吸的城市、装着记忆的雨、可以更换的身体、显示情绪的天空、不再是终点的死亡、变成计算机的月球、被包裹的太阳和星系尺度的大脑。最后星系睁开眼睛，正是开头那只眼睛。

> 是我们创造了它，还是它梦见了我们？

## 成片

**v2 写实版（推荐）**：`out/recursion_v2_9x16.mp4`。用 GLSL 光线步进和体积渲染做出有真实光影的 CG 画面，共 6 个镜头，依次是：人眼微距、雾中生长的巨构城市、地球夜面和被电路覆盖的月球、戴森球、体积星系、回到人眼。源码在 `v2/`，分镜见 `docs/storyboard_v2.md`。

**v1 风格化版**：
`out/recursion_9x16.mp4`：1080×1920，30fps，H.264 + AAC，首尾可以无缝循环。

## 文件

| 路径 | 说明 |
|---|---|
| `docs/storyboard.md` | 分镜脚本、节奏表、TikTok 安全区说明，以及做写实版本用的 AI 视频提示词 |
| `film/recursion.html` | 全部画面（程序化生成）。直接用浏览器打开就能实时预览，点击画面播放 |
| `film/audio.py` | 配乐与音效合成，纯 Python，不依赖任何外部库 |
| `film/render.mjs` | 离线逐帧渲染，再用 ffmpeg 编码成 MP4 |

## 重新渲染

```bash
pip install imageio-ffmpeg        # 提供带 libx264 的 ffmpeg（或设置 FFMPEG=/path/to/ffmpeg）
npm i -D playwright               # 使用 Chromium 渲染
python3 film/audio.py             # 生成 out/recursion_audio.wav
node film/render.mjs              # 生成 out/recursion_9x16.mp4
node film/render.mjs --stills 0,4.9,13.6   # 只导出指定时间点的静帧，用来检查画面
```
