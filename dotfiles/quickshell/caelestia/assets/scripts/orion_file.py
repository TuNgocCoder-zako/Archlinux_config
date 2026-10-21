#!/usr/bin/env python3
import sys
import os
import argparse
import urllib.parse

def extract_file_content(filepath, max_chars=16000):
    if not filepath:
        return "Error: No file path provided."

    # Handle file:// URI scheme and urlencoding
    if filepath.startswith("file://"):
        filepath = urllib.parse.unquote(filepath[7:])
    else:
        filepath = urllib.parse.unquote(filepath)

    filepath = os.path.expanduser(filepath.strip("'\""))

    if not os.path.exists(filepath):
        return f"Error: File not found: {filepath}"

    if os.path.isdir(filepath):
        entries = sorted(os.listdir(filepath))[:50]
        return f"Directory listing for {filepath} ({len(entries)} items):\n" + "\n".join(entries)

    filename = os.path.basename(filepath)
    ext = os.path.splitext(filepath)[1].lower()

    if ext == ".pdf":
        try:
            import pypdf
            reader = pypdf.PdfReader(filepath)
            total_pages = len(reader.pages)
            pages = []
            total_chars = 0
            for idx, page in enumerate(reader.pages):
                text = page.extract_text() or ""
                if text.strip():
                    pages.append(f"--- [Trang {idx+1}/{total_pages}] ---\n{text.strip()}")
                    total_chars += len(text)
                if total_chars >= max_chars:
                    pages.append(f"\n... [Đã trích xuất {idx+1}/{total_pages} trang đầu tiên do giới hạn độ dài văn bản]")
                    break
            if not pages:
                return f"Tập tin PDF '{filename}' không chứa văn bản có thể trích xuất (có thể là file scan hoặc hình ảnh)."
            return f"Nội dung tài liệu PDF '{filename}' ({total_pages} trang):\n\n" + "\n\n".join(pages)
        except Exception as e:
            return f"Lỗi đọc tập tin PDF '{filename}': {e}"

    # Text, code, markdown, json, etc.
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            content = f.read(max_chars)
            more = f.read(1)
        res = f"Nội dung tập tin '{filename}':\n\n{content}"
        if more:
            res += f"\n\n... [Đã cắt bớt do tập tin quá dài, chỉ lấy {max_chars} ký tự đầu tiên]"
        return res
    except Exception as e:
        return f"Lỗi đọc tập tin '{filename}': {e}"

def main():
    parser = argparse.ArgumentParser(description="Orion File Reader Helper")
    parser.add_argument("--path", required=True, help="Path to file or directory")
    parser.add_argument("--max-chars", type=int, default=16000, help="Max characters to return")
    args = parser.parse_args()

    content = extract_file_content(args.path, max_chars=args.max_chars)
    print(content)

if __name__ == "__main__":
    main()
