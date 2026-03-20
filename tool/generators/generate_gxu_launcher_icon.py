from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image
from PIL import ImageOps

DEFAULT_ICON_SIZE = 1024
DEFAULT_OUTPUT = Path("assets") / "gxu.png"
PNG_COMPRESS_LEVEL = 9


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--size", type=int, default=DEFAULT_ICON_SIZE)
    return parser.parse_args()


def resolve_repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def resolve_path(base: Path, path: Path) -> Path:
    if path.is_absolute():
        return path
    return base / path


def prepare_image(source_path: Path, size: int) -> Image.Image:
    with Image.open(source_path) as source_image:
        fitted_image = ImageOps.fit(
            source_image,
            (size, size),
            method=Image.Resampling.LANCZOS,
        )
        if "A" not in fitted_image.getbands():
            return fitted_image.convert("RGB")

        alpha_channel = fitted_image.getchannel("A")
        if alpha_channel.getextrema() == (255, 255):
            return fitted_image.convert("RGB")
        return fitted_image.convert("RGBA")


def save_png(image: Image.Image, output_path: Path) -> None:
    temporary_path = output_path.with_suffix(".tmp.png")
    image.save(
        temporary_path,
        format="PNG",
        optimize=True,
        compress_level=PNG_COMPRESS_LEVEL,
    )
    temporary_path.replace(output_path)


def build_icon(source_path: Path, output_path: Path, size: int) -> None:
    prepared_image = prepare_image(source_path, size)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    save_png(prepared_image, output_path)


def main() -> None:
    arguments = parse_args()
    repo_root = resolve_repo_root()
    output_path = resolve_path(repo_root, arguments.output)
    source_argument = arguments.source or arguments.output
    source_path = resolve_path(repo_root, source_argument)
    build_icon(source_path, output_path, arguments.size)
    print(f"generated: {output_path} ({output_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
