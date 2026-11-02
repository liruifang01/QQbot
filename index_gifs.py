"""Create a one-time visual meaning index for images/gifs using DeepSeek vision."""
import base64
import json
import os
from io import BytesIO
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
GIF_DIR = ROOT / "images" / "gifs"
OUT = GIF_DIR / "meanings.json"
load_dotenv(ROOT / ".env")


def make_sheet(files: list[Path]) -> str:
    cell_w, cell_h, image_h = 320, 270, 232
    sheet = Image.new("RGB", (cell_w * 4, cell_h * 4), "white")
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(files):
        frame = Image.open(path)
        try:
            frame.seek(0)
            frame = frame.convert("RGB")
            frame.thumbnail((cell_w - 12, image_h - 8))
            x, y = (i % 4) * cell_w, (i // 4) * cell_h
            sheet.paste(frame, (x + (cell_w-frame.width)//2, y))
            draw.text((x + 6, y + image_h + 4), path.name, fill="black")
        finally:
            Image.open(path).close()
    buf = BytesIO()
    sheet.save(buf, format="JPEG", quality=72, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def main() -> None:
    key = os.getenv("DEEPSEEK_API_KEY", "").strip()
    if not key:
        raise SystemExit(".env 中没有配置 DEEPSEEK_API_KEY")
    files = sorted(p for p in GIF_DIR.iterdir() if p.suffix.lower() in {".gif", ".png", ".jpg", ".jpeg"})
    meanings: dict[str, str] = {}
    client = OpenAI(api_key=key, base_url=os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com"), timeout=180)
    for start in range(0, len(files), 16):
        batch = files[start:start+16]
        prompt = (
            "识别这张联系表中每个编号文件的表情包画面和适合表达的聊天情绪。"
            "文件名写在对应格子下方。返回严格JSON对象，键为完整文件名，值为简短中文含义与适用场景；"
            "不要猜测看不清的细节，依据画面描述。"
        )
        response = client.chat.completions.create(
            model=os.getenv("DEEPSEEK_MODEL", "deepseek-flash"),
            messages=[{"role": "user", "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": make_sheet(batch)}},
            ]}],
            response_format={"type": "json_object"},
        )
        data = json.loads(response.choices[0].message.content or "{}")
        for path in batch:
            meaning = data.get(path.name)
            if isinstance(meaning, str) and meaning.strip():
                meanings[path.name] = meaning.strip()
        print(f"已识别 {min(start+16, len(files))}/{len(files)} 张")
    OUT.write_text(json.dumps(meanings, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"索引已保存：{OUT}（{len(meanings)}/{len(files)} 张）")


if __name__ == "__main__":
    main()
