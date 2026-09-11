#!/usr/bin/env python3
import sys
import argparse
import subprocess
import urllib.parse
import re
import html

def search_web(query, page_num=1):
    try:
        url = 'https://html.duckduckgo.com/html/?q=' + urllib.parse.quote(query)
        res = subprocess.run([
            'curl', '-s', '-L', '--max-time', '12',
            '-A', 'Lynx/2.8.9rel.1 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/3.0.7',
            url
        ], capture_output=True, text=True, errors='ignore')

        if res.returncode != 0 or not res.stdout:
            return "Error: Could not retrieve search results."

        results = []
        pattern = re.compile(
            r'<a class=\"result__snippet\" href=\"([^\"]+)\">(.*?)</a>',
            re.DOTALL
        )
        for m in pattern.finditer(res.stdout):
            raw_url, raw_snippet = m.groups()
            snippet = html.unescape(re.sub(r'<.*?>', '', raw_snippet)).strip()
            
            m_url = re.search(r'uddg=([^&]+)', raw_url)
            clean_url = urllib.parse.unquote(m_url.group(1)) if m_url else raw_url
            if not clean_url.startswith('http'):
                clean_url = 'https:' + clean_url if clean_url.startswith('//') else clean_url
                
            results.append((clean_url, snippet))

        if not results:
            return "No useful results found for this query."

        # Pagination (5 results per page)
        start_idx = (page_num - 1) * 5
        end_idx = start_idx + 5
        page_results = results[start_idx:end_idx]

        formatted = []
        for i, (u, snip) in enumerate(page_results, start=start_idx + 1):
            formatted.append(f"[{i}] URL: {u}\nSummary: {snip}")

        return "\n\n".join(formatted)

    except Exception as e:
        return f"Error during web search: {str(e)}"

def read_webpage(url):
    try:
        res = subprocess.run([
            'curl', '-s', '-L', '--max-time', '12',
            '-A', 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0',
            url
        ], capture_output=True, text=True, errors='ignore')

        if res.returncode != 0 or not res.stdout:
            return "Error: Could not fetch webpage content."

        raw = res.stdout
        clean = re.sub(r'<script.*?</script>', '', raw, flags=re.DOTALL | re.IGNORECASE)
        clean = re.sub(r'<style.*?</style>', '', clean, flags=re.DOTALL | re.IGNORECASE)
        clean = re.sub(r'<nav.*?</nav>', '', clean, flags=re.DOTALL | re.IGNORECASE)
        clean = re.sub(r'<header.*?</header>', '', clean, flags=re.DOTALL | re.IGNORECASE)
        clean = re.sub(r'<footer.*?</footer>', '', clean, flags=re.DOTALL | re.IGNORECASE)
        clean = re.sub(r'<.*?>', ' ', clean)
        clean = html.unescape(clean)
        clean = re.sub(r'\s+', ' ', clean).strip()

        # Truncate text to avoid blowing up context window
        if len(clean) > 4000:
            clean = clean[:4000] + "\n\n[Content truncated for context window limits]"

        return clean if clean else "Could not extract readable text from this page."

    except Exception as e:
        return f"Error reading webpage: {str(e)}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["search", "read"], required=True)
    parser.add_argument("--query", type=str, help="Search query")
    parser.add_argument("--page", type=int, default=1, help="Page number (1-indexed)")
    parser.add_argument("--url", type=str, help="URL to read")
    
    args = parser.parse_args()
    
    if args.mode == "search":
        if not args.query:
            print("Error: --query is required for search mode")
            sys.exit(1)
        print(search_web(args.query, args.page))
    elif args.mode == "read":
        if not args.url:
            print("Error: --url is required for read mode")
            sys.exit(1)
        print(read_webpage(args.url))
