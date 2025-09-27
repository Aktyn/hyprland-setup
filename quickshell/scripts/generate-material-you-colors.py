import argparse
import json
import typing as t
from PIL import Image
from materialyoucolor.dynamiccolor.material_dynamic_colors import DynamicColor
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.scheme.dynamic_scheme import DynamicScheme
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.hct import Hct

dark_mode = True

type RGB = tuple[int, int, int]


def rgb_to_hex(rgb: RGB) -> str:
    return "#{:02x}{:02x}{:02x}".format(*rgb[:3])


def get_color(color_name: str) -> DynamicColor | None:
    color = getattr(MaterialDynamicColors, color_name, None)
    if isinstance(color, DynamicColor):
        return color
    else:
        return None


def format_color_name(color_name: str) -> str:
    if color_name.startswith("on"):
        return f"color{color_name[0].upper()}{color_name[1:]}"
    return color_name


class ColorsCache:
    __slots__ = ("colors", "wallpaper", "original_color", "contrast_level", "is_dark")

    def __init__(
        self,
        colors: DynamicScheme | dict[str, str],
        wallpaper: str | None,
        original_color: int | None,
        contrast_level: int,
        is_dark: bool,
        colors_dark: DynamicScheme | dict[str, str] | None = None,
        colors_light: DynamicScheme | dict[str, str] | None = None,
    ) -> None:
        self.colors: dict[str, str] = {}
        self.wallpaper = wallpaper
        self.original_color = original_color
        self.contrast_level = contrast_level
        self.is_dark = is_dark

        if isinstance(colors, DynamicScheme):
            for color_name in vars(MaterialDynamicColors).keys():
                color = get_color(color_name)
                if color is None:
                    continue
                self.colors[format_color_name(color_name)] = rgb_to_hex(
                    color.get_hct(colors).to_rgba()
                )
        else:
            self.colors = colors

        _schemes = ((colors_dark, "Dark"), (colors_light, "Light"))
        for scheme, suffix in _schemes:
            if scheme is None:
                continue
            if isinstance(scheme, dict):
                for key, value in scheme.items():
                    self.colors[f"{key}{suffix}"] = value
                continue
            for color_name in vars(MaterialDynamicColors).keys():
                color = get_color(color_name)
                if color is None:
                    continue
                self.colors[f"{format_color_name(color_name)}{suffix}"] = rgb_to_hex(
                    color.get_hct(colors).to_rgba()
                )


def colors_dict(cache: ColorsCache) -> dict[str, t.Any]:
    dict = {
        "wallpaper": cache.wallpaper,
        "colors": cache.colors,
        "original_color": cache.original_color,
        "contrast_level": cache.contrast_level,
        "is_dark": cache.is_dark,
    }
    return dict


def downsample_image_rgb(path: str, quality: int) -> list[tuple[int, int, int]]:
    """
    Downsamples an image and returns a list of RGB tuples from the sampled pixels.
    """
    result: list[tuple[int, int, int]] = []

    img = Image.open(path).convert("RGB")
    width, height = img.size
    pix = img.load()

    for y in range(0, height, quality):
        for x in range(0, width, quality):
            r, g, b = pix[x, y]
            result.append((r, g, b))

    return result


def process_image(image_path: str, quality: int = 2, num_colors: int = 128) -> int:
    from materialyoucolor.quantize import QuantizeCelebi  # type: ignore
    from materialyoucolor.score.score import Score  # type: ignore

    pixel_array = downsample_image_rgb(image_path, quality)

    result = QuantizeCelebi(pixel_array, num_colors)

    color = int(Score.score(result)[0])

    return color


@t.overload
def generate_colors_sync(
    image_path: str,
    use_color: t.Literal[None] = None,
    is_dark: bool = True,
    contrast_level: int = 0,
    output_path: str = None,
) -> None: ...


@t.overload
def generate_colors_sync(
    image_path: t.Literal[None],
    use_color: int,
    is_dark: bool = True,
    contrast_level: int = 0,
    output_path: str = None,
) -> None: ...


def generate_colors_sync(
    image_path: str | None = None,
    use_color: int | None = None,
    is_dark: bool = True,
    contrast_level: int = 0,
    output_path: str = None,
) -> None:
    if output_path is None:
        raise Exception("output_path is required")

    if use_color is None and image_path is not None:
        color = process_image(image_path, 4, 1024)
    elif use_color is not None and image_path is None:
        color = use_color
    else:
        raise TypeError("Either image_path or use_color should be not None.")

    dark_scheme = SchemeTonalSpot(Hct.from_int(color), True, contrast_level)
    light_scheme = SchemeTonalSpot(Hct.from_int(color), False, contrast_level)
    scheme = dark_scheme if is_dark else light_scheme

    with open(output_path, "w") as f:
        object = ColorsCache(
            colors=scheme,
            wallpaper=image_path,
            original_color=use_color,
            contrast_level=contrast_level,
            is_dark=is_dark,
            colors_dark=dark_scheme,
            colors_light=light_scheme,
        )
        json.dump(colors_dict(object), f, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description="Generate Material You colors from an image."
    )
    parser.add_argument("image_path", help="Path to the input image.")
    parser.add_argument("output_path", help="Path to the output JSON file for colors.")
    parser.add_argument(
        "--light",
        action="store_true",
        help="Generate colors for light mode (default is dark).",
    )
    parser.add_argument(
        "--contrast-level",
        type=float,
        default=0.0,
        help="Contrast level (0.0 to 1.0).",
    )
    args = parser.parse_args()

    generate_colors_sync(
        image_path=args.image_path,
        use_color=None,
        is_dark=not args.light,
        contrast_level=args.contrast_level,
        output_path=args.output_path,
    )
    print(f"Colors generated and saved to {args.output_path}")


if __name__ == "__main__":
    main()
