#!/usr/bin/env python3

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser()
  parser.add_argument("--tag", required=True)
  parser.add_argument("--release-url", required=True)
  parser.add_argument("--cdn-base-url", required=True)
  parser.add_argument("--body-file", required=True)
  parser.add_argument("--output", required=True)
  parser.add_argument("--asset-path", action="append", required=True)
  return parser.parse_args()


def build_manifest(args: argparse.Namespace) -> dict:
  if not args.cdn_base_url.strip():
    raise ValueError("cdn-base-url must not be empty")
  body = Path(args.body_file).read_text(encoding="utf-8")
  cdn_base_url = args.cdn_base_url.rstrip("/")
  tag = args.tag.strip()
  assets = []
  for asset_path in args.asset_path:
    asset_name = Path(asset_path).name
    if not asset_name:
      raise ValueError("asset-path must point to a file")
    assets.append({
      "name": asset_name,
      "browser_download_url": f"{cdn_base_url}/releases/{tag}/{asset_name}",
    })
  return {
    "tag_name": tag,
    "html_url": args.release_url.strip(),
    "body": body,
    "assets": assets,
  }


def main() -> None:
  args = parse_args()
  manifest = build_manifest(args)
  output_path = Path(args.output)
  output_path.parent.mkdir(parents=True, exist_ok=True)
  output_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
  )


if __name__ == "__main__":
  main()
