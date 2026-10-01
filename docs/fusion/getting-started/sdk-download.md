---
title: "SDK & Download"
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/getting-started/sdk-download
product: fusion-godot
version: v3-client-server
language: en-us
description: "Get the Photon Fusion SDK for Godot 4: GDExtension downloads for Windows, macOS, and Linux, release notes, and version compatibility. Free tier included."
timestamp: 2026-07-21
---

# SDK & Download

> **Info: Preview**
> 
> Fusion Godot SDK 3.0.0 is a development preview and is **not** intended for production use.
> The API may change during the preview phase.

## Download

- [**Download**](https://dev-downloads.photonengine.com/download/latest/photon-fusion-godot-sdk-3-godot-46): Download Fusion Godot SDK 3.0 for Godot 4.6
- [**Changelog**](release-notes.md): View release notes for Fusion Godot 3.0.0


<table><thead><th>Version</th><th>Release Date</th><th colspan="2">Download</th></thead><tbody><tr><td>3.0.0 Preview</td><td>Jul 17, 2026</td><td><a href="https://dev-downloads.photonengine.com/download/fusion-godot/photon-fusion-godot4.6-3.0.0-preview-555.7z?pre=sp">Fusion Godot SDK 3.0.0 Preview Build 555</a></td><td><a href="/fusion-godot/v3-shared-authority/getting-started/release-notes#build-555-Jul-17-2026">Release Notes</a></td></tr></tbody></table>


## Requirements

- Fusion 3 AppId ([Photon Dashboard](https://dev-dashboard.photonengine.com))
- Godot 4.6+
- Windows, Linux, macOS, iOS, Android or web

## Installation

1. Download and extract the SDK archive.
2. Copy the `fusion/` folder into `addons/` in your Godot project root (create `addons/` if it doesn't exist).
3. Reopen the project - Godot loads the GDExtension automatically.

## SDK Contents

- `fusion/` - GDExtension plugin
- `fusion/bin/` - platform-specific native libraries
- `fusion/fusion.gdextension` - GDExtension descriptor
