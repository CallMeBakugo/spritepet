# spritepet

An image-based desktop pet for Wayland compositors that support wlr-layer-shell, including Hyprland, Sway, and river. Drop any collection of PNG or WebP images into a configuration directory and spritepet floats them above your windows as living companions with full click-through transparency. The whole pet is a single QML file running on Quickshell, so there is no Electron, no X11, and nothing to compile.

## Features

- Any image becomes a pet. Every PNG or WebP file in the images directory is discovered automatically at startup, and each file becomes a mood that you can cycle through.
- She moves without animation files. The pet breathes with a gentle bob, sways around her feet, hops when you click her, and surprises you with an occasional idle hop, all through parametric transforms on a still image.
- Full click-through transparency. Input passes straight through her window everywhere except her body, so she never blocks your work.
- Drag her anywhere on the screen and resize her from figurine to billboard with the scroll wheel.
- A JSON configuration file tunes her size, her position, her breathing depth, her sway, her hop height, and how often she hops while idle.

## Requirements

- Quickshell 0.3 or newer
- A Wayland compositor that supports the wlr-layer-shell protocol

## Installation

Clone the repository and launch her with Quickshell, pointing at the checkout path:

```
git clone https://github.com/CallMeBakugo/spritepet.git
qs -d -n -p /path/to/spritepet
```

To start her automatically under Hyprland, add this line to your hyprland.conf:

```
exec-once = qs -d -n -p /path/to/spritepet
```

To dismiss her at any time, run `pkill -x qs`. To bring her back, run the launch command again.

## Controls

| Input over her body | Effect |
|---|---|
| Left drag | Move her anywhere on the screen |
| Scroll | Resize her between 5 percent and 600 percent of the image's native size |
| Left click | She hops |
| Right click | Cycle to the next mood image |

## Configuration

Spritepet reads an optional JSON file from `$XDG_CONFIG_HOME/spritepet/config.json`, which is `~/.config/spritepet/config.json` by default. Copy `config.json.example` from this repository there and adjust it to taste. Every key is optional, and missing keys fall back to the defaults listed here.

| Key | Default | Meaning |
|---|---|---|
| scale | 0.9 | Her initial size relative to the image's native resolution |
| margin | 130 | Distance in pixels from the screen edges where she first appears |
| x | unset | Absolute horizontal position in pixels; when unset she appears near the bottom-right corner |
| y | unset | Absolute vertical position in pixels |
| bobAmplitude | 12 | How far in pixels she rises while breathing |
| bobDurationMs | 1800 | Duration in milliseconds of each half of the breathing cycle |
| swayAngleDeg | 1.2 | How far in degrees she leans while swaying |
| swayDurationMs | 2600 | Duration in milliseconds of each half of the sway |
| hopHeight | 70 | How high in pixels she hops when clicked |
| idleHopMinMs | 20000 | Earliest time in milliseconds between surprise hops while idle |
| idleHopMaxMs | 34000 | Latest time in milliseconds between surprise hops while idle |

## Moods

Place any images you like into `$XDG_CONFIG_HOME/spritepet/images/`. Files are listed alphabetically at startup, and right-clicking the pet cycles through them in that order. A transparent PNG cutout looks best; for artwork on a plain background, any background-removal tool will free her first. If the directory is empty, the pet shows a hint explaining where to put images instead.

This repository ships one ready-made mood in `example-moods/`. Copy it into your images directory and she will appear on your next launch:

```
mkdir -p ~/.config/spritepet/images
cp example-moods/canari-fingerheart.png ~/.config/spritepet/images/
```

With a single image in the directory, the pet has nothing to cycle through and simply keeps her on screen.

## Notes for contributors

Four Quickshell specifics caused real debugging pain during development and are worth knowing before you touch the QML. A Quickshell window defaults to an opaque background, so the root PanelWindow must set `color: "transparent"` or the overlay whites out the entire monitor. The `StdioCollector` type lives in the `Quickshell.Io` module rather than in the core module. The layer and keyboard-focus enums come from the private `Quickshell.Wayland._WlrLayerShell` module and are used as `WlrLayer.Overlay` and `WlrKeyboardFocus.None`, not as members of the attached `WlrLayershell` object. Finally, click-through transparency outside the sprite is achieved with `mask: Region { item: <spriteItem> }`, and the input region follows that item through drags and zooms automatically.

## Roadmap

- An IPC handler so external scripts can switch moods and toggle visibility.
- Explicit multi-output selection in the configuration.
- Persisting zoom and position across restarts.
- Support for animated WebP moods that play short loops.

## License

MIT, Copyright (c) 2026 Bakugo. See the LICENSE file for the full text.
