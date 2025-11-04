# iOS Icon Setup Guide

This guide will help you change the app logo for iPad when using AltStore.

## Prerequisites

1. **Python 3.x** installed on your computer
2. **Pillow library** for image processing

Install Pillow if you haven't already:
```bash
pip install Pillow
```

## Steps to Change Your Logo

### 1. Prepare Your Logo

Create or find your logo image with these specifications:
- **Format:** PNG (supports transparency)
- **Size:** At least 1024x1024 pixels (recommended)
- **Shape:** Square (or it will be auto-cropped to square)
- **Design tips:**
  - Keep important elements away from edges
  - Use simple, recognizable designs
  - Test how it looks at small sizes (20x20 pixels)

### 2. Run the Icon Generator Script

Place your logo image in the `flutter_application_3` folder, then run:

```bash
python generate_ios_icons.py your_logo.png
```

For example, if your logo is named `fbla_logo.png`:
```bash
python generate_ios_icons.py fbla_logo.png
```

The script will:
- ✓ Validate your image
- ✓ Generate 15 different icon sizes
- ✓ Save them to `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- ✓ Show you a summary of generated icons

### 3. Rebuild Your App

After generating the icons, rebuild your Flutter app:

```bash
flutter clean
flutter build ios --release
```

### 4. Sideload with AltStore

1. Open AltStore on your computer
2. Connect your iPad
3. Install the rebuilt IPA file
4. Your new icon should now appear on your iPad!

## Icon Sizes Generated

The script creates icons for all iOS devices:

### iPad Icons
- 20x20, 40x40 (notifications)
- 29x29, 58x58 (settings)
- 40x40, 80x80 (spotlight)
- **76x76, 152x152** (main iPad app icon)
- **167x167** (iPad Pro app icon)

### iPhone Icons
- Various sizes from 40x40 to 180x180

### App Store
- 1024x1024 (required for App Store/AltStore)

## Troubleshooting

**Error: "Pillow library not found"**
- Run: `pip install Pillow`

**Warning: "Image is not square"**
- Your image will be center-cropped automatically
- For best results, prepare a square image beforehand

**Warning: "Image is smaller than 1024x1024"**
- The script will work but quality may be reduced
- Use a larger source image for better results

**Icons not showing after rebuild**
- Run `flutter clean` before rebuilding
- Make sure you're building in release mode
- Reinstall the app completely on your iPad

## Tips for Best Results

1. **High resolution source:** Start with at least 1024x1024 (or larger)
2. **Transparent background:** Use PNG with transparency for modern look
3. **Simple design:** Complex details don't show well at small sizes
4. **Test visibility:** Check how your icon looks at 76x76 (iPad size)
5. **Safe area:** Keep important elements within the center 80% of the image

## Need Help?

If you encounter any issues:
1. Check that Python and Pillow are installed correctly
2. Verify your source image opens in an image viewer
3. Make sure the output directory exists: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
