<!-- Generated from pebble-dev/developer.rebble.io (Apache 2.0) with modifications -->

# App Resources

> Information on the many kinds of files that can be used inside Pebble apps.

## Animated Images

The Pebble SDK allows animated images to be played inside an app using the
``GBitmapSequence`` API, which takes [APNG](https://en.wikipedia.org/wiki/APNG)
images as input files. APNG files are similar to well-known `.gif` files, which
are not supported directly but can be converted to APNG.

A similar effect can be achieved with multiple image resources, a
``BitmapLayer`` and an ``AppTimer``, but would require a lot more code. The
``GBitmapSequence`` API handles the reading, decompression, and frame
duration/count automatically.

## Converting GIF to APNG

A `.gif` file can be converted to the APNG `.png` format with
[gif2apng](http://gif2apng.sourceforge.net/) and the `-z0` flag:

```text
./gif2apng -z0 animation.gif
```

> Note: The file extension must be `.png`, **not** `.apng`.

## Adding an APNG

Include the APNG file in the `resources` array in `package.json` as a `raw`
resource:

```js
"resources": {
  "media": [
    {
      "type":"raw",
      "name":"ANIMATION",
      "file":"images/animation.png"
    }
  ]
}
```

## Displaying APNG Frames

The ``GBitmapSequence`` will use a ``GBitmap`` as a container and update its
contents each time a new frame is read from the APNG file. This means that the
first step is to create a blank ``GBitmap`` to be this container.

Declare file-scope variables to hold the data:

```c
static GBitmapSequence *s_sequence;
static GBitmap *s_bitmap;
```

Load the APNG from resources into the ``GBitmapSequence`` variable, and use the
frame size to create the blank ``GBitmap`` frame container:

```c
// Create sequence
s_sequence = gbitmap_sequence_create_with_resource(RESOURCE_ID_ANIMATION);

// Create blank GBitmap using APNG frame size
GSize frame_size = gbitmap_sequence_get_bitmap_size(s_sequence);
s_bitmap = gbitmap_create_blank(frame_size, GBitmapFormat8Bit);
```

Once the app is ready to begin playing the animated image, advance each frame
using an ``AppTimer`` until the end of the sequence is reached. Loading the next
APNG frame is handled for you and written to the container ``GBitmap``.

Declare a ``BitmapLayer`` variable to display the current frame, and set it up
as described under
.

```c
static BitmapLayer *s_bitmap_layer;
```

Create the callback to be used when the ``AppTimer`` has elapsed, and the next
frame should be displayed. This will occur in a loop until there are no more
frames, and ``gbitmap_sequence_update_bitmap_next_frame()`` returns `false`:

```c
static void timer_handler(void *context) {
  uint32_t next_delay;

  // Advance to the next APNG frame, and get the delay for this frame
  if(gbitmap_sequence_update_bitmap_next_frame(s_sequence, s_bitmap, &next_delay)) {
    // Set the new frame into the BitmapLayer
    bitmap_layer_set_bitmap(s_bitmap_layer, s_bitmap);
    layer_mark_dirty(bitmap_layer_get_layer(s_bitmap_layer));

    // Timer for that frame's delay
    app_timer_register(next_delay, timer_handler, NULL);
  }
}
```

When appropriate, schedule the first frame advance with an ``AppTimer``:

```c
uint32_t first_delay_ms = 10;

// Schedule a timer to advance the first frame
app_timer_register(first_delay_ms, timer_handler, NULL);
```

When the app exits or the resource is no longer required, destroy the
``GBitmapSequence`` and the container ``GBitmap``:

```c
gbitmap_sequence_destroy(s_sequence);
gbitmap_destroy(s_bitmap);
```

## App Assets

This guide contains some resources available for developers to use in their apps
to improve consistency, as well as for convenience. For example, most
``ActionBarLayer`` implementations will require at least one of the common icons
given below.

## Pebble Timeline Pin Icons

Many timeline pin icons 
[are available](/assets/other/pebble-timeline-icons-pdc.zip) 
in Pebble Draw Command or PDC format (as described in 
) for use in watchfaces
and watchapps. These are useful in many kinds of generic apps.

## Example PDC icon SVG Files

Many of the system PDC animations are available for use in watchfaces and
watchapps as part of the 
[`pdc-sequence`](https://github.com/pebble-examples/pdc-sequence/tree/master/resources) 
example project.

## Example Action Bar Icons

There is a 
[set of example icons](https://s3.amazonaws.com/developer.getpebble.com/assets/other/actionbar-icons.zip) 
for developers to use for common actions. Each icon is shown below as a preview,
along with a short description about its suggested usage.

| Preview | Description |
|---------|-------------|
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_check.png) | Check mark for confirmation actions. |
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_dismiss.png) | Cross mark for dismiss, cancel, or decline actions. |
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_up.png) | Up arrow for navigating or scrolling upwards. |
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_down.png) | Down arrow for navigating or scrolling downwards. |
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_edit.png) | Pencil icon for edit actions. |
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_delete.png) | Trash can icon for delete actions. |
| ![](/images/guides/design-and-interaction/icons/action_bar_icon_snooze.png) | Stylized 'zzz' for snooze actions. |
| ![](/images/guides/design-and-interaction/icons/music_icon_ellipsis.png) | Ellipsis to suggest further information or actions are available. |
| ![](/images/guides/design-and-interaction/icons/music_icon_play.png) | Common icon for play actions. |
| ![](/images/guides/design-and-interaction/icons/music_icon_pause.png) | Common icon for pause actions. |
| ![](/images/guides/design-and-interaction/icons/music_icon_skip_forward.png) | Common icon for skip forward actions. |
| ![](/images/guides/design-and-interaction/icons/music_icon_skip_backward.png) | Common icon for skip backward actions. |
| ![](/images/guides/design-and-interaction/icons/music_icon_volume_up.png) | Common icon for raising volume. |
| ![](/images/guides/design-and-interaction/icons/music_icon_volume_down.png) | Common icon for lowering volume. |

