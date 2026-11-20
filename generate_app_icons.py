import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_pepper_reader_logo(size=2048):
    # Render at 2048 for high precision supersampling down to final sizes
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    # Squircle / rounded rectangle mask
    radius = int(size * 0.22)
    margin = int(size * 0.04)
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=255
    )

    # Rich Pepper Red gradient: from vibrant crimson (#D91E36) to deep burgundy (#800C1E)
    grad = Image.new('RGBA', (size, size))
    for y in range(size):
        ratio = y / size
        # Non-linear curve for depth
        factor = math.pow(ratio, 0.8)
        r = int(220 * (1 - factor) + 120 * factor)
        g = int(28 * (1 - factor) + 10 * factor)
        b = int(52 * (1 - factor) + 24 * factor)
        for x in range(size):
            grad.putpixel((x, y), (r, g, b, 255))

    img.paste(grad, (0, 0), mask)

    # Inner subtle vignette ring
    ring = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(ring)
    ring_draw.rounded_rectangle(
        [margin + 8, margin + 8, size - margin - 8, size - margin - 8],
        radius=radius - 6,
        outline=(255, 255, 255, 45),
        width=int(size * 0.012)
    )
    img = Image.alpha_composite(img, ring)

    # Book geometry (open book at bottom/center)
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    cx = size // 2
    book_bottom_y = int(size * 0.76)
    book_spine_y = int(size * 0.46)
    left_x = int(size * 0.18)
    right_x = int(size * 0.82)
    top_outer_y = int(size * 0.38)
    bottom_outer_y = int(size * 0.68)

    # Left page polygon
    left_page = [
        (cx, book_bottom_y),
        (left_x + 30, bottom_outer_y),
        (left_x, top_outer_y),
        (cx - 24, book_spine_y),
        (cx, book_spine_y + 16),
    ]

    # Right page polygon
    right_page = [
        (cx, book_bottom_y),
        (right_x - 30, bottom_outer_y),
        (right_x, top_outer_y),
        (cx + 24, book_spine_y),
        (cx, book_spine_y + 16),
    ]

    # Book shadow
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.polygon(left_page, fill=(0, 0, 0, 80))
    s_draw.polygon(right_page, fill=(0, 0, 0, 80))
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(size * 0.02)))
    img = Image.alpha_composite(img, shadow)

    # Draw pages
    draw.polygon(left_page, fill=(244, 246, 248, 255))
    draw.polygon(right_page, fill=(255, 255, 255, 255))

    # Page fold and edge styling
    draw.line([(cx, book_spine_y + 16), (cx, book_bottom_y)], fill=(195, 200, 208, 255), width=int(size * 0.007))
    draw.line([(cx - 24, book_spine_y), (left_x, top_outer_y)], fill=(225, 228, 233, 255), width=int(size * 0.005))
    draw.line([(cx + 24, book_spine_y), (right_x, top_outer_y)], fill=(225, 228, 233, 255), width=int(size * 0.005))

    # Golden bookmark ribbon descending below book
    ribbon_w = int(size * 0.038)
    ribbon_h = int(size * 0.40)
    ribbon = [
        (cx - ribbon_w, book_spine_y + 10),
        (cx + ribbon_w, book_spine_y + 10),
        (cx + ribbon_w, book_bottom_y + int(size * 0.06)),
        (cx, book_bottom_y + int(size * 0.03)),
        (cx - ribbon_w, book_bottom_y + int(size * 0.06)),
    ]
    draw.polygon(ribbon, fill=(255, 193, 7, 255))

    # Stylized Red Chili Pepper Logo Icon emerging like a flame from the center
    # Outer white contour for crisp contrast
    pepper_scale = size / 1024
    def pt(x, y):
        return (int(x * pepper_scale), int(y * pepper_scale))

    outer_chili = [
        pt(512, 190), pt(546, 218), pt(575, 260), pt(590, 316),
        pt(582, 376), pt(556, 435), pt(532, 485), pt(512, 535),
        pt(492, 485), pt(468, 435), pt(442, 376), pt(434, 316),
        pt(449, 260), pt(478, 218)
    ]
    draw.polygon(outer_chili, fill=(255, 255, 255, 255))

    # Inner fiery Pepper Red chili body
    inner_chili = [
        pt(512, 210), pt(540, 235), pt(562, 272), pt(574, 320),
        pt(566, 370), pt(544, 422), pt(524, 468), pt(512, 506),
        pt(500, 468), pt(480, 422), pt(458, 370), pt(450, 320),
        pt(462, 272), pt(484, 235)
    ]
    draw.polygon(inner_chili, fill=(210, 24, 48, 255))

    # Chili highlight reflection
    highlight = [
        pt(535, 255), pt(550, 290), pt(554, 340), pt(542, 390),
        pt(534, 385), pt(544, 335), pt(540, 290), pt(528, 262)
    ]
    draw.polygon(highlight, fill=(255, 110, 130, 220))

    # Green Pepper Stem with natural curve
    stem = [
        pt(504, 210), pt(508, 172), pt(522, 150), pt(538, 142),
        pt(544, 148), pt(532, 165), pt(520, 182), pt(518, 210)
    ]
    draw.polygon(stem, fill=(46, 204, 113, 255))

    img = Image.alpha_composite(img, overlay)
    return img

