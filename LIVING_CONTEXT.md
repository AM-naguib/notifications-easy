# Living Context

## Recent Tasks
- Diagnosed white app icon issue in iOS project: Found that PNG images in `AppIcon.appiconset` have transparency (RGBA).

## Decisions & Discoveries
- **App Icon Transparency**: iOS requires app icons to be strictly opaque. Transparency causes the system to fill the background with white or black.

## Known Limitations / Bugs
- iOS App Icon is currently displaying as white because the source image files contain an alpha channel.