## Converting SVG to PDC

[Pebble Draw Commands](``Draw Commands``) (PDC) are a powerful method of
creating vector images and icons that can be transformed and manipulated at
runtime. These can be used as a low-cost alternative to APNGs or bitmap
sequences. Currently the only simple way to create PDC files is to use the
[`svg2pdc.py`](https://github.com/pebble-examples/cards-example/blob/master/tools/svg2pdc.py)
tool. However, as noted in
[*Vector Animations*](/tutorials/advanced/vector-animations/#creating-compatible-files)
there are a some limitations to the nature of the input SVG file:

> The `svg2pdc` tool currently supports SVG files that use **only** the
> following elements: `g`, `layer`, `path`, `rect`, `polyline`, `polygon`,
> `line`, `circle`.

Fortunately, steps can be taken when creating SVG files in popular graphics
packages to avoid these limitations and ensure the output file is compatible
with `svg2pdc.py`. In this guide, we will be creating compatible PDC files using
an example SVG - this
[pencil icon](https://upload.wikimedia.org/wikipedia/commons/a/ac/Black_pencil.svg).

![pencil icon](/images/guides/pebble-apps/resources/pencil.svg =100x)

## Using Inkscape

* First, open the SVG in [Inkscape](https://inkscape.org/en/):

![inkscape-open](/images/guides/pebble-apps/resources/inkscape-open.png)

* Resize the viewport with *File*, *Document Properties*,
  *Page*, *Resize Page to Drawing*:

![inkscape-resize-page](/images/guides/pebble-apps/resources/inkscape-resize-page.png =350x)

* Select the layer, then resize the image to fit Pebble (50 x 50 pixels in this
  example) with *Object*, *Transform*:

![inkscape-resize-pebble](/images/guides/pebble-apps/resources/inkscape-resize-pebble.png)

* Now that the image has been resized, shrink the viewport again with *File*,
  *Document Properties*, *Page*, *Resize Page to Drawing*:

* Remove groupings with *Edit*, *Select All*, then *Object*, *Ungroup* until no
  groups remain:

![inkscape-ungroup](/images/guides/pebble-apps/resources/inkscape-ungroup.png)

* Disable relative move in *Object*, *Transform*. Hit *Apply*:

![inkscape-relative](/images/guides/pebble-apps/resources/inkscape-relative.png)

* Finally, save the image as a 'Plain SVG':

![inkscape-plain](/images/guides/pebble-apps/resources/inkscape-plain.png)

## Using Illustrator

* First, open the SVG in Illustrator:

![illustrator-open](/images/guides/pebble-apps/resources/illustrator-open.png)

* Resize the image to fit Pebble (50 x 50 pixels in this example) by entering in
  the desired values in the 'W' and 'H' fields of the *Transform* panel:

![illustrator-resize](/images/guides/pebble-apps/resources/illustrator-resize.png)

* Ungroup all items with *Select*, *All*, followed by *Object*, *Ungroup* until
  no groups remain:

![illustrator-ungroup](/images/guides/pebble-apps/resources/illustrator-ungroup.png)

* Shrink the image bounds with *Object*, *Artboards*, *Fit to Selected Art*:

![illustrator-fit](/images/guides/pebble-apps/resources/illustrator-fit.png)

* Save the SVG using *File*, *Save As* with the *SVG Tiny 1.1* profile and 1 decimal places:

![illustrator-settings](/images/guides/pebble-apps/resources/illustrator-settings.png =350x)

## Using the PDC Files

Once the compatible SVG files have been created, it's time to use `svg2pdc.py`
to convert into PDC resources, which will contain all the vector information
needed to draw the image in the correct Pebble binary format. The command is
shown below, with the Inkscape output SVG used as an example:

```nc|bash
$ python svg2pdc.py pencil-inkscape.svg  # Use python 2.x!
```

> If a coordinate value's precision value isn't supported, a warning will be
> printed and the nearest compatible value will be used instead:
>
> ```text
> Invalid point: (9.4, 44.5). Closest supported coordinate: (9.5, 44.5)
> ```

To use the PDC file in a Pebble project, read
[*Drawing a PDC Image*](/tutorials/advanced/vector-animations/#drawing-a-pdc-image).
The result should look near-identical on Pebble:

![svg-output >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/pebble-apps/resources/svg-output.png)

## Example Output

For reference, compatible output files are listed below:

* Inkscape: [SVG](/assets/other/pdc/pencil-inkscape.svg) | [PDC](/assets/other/pdc/pencil-inkscape.pdc)

* Illustrator: [SVG](/assets/other/pdc/pencil-illustrator.svg) | [PDC](/assets/other/pdc/pencil-illustrator.pdc)

## Fonts

## Using Fonts

Text drawn in a Pebble app can be drawn using a variety of built-in fonts or a
custom font specified as a project resource.

Custom font resources must be in the `.ttf` (TrueType font) format. When the app
is built, the font file is processed by the SDK according to the `compatibility`
(See [*Font Compatibility*](#font-compatibility)) and `characterRegex`
fields (see [*Choosing Font Characters*](#choosing-font-characters)), the latter
of which is a standard Python regex describing the character set of the
resulting font.

## System Fonts

All of the built-in system fonts are available to use with
``fonts_get_system_font()``. See  for
a complete list with sample images. Examples of using a built-in system font in
code are [shown below](#using-a-system-font).

### Limitations

There are limitations to the Bitham, Roboto, Droid and LECO fonts, owing to the
memory space available on Pebble, which only contain a subset of the default
character set.

* Roboto 49 Bold Subset - contains digits and a colon.
* Bitham 34/42 Medium Numbers - contain digits and a colon.
* Bitham 18/34 Light Subset - only contains a few characters and is not suitable
  for displaying general text.
* LECO Number sets - suitable for number-only usage.

## Using a System Font

Using a system font is the easiest choice when displaying simple text. For more
advanced cases, a custom font may be advantageous. A system font can be obtained
at any time, and the developer is not responsible for destroying it when they
are done with it. Fonts can be used in two modes:

```c
// Use a system font in a TextLayer
text_layer_set_font(s_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_24));
```

```c
// Use a system font when drawing text manually
graphics_draw_text(ctx, text, fonts_get_system_font(FONT_KEY_GOTHIC_24), bounds,
                     GTextOverflowModeWordWrap, GTextAlignmentCenter, NULL);
```

## Adding a Custom Font

After placing the font file in the project's `resources` directory, the custom
font can be added to a project as `font` `type` item in the `media` array in
`package.json`. The `name` field's contents will be made available at compile
time with `RESOURCE_ID_` at the front, and must end with the desired font size.
For example:

```js
"resources": {
  "media": [
    {
      "type": "font",
      "name": "EXAMPLE_FONT_20",
      "file": "example_font.ttf"
    }
  ]
}
```

The maximum recommended font size is 48.

## Using a Custom Font

Unlike a system font, a custom font must be loaded and unloaded by the
developer. Once this has been done, the font can easily be used in a similar
manner.

When the app initializes, load the font from resources using the generated
`RESOURCE_ID`:

```c
// Declare a file-scope variable
static GFont s_font;
```

```c
// Load the custom font
s_font = fonts_load_custom_font(
                          resource_get_handle(RESOURCE_ID_EXAMPLE_FONT_20));
```

The font can now be used in two modes - with a ``TextLayer``, or when drawing
text manually in a ``LayerUpdateProc``:

```c
// Use a custom font in a TextLayer
text_layer_set_font(s_text_layer, s_font);
```

```c
// Use a custom font when drawing text manually
graphics_draw_text(ctx, text, s_font, bounds, GTextOverflowModeWordWrap,
                                                  GTextAlignmentCenter, NULL);
```

## Font Compatibility

The font rendering process was improved in SDK 2.8. However, in some cases this
may cause the appearance of custom fonts to change slightly. To revert to the
old rendering process, add `"compatibility": "2.7"` to your font's object in the
`media` array (shown above) in `package.json`.

## Choosing Font Characters

By default, the maximum number of supported characters is generated for a font
resource. In most cases this will be far too many, and can bloat the size of the
app. To optimize the size of your font resources you can use a standard regular
expression (or 'regex') string to limit the number of characters to only those
you require.

The table below outlines some example regular expressions to use for limiting
font character sets in common watchapp scenarios:

| Expression | Result |
|------------|--------|
| `[ -~]` | ASCII characters only. |
| `[0-9]` | Numbers only. |
| `[0-9 ]` | Numbers and spaces only. |
| `[a-zA-Z]` | Letters only. |
| `[a-zA-Z ]` | Letters and spaces only. |
| `[0-9:APM ]` | Time strings only (e.g.: "12:45 AM"). |
| `[0-9:A-Za-z ]` | Time and date strings (e.g.: "12:43 AM Wednesday 3rd March 2015". |
| `[0-9:A-Za-z° ]` | Time, date, and degree symbol for temperature gauges. |
| `[0-9°CF ]` | Numbers and degree symbol with 'C' and 'F' for temperature gauges. |

Add the `characterRegex` key to any font objects in `package.json`'s
`media` array.

```js
"media": [
  {
    "characterRegex": "[:0-9]",
    "type": "font",
    "name": "EXAMPLE_FONT",
    "file": "example_font.ttf"
  }
]
```

Check out
[regular-expressions.info](http://www.regular-expressions.info/tutorial.html)
to learn more about how to use regular expressions.

## Images

Images can be displayed in a Pebble app by adding them as a project resource.
They are stored in memory as a ``GBitmap`` while the app is running, and can be
displayed either in a ``BitmapLayer`` or by using
``graphics_draw_bitmap_in_rect()``.

## Creating an Image

In order to be compatible with Pebble, the image should be saved as a PNG file,
ideally in a palettized format (see below for palette files) with the
appropriate number of colors. The number of colors available on each platform is
shown below:

| Platform | Number of Colors |
|----------|------------------|
| Aplite | 2 (black and white) |
| Basalt | 64 colors |
| Chalk | 64 colors |
| Diorite | 2 (black and white) |
| Emery | 64 colors |
| Flint | 2 (black and white) |

## Color Palettes

Palette files for popular graphics packages that contain the 64 supported colors
are available below. Use these when creating color image resources:

* [Photoshop `.act`](/assets/other/pebble_colors_64.act)

* [Aseprite (raw colors, for watch displays) `.aseprite`](/assets/other/pebble_colors_uncorrected.aseprite)
* [Aseprite (Sunlight, color-corrected for HD displays) `.aseprite`](/assets/other/pebble_colors_sunlight.aseprite)

* [Illustrator `.ai`](/assets/other/pebble_colors_64.ai)

* [GIMP `.pal`](/assets/other/pebble_colors_64.pal)

* [ImageMagick `.gif`](/assets/other/pebble_colors_64.gif)

## Import the Image

After placing the image in the project's `resources` directory, add an entry to
the `resources` item in `package.json`. Specify the `type` as `bitmap`, choose a
`name` (to be used in code) and supply the path relative to the project's
`resources` directory. Below is an example:

```js
"resources": {
  "media": [
    {
      "type": "bitmap",
      "name": "EXAMPLE_IMAGE",
      "file": "background.png"
    }
  ]
},
```

## Specifying an Image Resource

Image resources are used in a Pebble project when they are listed using the
`bitmap` resource type.

Resources of this type can be optimized using additional attributes:

| Attribute | Description | Values |
|-----------|-------------|--------|
| `memoryFormat` | Optional. Determines the bitmap type. Reflects values in the `GBitmapFormat` `enum`. | `Smallest`, `SmallestPalette`, `1Bit`, `8Bit`, `1BitPalette`, `2BitPalette`, or `4BitPalette`. |
| `storageFormat` | Optional. Determines the file format used for storage. Using `spaceOptimization` instead is preferred. | `pbi` or `png`. |
| `spaceOptimization` | Optional. Determines whether the output resource is optimized for low runtime memory or low resource space usage. | `storage` or `memory`. |

An example usage of these attributes in `package.json` is shown below:

```js
{
  "type": "bitmap",
  "name": "IMAGE_EXAMPLE",
  "file": "images/example_image.png"
  "memoryFormat": "Smallest",
  "spaceOptimization": "memory"
}
```

On all platforms `memoryFormat` will default to `Smallest`. On Aplite
`spaceOptimization` will default to `memory`, and `storage` on all other
platforms.

> If you specify a combination of attributes that is not supported, such as a
> `1Bit` unpalettized PNG, the build will fail. Palettized 1-bit PNGs are
> supported.

When compared to using image resources in previous SDK versions:

* `png` is equivalent to `bitmap` with no additional specifiers.

* `pbi` is equivalent to `bitmap` with `"memoryFormat": "1Bit"`.

* `pbi8` is equivalent to `bitmap` with `"memoryFormat": "8Bit"` and
  `"storageFormat": "pbi"`.

Continuing to use the `png` resource type will result in a `bitmap` resource
with `"storageFormat": "png"`, which is not optimized for memory usage on the
Aplite platform due to less memory available in total, and is not encouraged.

## Specifying Resources Per Platform

To save resource space, it is possible to include only certain image resources
when building an app for specific platforms. For example, this is useful for the
Aplite platform, which requires only black and white versions of images, which
can be significantly smaller in size. Resources can also be selected according
to platform and display shape.

Read  to learn more about how to
do this.

## Displaying an Image

Declare a ``GBitmap`` pointer. This will be the object type the image data is
stored in while the app is running:

```c
static GBitmap *s_bitmap;
```

Create the ``GBitmap``, specifying the `name` chosen earlier, prefixed with
`RESOURCE_ID_`. This will manage the image data:

```c
s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);
```

Declare a ``BitmapLayer`` pointer:

```c
static BitmapLayer *s_bitmap_layer;
```

Create the ``BitmapLayer`` and set it to show the ``GBitmap``. Make sure to
supply the correct width and height of your image in the ``GRect``, as well as
using ``GCompOpSet`` to ensure color transparency is correctly applied:

```c
s_bitmap_layer = bitmap_layer_create(GRect(5, 5, 48, 48));
bitmap_layer_set_compositing_mode(s_bitmap_layer, GCompOpSet);
bitmap_layer_set_bitmap(s_bitmap_layer, s_bitmap);
```

Add the ``BitmapLayer`` as a child layer to the ``Window``:

```c
layer_add_child(window_get_root_layer(window), 
                                      bitmap_layer_get_layer(s_bitmap_layer));
```

Destroy both the ``GBitmap`` and ``BitmapLayer`` when the app exits:

```c
gbitmap_destroy(s_bitmap);
bitmap_layer_destroy(s_bitmap_layer);
```

## Menu Icon in the Launcher

The new launcher in firmware 4.0+ allows developers to provide a custom icon for
their watchapps and watchfaces.

<div class="pebble-dual-image">
  <div class="panel">
  
  ![Launcher Icon](/images/blog/2016-08-19-pikachu-icon.png)
  
  </div>
  <div class="panel">
  
  ![Launcher >{pebble-screenshot,pebble-screenshot--time-red}](/images/blog/2016-08-19-pikachu-launcher.png)
  
  </div>
</div>

You can add a 25x25 `png` to the `resources.media` section of the`package.json`
file, and set `"menuIcon": true`. Please note that icons that are larger will be
rejected by the SDK.

```js
"resources": {
  "media": [
    {
      "type": "bitmap",
      "name": "MENU_ICON",
      "file": "images/icon.png",
      "menuIcon": true
    }
  ]
}
```

If your `png` file is color, we will use the luminance of the image to add some
subtle gray when rendering it in the launcher, rather than just black and white.
Transparency will be preserved.

The app icons specified during submission to the appstore are independent of
this image resource (used in other places such as the mobile app and the
appstore) - the `menuIcon` specified will always be used in the watch
launcher list.

## Pebble Draw Command File Format

Pebble [`Draw Commands`](``Draw Commands``) (PDCs) are vector image files that
consist of a binary resource containing the instructions for each stroke, fill,
etc. that makes up the image. The byte format of all these components are
described in tabular form below.

> **Important**: All fields are in the little-endian format!

An example implementation with some
[usage limitations](/tutorials/advanced/vector-animations#creating-compatible-files)
can be seen in
[`svg2pdc.py`](/cards-example/blob/master/tools/svg2pdc.py).

## Component Types

A PDC binary file consists of the following key components, in ascending order
of abstraction:

* [Draw Command](#pebble-draw-command) - an instruction for a single line or
  path to be drawn.

* [Draw Command List](#pebble-draw-command-list) - a set of Draw Commands that
  make up a shape.

* [Draw Command Frame](#pebble-draw-command-frame) - a Draw Command List with
  configurable duration making up one animation frame. Many of these are used in
  a Draw Command Sequence.

* [Draw Command Image](#pebble-draw-command-image) - A single vector image.

* [Draw Command Sequence](#pebble-draw-command-sequence) - A set of Draw Command
  Frames that make up an animated sequence of vector images.

## Versions

| PDC Format Version | Implemented |
|--------------------|-------------|
| 1 | Firmware 3.0 |

## File Format Components

### Point

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| X | 0 | 2 | X axis coordinate. Has one of two formats depending on the Draw Command type (see below):<br/><br>Path/Circle type: signed integer. <br/>Precise path type: 13.3 fixed point. |
| Y | 2 | 2 | Y axis coordinate. Has one of two formats depending on the Draw Command type (see below):<br/><br>Path/Circle type: signed integer. <br/>Precise path type: 13.3 fixed point. |

### View Box

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Width | 0 | 2 | Width of the view box (signed integer). |
| Height | 2 | 2 | Height of the view box (signed integer). |

### Pebble Draw Command

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Type | 0 | 1 | Draw command type. Possible values are: <br/><br/>`0` - Invalid <br/>`1` - Path<br/>`2` - Circle<br/>`3` - Precise path |
| Flags | 1 | 1 | Bit 0: Hidden (Draw Command should not be drawn). <br/> Bits 1-7: Reserved. |
| Stroke color | 2 | 1 | Pebble color (integer). |
| Stroke width | 3 | 1 | Stroke width (unsigned integer). |
| Fill color | 4 | 1 | Pebble color (integer). |
| Path open/radius | 5 | 2 | Path/Precise path type: Bit 0 indicates whether or not the path is drawn open (`1`) or closed (`0`).<br/>Circle type: radius of the circle. |
| Number of points | 7 | 2 | Number of points (n) in the point array. See below. |
| Point array | 9 | n x 4 | The number of points (n) points. |

### Pebble Draw Command List

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Number of commands | 0 | 2 | Number of Draw Commands in this Draw Command List. (`0` is invalid). |
| Draw Command array | 2 | n x size of Draw Command  | List of Draw Commands in the format [specified above](#pebble-draw-command). |

### Pebble Draw Command Frame

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Duration | 0 | 2 | Duration of the frame in milliseconds. If `0`, the frame will not be shown at all (unless it is the last frame in a sequence). |
| Command list | 2 | Size of Draw Command List | Pebble Draw Command List in the format [specified above](#pebble-draw-command-list). |

### Pebble Draw Command Image

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Version | 8 | 1 | File version. |
| Reserved | 9 | 1 | Reserved field. Must be `0`. |
| [View box](#view-box) | 10 | 4 | Bounding box of the image. All Draw Commands are drawn relative to the top left corner of the view box. |
| Command list | 14 | Size of Draw Command List | Pebble Draw Command List in the format [specified above](#pebble-draw-command-list). |

### Pebble Draw Command Sequence

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Version | 8 | 1 | File version. |
| Reserved | 9 | 1 | Reserved field. Must be `0`. |
| [View box](#view-box) | 10 | 4 | Bounding box of the sequence. All Draw Commands are drawn relative to the top left corner of the view box. |
| Play count | 14 | 2 | Number of times to repeat the sequence. A value of `0` will result in no playback at all, whereas a value of `0xFFFF` will repeat indefinitely. |
| Frame count | 16 | 2 | Number of frames in the sequence. `0` is invalid. |
| Frame list | 18 | n x size of Draw Command Frame | Array of Draw Command Frames in the format [specified above](#pebble-draw-command-frame). |

## File Formats

### Pebble Draw Command Image File

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Magic word | 0 | 4 | ASCII characters spelling "PDCI". |
| Image size | 4 | 4 | Size of the Pebble Draw Command Image (in bytes). |
| Image | 8 | Size of Pebble Draw Command Image. | The Draw Command Image in the format [specified above](#pebble-draw-command-image). |

### Pebble Draw Command Sequence File

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Magic word | 0 | 4 | ASCII characters spelling "PDCS". |
| Sequence size | 4 | 4 | Size of the Pebble Draw Command Sequence (in bytes). |
| Sequence | 8 | Size of Draw Command Sequence | The Draw Command Sequence in the format [specified above](#pebble-draw-command-sequence). |

## Platform-specific Resources

You may want to use different versions of a resource on one or more of the
Aplite, Basalt or Chalk platforms. To enable this, it is now possible to
"tag" resource files with the attributes that make them relevant to a given
platform.

The follows tags exist for each platform:

| Aplite  | Basalt     | Chalk      | Diorite | Emery      | Flint   |
|---------|------------|------------|---------|------------|---------|
| rect    | rect       | round      | rect    | rect       | rect    |
| bw      | color      | color      | bw      | color      | bw      |
| aplite  | basalt     | chalk      | diorite | emery      | flint   |
| 144w    | 144w       | 180w       | 144w    | 200w       | 144w    |
| 168h    | 168h       | 180h       | 168h    | 228h       | 168h    |
| compass | compass    | compass    |         | compass    | compass |
|         | mic        | mic        | mic     | mic        | mic     |
|         | strap      | strap      | strap   | strap      |         |
|         | strappower | strappower |         | strappower |         |
|         | health     | health     | health  | health     | health  |

To tag a resource, add the tags after the file's using tildes (`~`) — for
instance, `example-image~color.png` to use the resource on only color platforms,
or `example-image~color~round.png` to use the resource on only platforms with
round, color displays. All tags must match for the file to be used. If no file
matches for a platform, a compilation error will occur.

If the correct file for a platform is ambiguous, an error will occur at
compile time. You cannot, for instance, have both `example~color.png` and
`example~round.png`, because it is unclear which image to use when building
for Chalk. Instead, use `example~color~rect.png` and `example~round.png`. If
multiple images could match, the one with the most tags wins.

We recommend avoiding the platform specific tags (aplite, basalt etc). When we
release new platforms in the future, you will need to create new files for that
platform. However, if you use the descriptive tags we will automatically use
them as appropriate. It is also worth noting that the platform tags are _not_
special: if you have `example~basalt.png` and `example~rect.png`, that is
ambiguous (they both match Basalt) and will cause a compilation error.

An example file structure is shown below.

```text
my-project/
  resources/
    images/
      example-image~bw.png
      example-image~color~rect.png
      example-image~color~round.png
  src/
    main.c
  package.json
  wscript
```

This resource will appear in `package.json` as shown below.

```
"resources": {
  "media": [
    {
      "type": "bitmap",
      "name": "EXAMPLE_IMAGE",
      "file": "images/example-image.png"
    }
  ]
}
```

**Single-platform Resources**

If you want to only include a resource on a **specific** platform, you can add a
`targetPlatforms` field to the resource's entry in the `media` array in
`package.json`. For example, the resource shown below will only be included for
the Basalt build.

```
"resources": {
  "media": [
    {
      "type": "bitmap",
      "name": "BACKGROUND_IMAGE",
      "file": "images/background.png",
      "targetPlatforms": [
        "basalt"
      ]
    }
  ]
}
```

## Raw Data Files

Some kinds of apps will require extra data that is not a font or an image. In
these cases, the file can be included in a Pebble project as a raw resource.
When a file is included as a raw resource, it is not modified in any way from
the original when the app is built.

Applications of this resource type can be found in the Pebble SDK for APIs
such as ``GDrawCommand`` and ``GBitmapSequence``, which both use raw resources
as input files. Other possible applications include localized string
dictionaries, CSV data files, etc.

## Adding Raw Data Files

To add a file as a raw resource, specify its `type` as `raw` in `package.json`.
An example is shown below:

```js
"resources": {
  "media": [
    {
      "type": "raw",
      "name": "EXAMPLE_DATA_FILE",
      "file": "data.bin"
    }
  ]
}
```

## Reading Bytes and Byte Ranges

Once a raw resource has been added to a project, it can be loaded at runtime in
a manner similar to other resources types:

```c
// Get resource handle
ResHandle handle = resource_get_handle(RESOURCE_ID_DATA);
```

With a handle to the resource now available in the app, the size of the resource
can be determined:

```c
// Get size of the resource in bytes
size_t res_size = resource_size(handle);
```

To read bytes from the resource, create an appropriate byte buffer and copy data
into it:

```c
// Create a buffer the exact size of the raw resource
uint8_t *s_buffer = (uint8_t*)malloc(res_size);
```

The example below copies the entire resource into a `uint8_t` buffer:

```c
// Copy all bytes to a buffer
resource_load(handle, s_buffer, res_size);
```

It is also possible to read a specific range of bytes from a given offset into
the buffer:

```c
// Read the second set of 8 bytes
resource_load_byte_range(handle, 8, s_buffer, 8);
```

## System Fonts

The tables below show all the system font identifiers available in the Pebble
SDK, sorted by family. A sample of each is also shown.

## Available System Fonts

### Raster Gothic

<table>
  <thead>
    <th>Available Font Keys</th>
    <th>Preview</th>
  </thead>
  <tbody>
    <tr>
      <td><code>FONT_KEY_GOTHIC_14</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_14_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_14_BOLD</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_14_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_18</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_18_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_18_BOLD</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_18_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_24</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_24_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_24_BOLD</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_24_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_28</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_28_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_GOTHIC_28_BOLD</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/gothic_28_bold_preview.png"/></td>
    </tr>
  </tbody>
</table>

### Bitham

<table>
  <thead>
    <th>Available Font Keys</th>
    <th>Preview</th>
  </thead>
  <tbody>
    <tr>
      <td><code>FONT_KEY_BITHAM_30_BLACK</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/bitham_30_black_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_BITHAM_34_MEDIUM_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/bitham_34_medium_numbers_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_BITHAM_42_BOLD</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/bitham_42_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_BITHAM_42_LIGHT</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/bitham_42_light_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_BITHAM_42_MEDIUM_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/bitham_42_medium_numbers_preview.png"/></td>
    </tr>
  </tbody>
</table>

### Roboto/Droid Serif

<table>
  <thead>
    <th>Available Font Keys</th>
    <th>Preview</th>
  </thead>
  <tbody>
    <tr>
      <td><code>FONT_KEY_ROBOTO_CONDENSED_21</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/roboto_21_condensed_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_ROBOTO_BOLD_SUBSET_49</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/roboto_49_bold_subset_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_DROID_SERIF_28_BOLD</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/droid_28_bold_preview.png"/></td>
    </tr>
  </tbody>
</table>

### LECO

<table>
  <thead>
    <th>Available Font Keys</th>
    <th>Preview</th>
  </thead>
  <tbody>
    <tr>
      <td><code>FONT_KEY_LECO_20_BOLD_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_20_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_LECO_26_BOLD_NUMBERS_AM_PM</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_26_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_LECO_28_LIGHT_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_28_light_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_LECO_32_BOLD_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_32_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_LECO_36_BOLD_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_36_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_LECO_38_BOLD_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_38_bold_preview.png"/></td>
    </tr><tr>
      <td><code>FONT_KEY_LECO_42_NUMBERS</code></td>
      <td><img src="/assets/images/guides/app-resources/fonts/leco_42_preview.png"/></td>
    </tr>
  </tbody>
</table>

## Obtaining System Font Files

The following system fonts are available to developers in the SDK can be found
online for use in design mockups:

* [Raster Gothic](http://www.marksimonson.com/) - By Mark Simonson

* [Gotham (Bitham)](http://www.typography.com/fonts/gotham/overview/) -
  Available from Typography.com

* [Droid Serif](https://www.google.com/fonts/specimen/Droid+Serif) - Available
  from Google Fonts

* [LECO 1976](https://www.myfonts.com/fonts/carnoky/leco-1976/) - Available from
  Myfonts.com

## Using Emoji Fonts

A subset of the built-in system fonts support the use of a set of emoji
characters. These are the Gothic 24, Gothic 24 Bold, Gothic 18, and Gothic 18
Bold fonts, but do not include the full range.

To print an emoji on Pebble, specify the code in a character string like the one
shown below when using a ``TextLayer``, or ``graphics_draw_text()``:

```c
text_layer_set_text(s_layer, "Smiley face: \U0001F603");
```

An app containing a ``TextLayer`` displaying the above string will look similar
to this:

![emoji-screenshot >{pebble-screenshot,pebble-screenshot--steel-black}](/images/guides/pebble-apps/resources/emoji-screenshot.png)

The supported characters are displayed below with their corresponding unicode
values.

<img style="align: center;" src="/assets/images/guides/pebble-apps/resources/emoji1.png"/>

### Deprecated Emoji Symbols

The following emoji characters are no longer available on the Aplite platform.

<img style="align: center;" src="/assets/images/guides/pebble-apps/resources/emoji-unsupported.png"/>

## App Resources

The Pebble SDK allows apps to include extra files as app resources. These files
can include images, animated images, vector images, custom fonts, and raw data
files. These resources are stored in flash memory and loaded when required by
the SDK. Apps that use a large number of resources should consider only keeping
in memory those that are immediately required.

The maximum number of resources an app can include is **256**. In addition, the
maximum size of all resources bundled into a built app is **128 kB** on the
Aplite platform, and **256 kB** on the Basalt and Chalk platforms. These limits
include resources used by included Pebble Packages.

App resources are included in a project by being listed in the `media` property
of `package.json`, and are converted into suitable firmware-compatible formats
at build time. Examples of this are shown in each type of resource's respective
guide.

## Contents

