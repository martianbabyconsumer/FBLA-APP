"""
iOS Icon Generator for Flutter App
This script generates all required iOS app icons from a single source image.
Compatible with iPad/iPhone and AltStore sideloading.

Requirements:
    pip install Pillow

Usage:
    python generate_ios_icons.py <path_to_your_logo.png>
    
Example:
    python generate_ios_icons.py my_logo.png
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow library not found.")
    print("Please install it using: pip install Pillow")
    sys.exit(1)


# Define all required iOS icon sizes
# Format: (filename, size_in_pixels, description)
ICON_SIZES = [
    # iPhone icons
    ("Icon-App-20x20@2x.png", 40, "iPhone Notification 2x"),
    ("Icon-App-20x20@3x.png", 60, "iPhone Notification 3x"),
    ("Icon-App-29x29@1x.png", 29, "iPhone Settings 1x"),
    ("Icon-App-29x29@2x.png", 58, "iPhone Settings 2x"),
    ("Icon-App-29x29@3x.png", 87, "iPhone Settings 3x"),
    ("Icon-App-40x40@2x.png", 80, "iPhone Spotlight 2x"),
    ("Icon-App-40x40@3x.png", 120, "iPhone Spotlight 3x"),
    ("Icon-App-60x60@2x.png", 120, "iPhone App 2x"),
    ("Icon-App-60x60@3x.png", 180, "iPhone App 3x"),
    
    # iPad icons
    ("Icon-App-20x20@1x.png", 20, "iPad Notification 1x"),
    ("Icon-App-40x40@1x.png", 40, "iPad Spotlight 1x"),
    ("Icon-App-76x76@1x.png", 76, "iPad App 1x"),
    ("Icon-App-76x76@2x.png", 152, "iPad App 2x"),
    ("Icon-App-83.5x83.5@2x.png", 167, "iPad Pro App 2x"),
    
    # App Store
    ("Icon-App-1024x1024@1x.png", 1024, "App Store"),
]


def validate_source_image(image_path):
    """Validate that the source image exists and is suitable."""
    if not os.path.exists(image_path):
        print(f"Error: Image file not found: {image_path}")
        return False
    
    try:
        img = Image.open(image_path)
        width, height = img.size
        
        if width != height:
            print(f"Warning: Image is not square ({width}x{height}). It will be cropped.")
        
        if width < 1024 or height < 1024:
            print(f"Warning: Image is smaller than 1024x1024 ({width}x{height}).")
            print("For best quality, use an image at least 1024x1024 pixels.")
        
        return True
    except Exception as e:
        print(f"Error: Cannot open image file: {e}")
        return False


def make_square(img):
    """Crop image to square using the center."""
    width, height = img.size
    if width == height:
        return img
    
    size = min(width, height)
    left = (width - size) // 2
    top = (height - size) // 2
    right = left + size
    bottom = top + size
    
    return img.crop((left, top, right, bottom))


def generate_icons(source_path, output_dir):
    """Generate all icon sizes from the source image."""
    print(f"\nGenerating iOS icons from: {source_path}")
    print(f"Output directory: {output_dir}\n")
    
    # Open and prepare source image
    try:
        source_img = Image.open(source_path)
        
        # Convert to RGBA if needed (to preserve transparency)
        if source_img.mode != 'RGBA':
            source_img = source_img.convert('RGBA')
        
        # Make square if needed
        source_img = make_square(source_img)
        
    except Exception as e:
        print(f"Error processing source image: {e}")
        return False
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate each icon size
    success_count = 0
    for filename, size, description in ICON_SIZES:
        try:
            # Resize image using high-quality resampling
            resized = source_img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save as PNG
            output_path = os.path.join(output_dir, filename)
            resized.save(output_path, 'PNG', optimize=True)
            
            print(f"✓ Generated {filename:30} ({size:4}x{size:4}) - {description}")
            success_count += 1
            
        except Exception as e:
            print(f"✗ Failed to generate {filename}: {e}")
    
    print(f"\n{'='*60}")
    print(f"Successfully generated {success_count}/{len(ICON_SIZES)} icons")
    print(f"{'='*60}")
    
    if success_count == len(ICON_SIZES):
        print("\n✓ All icons generated successfully!")
        print("\nNext steps:")
        print("1. The icons are ready in the AppIcon.appiconset folder")
        print("2. Rebuild your Flutter app: flutter build ios")
        print("3. Sideload with AltStore to see your new icon on iPad")
        return True
    else:
        print("\n⚠ Some icons failed to generate. Please check the errors above.")
        return False


def main():
    """Main entry point."""
    print("=" * 60)
    print("iOS Icon Generator for Flutter")
    print("=" * 60)
    
    # Check command line arguments
    if len(sys.argv) != 2:
        print("\nUsage: python generate_ios_icons.py <path_to_your_logo.png>")
        print("\nExample:")
        print("  python generate_ios_icons.py my_logo.png")
        print("\nNote: For best results, use a 1024x1024 PNG image with transparency.")
        sys.exit(1)
    
    source_image = sys.argv[1]
    
    # Validate source image
    if not validate_source_image(source_image):
        sys.exit(1)
    
    # Determine output directory (iOS asset catalog location)
    script_dir = Path(__file__).parent
    output_dir = script_dir / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    
    # Generate icons
    success = generate_icons(source_image, str(output_dir))
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
