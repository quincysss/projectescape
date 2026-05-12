from __future__ import annotations

import csv
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ITEMS_TAB = ROOT / "setting" / "items.tab"
OUT_DIR = ROOT / "assets" / "ui" / "itemicon"
SIZE = 128


QUALITY_ACCENTS = {
    "C": (122, 128, 126, 230),
    "B": (76, 145, 210, 235),
    "A": (150, 92, 210, 240),
    "S": (218, 186, 82, 245),
    "SS": (245, 105, 170, 248),
}


ITEM_SPECS = {
    "scrap_metal": ("scrap metal sheets", "material"),
    "cloth_dirty": ("dirty torn cloth strip", "material"),
    "wire_coil": ("old wire coil", "electronic material"),
    "battery_old": ("old leaking battery", "power material"),
    "medicine_powder": ("sealed medicine powder pouch", "medical material"),
    "tool_parts": ("gears screws and tool parts", "tool material"),
    "outpost_fuse": ("outpost repair fuse", "outpost material"),
    "outpost_filter": ("purification filter cartridge", "outpost material"),
    "stability_candy": ("wrapped calming candy", "consumable"),
    "field_bandage": ("temporary field bandage roll", "consumable"),
    "signal_injector": ("signal injector syringe", "consumable"),
    "backpack_small_reinforced": ("small reinforced backpack", "equipment"),
    "scanner_broken": ("broken handheld scanner", "equipment"),
    "bp_backpack_small": ("small backpack blueprint", "blueprint"),
    "keepsake_photo": ("faded keepsake photo", "rare collectible"),
    "gold_data_chip": ("gold data chip", "rare electronic"),
    "ration_bar": ("compressed ration bar", "consumable"),
    "cracked_lens": ("cracked optical lens", "material"),
    "duct_tape_roll": ("half roll of duct tape", "material"),
    "rusted_bolts": ("rusted bolts and nuts", "material"),
    "cracked_compass": ("cracked old compass", "rare collectible"),
    "sterile_patch": ("sealed sterile hemostatic patch", "consumable"),
    "reinforced_strap": ("reinforced backpack strap", "material"),
    "pulse_battery": ("unstable pulse battery pack", "material"),
    "street_map_fragment": ("torn street map fragment", "rare map"),
    "signal_resonator_coil": ("signal resonator coil", "electronic material"),
    "sealed_medkit": ("sealed emergency medkit", "consumable"),
    "survey_drone_core": ("survey drone core module", "rare electronic"),
    "outpost_servo_pack": ("outpost servo component pack", "outpost material"),
    "thermal_scope_module": ("thermal scope module", "equipment"),
    "blackbox_memory_core": ("blackbox memory core", "rare electronic"),
    "prefall_access_key": ("pre-fall access key", "rare access item"),
    "anomaly_heart_shard": ("anomaly heart crystal shard", "rare anomaly"),
    "sanctuary_nav_chip": ("sanctuary navigation chip", "rare map chip"),
    "ss_silverwing_engine_core": ("silverwing miniature engine core", "SS showcase"),
    "ss_pink_star": ("pink star crystal", "SS showcase"),
    "ss_wanming_pocket_watch": ("Wanming pocket watch", "SS showcase"),
    "ss_old_world_gold_bar": ("old world gold bar", "SS showcase"),
    "ss_zero_master_control_board": ("zero facility master control board", "SS showcase"),
}


def jitter_points(points: list[tuple[float, float]], rng: random.Random, amount: float = 1.5):
    return [(x + rng.uniform(-amount, amount), y + rng.uniform(-amount, amount)) for x, y in points]


def rough_line(draw: ImageDraw.ImageDraw, points, fill, width, rng):
    for _ in range(2):
        draw.line(jitter_points(points, rng, 1.25), fill=fill, width=width, joint="curve")


def rough_polygon(draw: ImageDraw.ImageDraw, points, fill, outline, width, rng):
    p = jitter_points(points, rng, 1.2)
    draw.polygon(p, fill=fill)
    for _ in range(2):
        draw.line(p + [p[0]], fill=outline, width=width, joint="curve")


