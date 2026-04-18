# App Icon Assets

This directory should contain the following files for the app launcher icon:

- `app_icon.png` - Main app icon (1024x1024 pixels recommended)
- `app_icon_foreground.png` - Foreground icon for adaptive icons (1024x1024 pixels)

## Icon Design
The app icon should feature:
- A water drop design
- Blue color scheme (#2196F3 primary)
- Clean, modern look
- High contrast for visibility

## How to Create Icons
1. Use the provided SVG file as a template: `app_icon.svg`
2. Convert to PNG using online tools or design software
3. Ensure the icon is:
   - 1024x1024 pixels for high resolution
   - Square format
   - Transparent background (for adaptive icon)

## Tools for Icon Creation
- Online: https://icon.kitchen/
- Design: Adobe Illustrator, Figma, Canva
- Simple: MS Paint with export to PNG

## After Adding Icons
Run this command to generate launcher icons:
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```
