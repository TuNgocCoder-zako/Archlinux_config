#!/usr/bin/env python3
import sys
import os
import argparse
import subprocess
import json
import urllib.request
import base64

def get_hyprland_info():
    info_lines = []
    ws_name = "1"
    try:
        act = subprocess.run(['hyprctl', 'activewindow', '-j'], capture_output=True, text=True, timeout=3)
        if act.returncode == 0 and act.stdout.strip():
            data = json.loads(act.stdout)
            app_class = data.get('class', '')
            title = data.get('title', '')
            ws_name = data.get('workspace', {}).get('name', '1')
            if app_class or title:
                info_lines.append(f"Active Application: {app_class} (Window Title: \"{title}\") on Workspace {ws_name}")
    except Exception:
        pass

    try:
        cls = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=3)
        if cls.returncode == 0 and cls.stdout.strip():
            clients = json.loads(cls.stdout)
            windows = [
                f"{c.get('class', 'App')}: \"{c.get('title', '')}\""
                for c in clients
                if str(c.get('workspace', {}).get('name', '')) == str(ws_name) and (c.get('class') or c.get('title'))
            ]
            if windows:
                info_lines.append(f"Visible Windows on Workspace {ws_name}: " + "; ".join(windows))
    except Exception:
        pass

    return "\n".join(info_lines)

def capture_screenshot(region=False, png_path="/tmp/orion_screenshot.png", jpg_path="/tmp/orion_screenshot.jpg"):
    try:
        if region:
            # Interactive region selection with slurp via orion_snip.sh
            snip_sh = os.path.join(os.path.dirname(__file__), "orion_snip.sh")
            res = subprocess.run(['bash', snip_sh], capture_output=True, text=True, timeout=60)
            out_lines = [l.strip() for l in res.stdout.splitlines() if l.strip()]
            if res.returncode != 0 or not out_lines or "CANCELLED" in out_lines:
                return False, "Hủy chọn vùng màn hình (Cancelled by user)."
            target_path = out_lines[-1]
            if os.path.exists(target_path):
                return True, target_path
            return False, "Không tìm thấy ảnh chụp vùng màn hình."
        else:
            # Try focused monitor first
            mon_proc = subprocess.run(
                ['sh', '-c', 'hyprctl monitors -j | jq -r \'.[] | select(.focused) | "\\(.x),\\(.y) \\(.width)x\\(.height)"\''],
                capture_output=True, text=True, timeout=3
            )
            geom = mon_proc.stdout.strip() if mon_proc.returncode == 0 else ""
            if geom:
                res = subprocess.run(['grim', '-g', geom, png_path], capture_output=True, timeout=5)
            else:
                res = subprocess.run(['grim', png_path], capture_output=True, timeout=5)

            if res.returncode != 0 or not os.path.exists(png_path):
                # Fallback to plain grim
                res = subprocess.run(['grim', png_path], capture_output=True, timeout=5)
                if res.returncode != 0:
                    return False, f"Grim failed to capture screen: {res.stderr.decode('utf-8', errors='ignore')}"

        if not os.path.exists(png_path):
            return False, "Tập tin chụp màn hình không tồn tại."

        # Optimize with ImageMagick - 1600x1600 preserves readable text and code
        magick_res = subprocess.run(
            ['magick', png_path, '-resize', '1600x1600>', '-quality', '92', jpg_path],
            capture_output=True, timeout=5
        )
        target_path = jpg_path if (magick_res.returncode == 0 and os.path.exists(jpg_path)) else png_path
        return True, target_path
    except Exception as e:
        return False, str(e)