def rough_ellipse(draw: ImageDraw.ImageDraw, box, fill, outline, width, rng):
    draw.ellipse(box, fill=fill)
    for _ in range(3):
        dx = rng.uniform(-1.2, 1.2)
        dy = rng.uniform(-1.2, 1.2)
        draw.ellipse((box[0] + dx, box[1] + dy, box[2] + dx, box[3] + dy), outline=outline, width=width)


def add_texture(img: Image.Image, mask: Image.Image, rng: random.Random):
    tex = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(tex)
    for _ in range(85):
        x = rng.randint(18, 110)
        y = rng.randint(18, 110)
        alpha = rng.randint(18, 55)
        d.point((x, y), fill=(0, 0, 0, alpha))
        if rng.random() < 0.45:
            d.line((x, y, x + rng.randint(-5, 5), y + rng.randint(-5, 5)), fill=(0, 0, 0, alpha), width=1)
    tex.putalpha(Image.composite(tex.getchannel("A"), Image.new("L", (SIZE, SIZE), 0), mask))
    img.alpha_composite(tex)


def accent_mark(draw: ImageDraw.ImageDraw, quality: str, rng: random.Random):
    color = QUALITY_ACCENTS.get(quality, QUALITY_ACCENTS["C"])
    if quality == "SS":
        rough_ellipse(draw, (92, 91, 116, 115), (45, 38, 43, 210), color, 3, rng)
        draw.line((98, 103, 110, 103), fill=color, width=2)
        draw.line((104, 97, 104, 109), fill=color, width=2)
    else:
        pts = [(103, 94), (117, 105), (105, 118), (92, 106)]
        rough_polygon(draw, pts, (34, 34, 34, 210), color, 3, rng)


def scratches(draw: ImageDraw.ImageDraw, rng: random.Random, count=9):
    for _ in range(count):
        x = rng.randint(29, 94)
        y = rng.randint(28, 98)
        rough_line(draw, [(x, y), (x + rng.randint(-10, 10), y + rng.randint(-5, 7))], (28, 28, 28, 130), 1, rng)


