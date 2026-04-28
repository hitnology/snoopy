[简体中文](README.md) | **English**

# Snoopy for macOS

An unofficial macOS port of the Snoopy screen saver originally seen on Apple TV / tvOS.

The goal of this project is straightforward: reproduce the tvOS Snoopy screen saver experience on macOS as faithfully as possible, including background artwork, transparent video layers, clip sequencing, and randomized playback.

## Purpose

- Port the Snoopy screen saver from tvOS into an installable macOS `.saver` bundle
- Preserve the original visual style and playback rhythm of the source material
- Rebuild clip sequencing, looping, and background switching around the macOS screen saver lifecycle
- Provide an open-source codebase that can be maintained and improved over time

## Tech Stack

- `Objective-C`
- `ScreenSaver.framework`
- `SpriteKit`
- `AVFoundation`
- `AVKit`
- `Xcode`

## Architecture Overview

The project is mainly organized around the following pieces:

- [`snoopyView`](/Users/yichen/Documents/git/Snoopy/snoopy/snoopyView.h) / [`snoopyView.m`](/Users/yichen/Documents/git/Snoopy/snoopy/snoopyView.m)
  - Entry point for the screen saver
  - Sets up `ScreenSaverView`, `SKView`, and `SKScene`
  - Manages playback, background updates, and screen saver lifecycle events
- [`Clip.h`](/Users/yichen/Documents/git/Snoopy/snoopy/Clip.h) / [`Clip.m`](/Users/yichen/Documents/git/Snoopy/snoopy/Clip.m)
  - Scans `.mov` assets bundled into the screen saver
  - Groups media into logical clips
  - Produces playback order and randomized clip sequencing

## Playback Strategy

This project does more than just play videos back-to-back. It rebuilds a playback layer that fits the macOS screen saver environment:

- `SKVideoNode` is used to render alpha videos inside a `SpriteKit` scene
- `AVQueuePlayer` is used to keep clip playback continuous
- The `Clip` model organizes media into structures such as `Intro / Loop / Outro / Others`
- Background color and artwork nodes reproduce the layered tvOS look
- Clip boundaries are handled separately to reduce flicker and ghosting

## Build

You can build the project directly in Xcode:

- Open [`snoopy.xcodeproj`](/Users/yichen/Documents/git/Snoopy/snoopy.xcodeproj)
- Select the `snoopy` scheme
- Build with the `Release` configuration

Or use the command line:

```bash
xcodebuild -project snoopy.xcodeproj -scheme snoopy -configuration Release build
```

The output is a macOS screen saver bundle:

- `snoopy.saver`

## Asset Notes

- The repository does not include the full video assets
- Those files are intentionally not uploaded to GitHub because of copyright constraints and file size
- The playback code in this project still supports those assets when they are bundled locally

## Project Scope

This repository focuses on bringing the Snoopy screen saver experience to macOS, with particular attention to:

- matching the tvOS presentation as closely as possible
- handling video playback constraints in the macOS screen saver environment
- keeping the project maintainable for future work on transitions, asset organization, and stability

## Version History

### v0.2.1

This release fixed the `legacyScreenSaver` memory issue.

The key finding was that macOS does not always call `stopAnimation()` when a screen saver stops. Instead, it sends the `com.apple.screensaver.willstop` notification, which needs to be handled explicitly.

### v0.1.1

This version still had known issues: it could occasionally start with a black screen, and long sessions could become sluggish.

At the time, the likely cause appeared to be `AVQueuePlayer` queue management.

This version also switched playback to `SpriteKit`, which made it possible to render HEVC videos with alpha for the layered background effect.

## 中文说明

See [README.md](README.md).