def main():
    root = r'c:\Users\HomePC\Videos\Tutorial\EbookApp'
    master = create_pepper_reader_logo(2048)

    # Save high-res master
    docs_dir = os.path.join(root, 'docs', 'assets')
    os.makedirs(docs_dir, exist_ok=True)
    master_1024 = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    master_1024.save(os.path.join(docs_dir, 'logo.png'), 'PNG')
    print('Saved master logo: docs/assets/logo.png')

    # Save in-app assets for Mobile and Desktop
    mobile_img_dir = os.path.join(root, 'Mobile', 'assets', 'images')
    desktop_img_dir = os.path.join(root, 'Desktop', 'assets', 'images')
    os.makedirs(mobile_img_dir, exist_ok=True)
    os.makedirs(desktop_img_dir, exist_ok=True)

    logo_512 = master.resize((512, 512), Image.Resampling.LANCZOS)
    logo_512.save(os.path.join(mobile_img_dir, 'app_logo.png'), 'PNG')
    logo_512.save(os.path.join(desktop_img_dir, 'app_logo.png'), 'PNG')
    print('Saved in-app assets: app_logo.png')

    # Android launcher icons
    android_res = os.path.join(root, 'Mobile', 'android', 'app', 'src', 'main', 'res')
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, px in android_sizes.items():
        out_dir = os.path.join(android_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        icon = master.resize((px, px), Image.Resampling.LANCZOS)
        icon.save(os.path.join(out_dir, 'ic_launcher.png'), 'PNG')
        print(f'Saved Android {folder} ({px}x{px})')

    # Windows Desktop ICO
    win_ico_path = os.path.join(root, 'Desktop', 'windows', 'runner', 'resources', 'app_icon.ico')
    os.makedirs(os.path.dirname(win_ico_path), exist_ok=True)
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    master.save(win_ico_path, format='ICO', sizes=ico_sizes)
    print(f'Saved Windows Desktop multi-resolution ICO: {win_ico_path}')

    # iOS AppIcon
    ios_icon_dir = os.path.join(root, 'Mobile', 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(ios_icon_dir, exist_ok=True)
    ios_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    for filename, px in ios_sizes.items():
        icon = master.resize((px, px), Image.Resampling.LANCZOS)
        icon.save(os.path.join(ios_icon_dir, filename), 'PNG')
    print('Saved iOS AppIcon set')

    # macOS Desktop AppIcon
    macos_icon_dir = os.path.join(root, 'Desktop', 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(macos_icon_dir, exist_ok=True)
    macos_sizes = {
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024,
    }
    for filename, px in macos_sizes.items():
        icon = master.resize((px, px), Image.Resampling.LANCZOS)
        icon.save(os.path.join(macos_icon_dir, filename), 'PNG')
    print('Saved macOS AppIcon set')

if __name__ == '__main__':
    main()