def draw_icon(item_id: str, quality: str) -> Image.Image:
    rng = random.Random(item_id)
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    mask = Image.new("L", (SIZE, SIZE), 0)
    d = ImageDraw.Draw(img)
    md = ImageDraw.Draw(mask)

    fill = (96, 98, 95, 238)
    light = (150, 153, 146, 235)
    dark = (31, 31, 30, 255)
    accent = QUALITY_ACCENTS.get(quality, QUALITY_ACCENTS["C"])

    def poly(points, f=fill):
        rough_polygon(d, points, f, dark, 4, rng)
        md.polygon(points, fill=255)

    def ell(box, f=fill):
        rough_ellipse(d, box, f, dark, 4, rng)
        md.ellipse(box, fill=255)

    def rect(box, f=fill, w=4):
        pts = [(box[0], box[1]), (box[2], box[1]), (box[2], box[3]), (box[0], box[3])]
        rough_polygon(d, pts, f, dark, w, rng)
        md.polygon(pts, fill=255)

    if item_id in {"scrap_metal", "rusted_bolts"}:
        for pts in [
            [(34, 39), (74, 31), (68, 64), (29, 70)],
            [(57, 62), (96, 54), (101, 87), (53, 94)],
            [(31, 76), (54, 68), (66, 102), (38, 105)],
        ]:
            poly(pts, (105, 108, 103, 235))
        if item_id == "rusted_bolts":
            for x, y in [(50, 48), (78, 74), (48, 88), (90, 62)]:
                ell((x - 7, y - 7, x + 7, y + 7), (82, 78, 70, 235))
                d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(20, 20, 20, 180))
    elif item_id in {"wire_coil", "signal_resonator_coil"}:
        ell((28, 28, 100, 100), (70, 72, 72, 220))
        for i in range(6):
            pad = 9 + i * 5
            d.ellipse((28 + pad, 28 + pad, 100 - pad, 100 - pad), outline=(22, 22, 22, 210), width=3)
        rough_line(d, [(90, 50), (109, 37)], accent, 3, rng)
        rough_line(d, [(91, 80), (111, 92)], accent, 3, rng)
    elif item_id in {"battery_old", "pulse_battery"}:
        rect((38, 34, 91, 96), (94, 94, 89, 240))
        rect((50, 25, 79, 37), (70, 72, 70, 235), 3)
        rough_line(d, [(51, 54), (78, 54)], dark, 3, rng)
        if item_id == "pulse_battery":
            rough_line(d, [(48, 77), (60, 64), (66, 78), (81, 60)], accent, 4, rng)
    elif item_id in {"medicine_powder", "stability_candy", "ration_bar"}:
        if item_id == "stability_candy":
            poly([(36, 52), (52, 43), (80, 43), (95, 53), (81, 72), (51, 73)])
            rough_line(d, [(58, 48), (77, 67)], accent, 3, rng)
        else:
            rect((34, 43, 95, 86), (127, 124, 112, 238))
            rough_line(d, [(39, 63), (91, 63)], dark, 2, rng)
            if item_id == "medicine_powder":
                d.ellipse((56, 55, 70, 69), outline=accent, width=3)
            else:
                rough_line(d, [(47, 52), (82, 77)], (78, 67, 55, 180), 2, rng)
    elif item_id in {"tool_parts", "outpost_fuse", "outpost_servo_pack"}:
        for x, y, r in [(46, 54, 17), (76, 72, 21)]:
            ell((x - r, y - r, x + r, y + r), (92, 92, 88, 238))
            ell((x - 6, y - 6, x + 6, y + 6), (30, 30, 30, 180))
        if item_id == "outpost_fuse":
            rect((49, 35, 78, 93), (105, 105, 98, 240))
            rough_line(d, [(55, 42), (72, 86)], accent, 3, rng)
        if item_id == "outpost_servo_pack":
            rect((34, 33, 94, 93), (83, 84, 81, 238))
            rough_line(d, [(44, 45), (85, 84)], accent, 3, rng)
    elif item_id == "outpost_filter":
        rect((39, 30, 89, 96), (130, 130, 122, 238))
        for x in [50, 61, 72, 83]:
            rough_line(d, [(x, 36), (x - 8, 91)], dark, 2, rng)
        rough_line(d, [(43, 45), (85, 45)], accent, 2, rng)
    elif item_id in {"field_bandage", "sterile_patch"}:
        if item_id == "field_bandage":
            ell((36, 37, 91, 91), (136, 132, 121, 240))
            ell((51, 51, 76, 76), (61, 61, 58, 230))
        else:
            rect((31, 41, 98, 86), (145, 143, 131, 240))
        rough_line(d, [(55, 63), (75, 63)], accent, 4, rng)
        rough_line(d, [(65, 53), (65, 73)], accent, 4, rng)
    elif item_id == "signal_injector":
        rough_line(d, [(32, 89), (88, 34)], dark, 7, rng)
        rough_line(d, [(36, 85), (84, 38)], (155, 157, 151, 245), 4, rng)
        rough_line(d, [(74, 28), (97, 51)], dark, 4, rng)
        rough_line(d, [(46, 74), (58, 86)], accent, 3, rng)
        md.line((32, 89, 97, 28), fill=255, width=12)
    elif item_id in {"backpack_small_reinforced", "reinforced_strap"}:
        rect((38, 34, 88, 98), (88, 87, 80, 245))
        rough_line(d, [(46, 34), (45, 18), (81, 18), (81, 34)], dark, 4, rng)
        rough_line(d, [(48, 55), (79, 55)], accent, 3, rng)
        if item_id == "reinforced_strap":
            rough_line(d, [(37, 35), (88, 98)], dark, 8, rng)
            rough_line(d, [(40, 36), (91, 97)], (132, 130, 120, 240), 4, rng)
    elif item_id in {"scanner_broken", "thermal_scope_module"}:
        rect((34, 42, 93, 82), (80, 84, 83, 238))
        ell((45, 50, 68, 73), (30, 35, 37, 230))
        ell((70, 48, 88, 66), (42, 48, 50, 230))
        rough_line(d, [(72, 78), (86, 100)], dark, 5, rng)
        rough_line(d, [(48, 38), (58, 29)], accent, 3, rng)
    elif item_id in {"bp_backpack_small", "street_map_fragment"}:
        poly([(31, 36), (91, 27), (99, 91), (39, 101)], (133, 130, 116, 238))
        for x in [48, 66, 83]:
            rough_line(d, [(x, 34), (x + 6, 94)], (40, 40, 38, 140), 1, rng)
        for y in [52, 70]:
            rough_line(d, [(37, y), (94, y - 9)], (40, 40, 38, 140), 1, rng)
        rough_line(d, [(45, 82), (62, 67), (79, 74)], accent, 2, rng)
    elif item_id == "keepsake_photo":
        rect((35, 31, 93, 95), (126, 123, 112, 238))
        rect((43, 42, 85, 78), (72, 75, 73, 235), 2)
        rough_line(d, [(49, 82), (78, 86)], (42, 42, 40, 170), 2, rng)
    elif item_id in {"gold_data_chip", "sanctuary_nav_chip", "blackbox_memory_core"}:
        base = (92, 76, 52, 240) if item_id == "gold_data_chip" else (48, 50, 52, 242)
        rect((36, 36, 94, 92), base)
        for x in [44, 54, 74, 85]:
            rough_line(d, [(x, 29), (x, 37)], accent, 2, rng)
            rough_line(d, [(x, 92), (x, 101)], accent, 2, rng)
        rough_line(d, [(49, 51), (79, 51), (79, 77), (58, 77)], accent, 2, rng)
    elif item_id == "cracked_lens":
        ell((31, 31, 97, 97), (118, 130, 130, 120))
        for pts in [[(64, 38), (58, 64), (70, 91)], [(42, 62), (64, 64), (89, 52)]]:
            rough_line(d, pts, dark, 2, rng)
    elif item_id == "duct_tape_roll":
        ell((31, 35, 96, 91), (101, 104, 101, 238))
        ell((49, 49, 78, 78), (30, 30, 30, 180))
        rough_line(d, [(72, 41), (101, 36), (88, 52)], dark, 3, rng)
    elif item_id == "cracked_compass":
        ell((31, 30, 98, 97), (112, 106, 91, 238))
        ell((43, 42, 86, 85), (72, 76, 74, 220))
        poly([(65, 46), (72, 66), (61, 79), (57, 60)], accent)
        rough_line(d, [(47, 52), (82, 80)], dark, 2, rng)
    elif item_id == "sealed_medkit":
        rect((31, 39, 98, 91), (136, 136, 128, 242))
        rect((49, 30, 79, 43), (112, 112, 106, 238), 3)
        rough_line(d, [(55, 65), (75, 65)], accent, 5, rng)
        rough_line(d, [(65, 55), (65, 75)], accent, 5, rng)
    elif item_id == "survey_drone_core":
        ell((39, 36, 90, 87), (72, 76, 76, 242))
        for x, y in [(28, 45), (101, 45), (31, 87), (98, 87)]:
            ell((x - 9, y - 9, x + 9, y + 9), (75, 77, 76, 230))
            rough_line(d, [(64, 62), (x, y)], dark, 3, rng)
        ell((54, 51, 76, 73), (31, 34, 35, 230))
        rough_line(d, [(57, 62), (73, 62)], accent, 2, rng)
    elif item_id == "prefall_access_key":
        ell((31, 47, 61, 77), (102, 104, 98, 242))
        rough_line(d, [(58, 62), (99, 62)], dark, 8, rng)
        rough_line(d, [(78, 62), (78, 76), (88, 62), (88, 73)], dark, 4, rng)
        rough_line(d, [(58, 62), (99, 62)], accent, 2, rng)
        md.line((58, 62, 99, 62), fill=255, width=14)
    elif item_id == "anomaly_heart_shard":
        poly([(64, 19), (91, 48), (80, 101), (42, 96), (32, 50)], (95, 86, 103, 242))
        rough_line(d, [(50, 42), (68, 63), (54, 88)], accent, 3, rng)
        rough_line(d, [(70, 32), (81, 49)], accent, 2, rng)
    elif item_id == "ss_silverwing_engine_core":
        ell((35, 34, 93, 92), (86, 90, 92, 245))
        ell((50, 49, 78, 77), (31, 34, 35, 230))
        for a in range(0, 360, 45):
            x = 64 + math.cos(math.radians(a)) * 42
            y = 64 + math.sin(math.radians(a)) * 42
            rough_line(d, [(64, 64), (x, y)], (160, 165, 166, 185), 2, rng)
        rough_line(d, [(48, 64), (80, 64)], (155, 205, 245, 245), 3, rng)
    elif item_id == "ss_pink_star":
        pts = []
        for i in range(10):
            r = 42 if i % 2 == 0 else 19
            a = math.radians(-90 + i * 36)
            pts.append((64 + math.cos(a) * r, 64 + math.sin(a) * r))
        poly(pts, (128, 88, 116, 242))
        rough_line(d, [(47, 64), (81, 64)], accent, 3, rng)
    elif item_id == "ss_wanming_pocket_watch":
        ell((34, 35, 94, 95), (120, 112, 91, 242))
        ell((45, 46, 83, 84), (65, 64, 58, 230))
        rect((56, 24, 72, 38), (104, 96, 80, 238), 3)
        rough_line(d, [(64, 65), (64, 51)], accent, 2, rng)
        rough_line(d, [(64, 65), (75, 72)], accent, 2, rng)
    elif item_id == "ss_old_world_gold_bar":
        poly([(34, 65), (52, 41), (94, 48), (106, 75), (88, 96), (45, 89)], (156, 124, 55, 245))
        rough_line(d, [(49, 47), (63, 69), (57, 91)], dark, 2, rng)
        rough_line(d, [(88, 50), (78, 72), (87, 94)], dark, 2, rng)
    elif item_id == "ss_zero_master_control_board":
        rect((29, 38, 99, 91), (58, 62, 62, 245))
        for x, y in [(43, 52), (61, 68), (83, 55), (79, 78)]:
            ell((x - 4, y - 4, x + 4, y + 4), accent)
        rough_line(d, [(43, 52), (61, 68), (83, 55), (79, 78), (48, 79)], accent, 2, rng)
    else:
        rect((35, 35, 93, 93))
        rough_line(d, [(47, 64), (82, 64)], accent, 3, rng)

    scratches(d, rng)
    add_texture(img, mask, rng)
    accent_mark(d, quality, rng)

    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_alpha = mask.filter(ImageFilter.GaussianBlur(1.4)).point(lambda p: int(p * 0.25))
    shadow.putalpha(shadow_alpha)
    final = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    final.alpha_composite(shadow, (2, 3))
    final.alpha_composite(img)
    return final


def read_items():
    with ITEMS_TAB.open("r", encoding="utf-8", errors="replace", newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    items = read_items()
    manifest = []
    for row in items:
        item_id = row["id"]
        quality = row["quality"]
        subject, category = ITEM_SPECS.get(item_id, (item_id.replace("_", " "), row["item_type"]))
        image = draw_icon(item_id, quality)
        out_path = OUT_DIR / f"{item_id}.png"
        image.save(out_path)
        manifest.append(
            {
                "id": item_id,
                "quality": quality,
                "category": category,
                "path": f"res://assets/ui/itemicon/{item_id}.png",
                "prompt": (
                    "Create a 128x128 inventory icon for a 2D wasteland extraction game. "
                    f"Subject: {subject}. Style: dark hand-drawn manga line art, thick black outline, "
                    "rough dirty texture, grayscale and charcoal palette, small muted accent color by quality. "
                    "Composition: centered object, transparent background, readable silhouette at small size. "
                    "Requirements: no text, no watermark, no background scene, clean cutout edges."
                ),
            }
        )

    with (OUT_DIR / "itemicon_manifest.json").open("w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print(f"Generated {len(items)} item icons in {OUT_DIR}")


if __name__ == "__main__":
    main()