def find_ollama_vision_model(ollama_url="http://localhost:11434"):
    try:
        req = urllib.request.Request(f"{ollama_url}/api/tags", headers={'Accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=3) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            models = data.get("models", [])

            # First priority: qwen3-vl or models with explicit -vl
            for m in models:
                name = m.get("name", "").lower()
                if "qwen3-vl" in name or "qwen2.5-vl" in name:
                    return m.get("name")

            # Second priority: any model with "vision" in capabilities or "clip" in families
            for m in models:
                caps = m.get("capabilities", [])
                families = m.get("details", {}).get("families", [])
                if "vision" in caps or "clip" in families or "mllama" in families:
                    return m.get("name")

            # Third priority: names containing vision indicators
            for m in models:
                name = m.get("name", "").lower()
                if any(v in name for v in ["vl", "vision", "moondream", "llava", "minicpm-v", "bakllava"]):
                    return m.get("name")

    except Exception:
        pass
    return None

def analyze_with_vision(image_path, query=None, ollama_url="http://localhost:11434", is_region=False):
    vision_model = find_ollama_vision_model(ollama_url)
    if not vision_model:
        return (
            "[Notice: Screenshot captured, but no vision model is installed in Ollama. "
            "To enable visual screen analysis, please run 'ollama pull qwen3-vl:8b' in your terminal.]"
        )

    try:
        with open(image_path, "rb") as f:
            b64_img = base64.b64encode(f.read()).decode('utf-8')

        if query and query.strip():
            context_type = "vùng màn hình được khoanh chọn" if is_region else "màn hình máy tính"
            prompt = (
                f"Đây là hình ảnh chụp {context_type} của người dùng.\n"
                f"Hãy phân tích thật kỹ hình ảnh: đọc chính xác các đoạn văn bản, câu hỏi, bài tập, công thức toán học, biểu thức logic hoặc đoạn mã nguồn hiển thị trong ảnh.\n\n"
                f"Yêu cầu của người dùng:\n{query.strip()}\n\n"
                f"Hãy trả lời chi tiết và giải quyết chính xác yêu cầu trên."
            )
        else:
            if is_region:
                prompt = "Phân tích chi tiết vùng màn hình này: đọc toàn bộ văn bản, bài tập, công thức toán học, biểu thức logic hoặc mã nguồn hiển thị trong ảnh."
            else:
                prompt = "Phân tích chi tiết màn hình này: đọc các cửa sổ đang mở, nội dung văn bản, mã nguồn, công thức và thông tin quan trọng hiển thị trên màn hình."

        payload = json.dumps({
            "model": vision_model,
            "prompt": prompt,
            "images": [b64_img],
            "stream": False,
            "options": {
                "num_ctx": 2048,
                "num_gpu": 24,
                "num_predict": 1024,
                "temperature": 0.2
            }
        }).encode('utf-8')

        req = urllib.request.Request(
            f"{ollama_url}/api/generate",
            data=payload,
            headers={'Content-Type': 'application/json'}
        )

        with urllib.request.urlopen(req, timeout=180) as resp:
            res_data = json.loads(resp.read().decode('utf-8'))
            visual_desc = res_data.get("response", "").strip()

            if visual_desc:
                label = "Phân tích vùng màn hình" if is_region else "Phân tích màn hình"
                out = f"[{label} bằng {vision_model}]:\n{visual_desc}"
                if query and query.strip():
                    out += f"\n\n[User's Focus]:\n{query.strip()}"
                return out
            else:
                return "[Không nhận được phản hồi mô tả từ mô hình thị giác]"

    except Exception as e:
        return f"[Lỗi khi phân tích hình ảnh bằng {vision_model}: {str(e)}]"

def main():
    parser = argparse.ArgumentParser(description="Orion Screen Tool")
    parser.add_argument("--query", type=str, default="", help="Optional focus query for screen analysis")
    parser.add_argument("--image", type=str, default="", help="Optional explicit image path to analyze instead of capturing")
    parser.add_argument("--region", action="store_true", help="Capture an interactive region selected with slurp")
    args = parser.parse_args()

    # 1. Hyprland OS Window context (only for full screen, or briefly for region)
    os_info = get_hyprland_info() if not args.region else ""

    # 2. Get screenshot or use provided image
    if args.image and os.path.exists(args.image):
        img_path = args.image
    else:
        ok, img_path = capture_screenshot(region=args.region)
        if not ok:
            out = []
            if os_info:
                out.append(os_info)
            out.append(f"Screen capture notice: {img_path}")
            print("\n\n".join(out))
            return

    # 3. Vision model analysis
    visual_analysis = analyze_with_vision(img_path, query=args.query, is_region=args.region)

    # 4. Combine results
    output_parts = []
    if os_info:
        output_parts.append(f"[Active OS Desktop Context]:\n{os_info}")
    output_parts.append(visual_analysis)

    print("\n\n".join(output_parts))

if __name__ == "__main__":
    main()
