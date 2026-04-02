# Migration

> Details on how to update older apps affected by API changes.

## SDK 3.x on Aplite Migration Guide

With the release of SDK 3.8, all Pebble platforms can be targeted with one SDK.
This enables developers to make use of lots of new APIs added since SDK 2.9, as
well as the countless bug fixes and improvements also added in the intervening
time. Some examples are:

* Timezone support

* Sequence and spawn animations

* Pebble timeline support

* Pebble Draw Commands

* Native PNG image support

* 8k `AppMessage` buffers

* New UI components such as `ActionMenu`, `StatusBarLayer`, and
  `ContentIndicator`.

* The stroke width, drawing arcs, polar points APIs, and the color gray!

## Get the Beta SDK

To try out the beta SDK, read the instructions on the [SDK Beta](/sdk/beta)
page.

## Mandatory Changes

To be compatible with users who update their Pebble Classic or Pebble Steel to
firmware 3.x the following important changes **MUST** be made:

* If you are adding support for Aplite, add `aplite` to your `targetPlatforms`
  array in `package.json`.

* Recompile your app with at least Pebble SDK 3.8 (coming soon!). The 3.x on
  Aplite files will reside in `/aplite/` instead of the `.pbw` root folder.
  Frankenpbws are **not** encouraged - a 2.x compatible release can be uploaded
  separately (see [*Appstore Changes*](#appstore-changes)).

* Update any old practices such as direct struct member access. An example is
  shown below:

    ```c
    // 2.x - don't do this!
    GRect bitmap_bounds = s_bitmap->bounds;

    // 3.x - please do this!
    GRect bitmap_bounds = gbitmap_get_bounds(s_bitmap);
    ```

* Apps that make use of the `png-trans` resource type should now make use of
  built-in PNG support, which allows a single black and white image with
  transparency to be used in place of the older compositing technique.

* If your app uses either the ``Dictation`` or ``Smartstrap`` APIs, you must
  check that any code dependant on these hardware features fails gracefully when
  they are not available. This should be done by checking for `NULL` or
  appropriate `enum` values returned from affected API calls. An example is
  shown below:

    ```c
    if(smartstrap_subscribe(handlers) != SmartstrapResultNotPresent) {
      // OK to use Smartstrap API!
    } else {
      // Not available, handle gracefully
      text_layer_set_text(s_text_layer, "Smartstrap not available!");
    }

    DictationSession *session = dictation_session_create(size, callback, context);
    if(session) {
      // OK to use Dictation API!
    } else {
      // Not available, handle gracefully
      text_layer_set_text(s_text_layer, "Dictation not available!");
    }
    ```

## Appstore Changes

To handle the transition as users update their Aplite to firmware 3.x (or choose
not to), the appstore will include the following changes:

* You can now have multiple published releases. When you publish a new release,
  it doesn’t unpublish the previous one. You can still manually unpublish
  releases whenever they want.

* The appstore will provide the most recently compatible release of an app to
  users. This means that if you publish a new release that has 3.x Aplite
  support, the newest published release that supports 2.x Aplite will be
  provided to users on 2.x Aplite.

* There will be a fourth Asset Collection type that you can create: Legacy
  Aplite. Apps that have different UI designs between 2.x and 3.x on Aplite
  should use the Legacy Aplite asset collection for their 2.x assets.

## Suggested Changes

To fully migrate to SDK 3.x, we also suggest you make these nonessential
changes:

* Remove any code conditionally compiled with `PBL_SDK_2` defines. It will no
  longer be compiled at all.

* Ensure that any use of ``app_message_inbox_size_maximum()`` and
  ``app_message_outbox_size_maximum()`` does not cause your app to run out of
  memory. These calls now create ``AppMessage`` buffers of 8k size by default.
  Aplite apps limited to 24k of RAM will quickly run out if they use much more
  memory.

* Colors not available on the black and white Aplite display will be silently
  displayed as the closet match (black, or white). We recommend checking every
  instance of a `GColor`to ensure each is the correct one. `GColorDarkGray` and
  `GColorLightGray` will result in a 50/50 dithered gray for **fill**
  operations. All other line and text drawing will be mapped to the nearest
  solid color (black or white).

* Apps using image resources should take advantage of the new `bitmap` resource
  type, which optimizes image files for you. Read the
  [*Unifying Bitmap Resources*](/blog/2015/12/02/Bitmap-Resources/)
  blog post to learn more.

* In addition to the point above, investigate how the contrast and readability
  of your app can be improved by making use of gray. Examples of this can be
  seen in the system UI:

![3x-aplite-system >{pebble-screenshot,pebble-screenshot--black}](/images/guides/migration/3x-aplite-system.png)

## SDK 3.x Migration Guide

This guide provides a detailed list of the changes to existing APIs in Pebble
SDK 3.x. To migrate an older app's code successfully from Pebble SDK 2.x to
Pebble SDK 3.x, consider the information outlined here and make the necessary
changes if the app uses a changed API.

The number of breaking changes in SDK 3.x for existing apps has been minimized
as much as possible. This means that:

* Apps built with SDK 2.x **will continue to run on firmware 3.x without any
  recompilation needed**.

* Apps built with SDK 3.x will generate a `.pbw` file that will run on firmware
  3.x.

## Backwards Compatibility

Developers can easily modify an existing app (or create a new one) to be
compilable for both Pebble/Pebble Steel as well as Pebble Time, Pebble Time
Steel, and Pebble Time Round by using `#ifdef` and various defines that are made
available by the SDK at build time. For example, to check that the app will run
on hardware supporting color:

```c
#ifdef PBL_COLOR
  window_set_background_color(s_main_window, GColorDukeBlue);
#else
  window_set_background_color(s_main_window, GColorBlack);
#endif
```

When the app is compiled, it will be built once for each platform with
`PBL_COLOR` defined as is appropriate. By catering for all cases, apps will run
and look good on both platforms with minimal effort. This avoids the need to
maintain two Pebble projects for one app.

In addition, as of Pebble SDK 3.6 there are macros that can be used to
selectively include code in single statements. This is an alternative to the
approach shown above using `#ifdef`:

```c
window_set_background_color(s_main_window,
                            PBL_IF_COLOR_ELSE(GColorDukeBlue, GColorBlack));
```

See 

to learn more about these macros, as well as see a complete list.

## PebbleKit Considerations

Apps that use PebbleKit Android will need to be re-compiled in Android Studio
(or similar) with the PebbleKit Android **3.x** (see 
)
library in order to be compatible with the Pebble Time mobile application.
No code changes are required, however.

PebbleKit iOS developers remain unaffected and their apps will continue to run
with the new Pebble mobile application. However, iOS companion apps will need to
be recompiled with PebbleKit iOS **3.x** (see 
) 
to work with Pebble Time Round.

## Changes to appinfo.json

There is a new field for tracking which version of the SDK the app is built for.
For example, when using 3.x SDK add this line to the project's `appinfo.json`.

```
"sdkVersion": "3"
```

Apps will specify which hardware platforms they support (and wish to be built
for) by declaring them in the `targetPlatforms` field of the project's
`appinfo.json` file.

```
"targetPlatforms": [
  "aplite",
  "basalt",
  "chalk"
]
```

For each platform listed here, the SDK will generate an appropriate binary and
resource pack that will be included in the `.pbw` file. This means that the app
is actually compiled and resources are optimized once for each platform. The
image below summarizes this build process:

![build process](/images/sdk/build-process-3.png)

> Note: If `targetPlatforms` is not specified in `appinfo.json` the app will be
> compiled for all platforms. 

Apps can also elect to not appear in the app menu on the watch (if is is only
pushing timeline pins, for example) by setting `hiddenApp`:

```
"watchapp": {
  "watchface": false,
  "hiddenApp": true
},
```

## Project Resource Processing

SDK 3.x enhances the options for adding image resources to a Pebble project,
including performing some pre-processing of images into compatible formats prior
to bundling. For more details on the available resource types, check out the 
 section of the guides.

## Platform-specific Resources

**Different Resources per Platform**

It is possible to include different versions of resources on only one of the
platforms with a specific type of display. Do this by appending `~bw` or
`~color` to the name of the resource file and the SDK will prefer that file over
another with the same name, but lacking the suffix.

This means is it possible to can include a smaller black and white version of an
image by naming it `example-image~bw.png`, which will be included in the
appropriate build over another file named `example-image.png`. In a similar
manner, specify a resource for a color platform by appending `~color` to the
file name.

An example file structure is shown below.

```text
my-project/
  resources/
    images/
      example-image~bw.png
      example-image~color.png
  src/
    main.c
  appinfo.json
  wscript
```

This resource will appear in `appinfo.json` as shown below.

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

Read  for more information about
specifying resources per-platform.

**Single-platform Resources**

To only include a resource on a **specific** platform, add a `targetPlatforms`
field to the resource's entry in the `media` array in `appinfo.json`. For
example, the resource shown below will only be included for the Basalt build.

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

## Changes to wscript

To support compilation for multiple hardware platforms and capabilities, the
default `wscript` file included in every Pebble project has been updated.

If a project uses a customized `wscript` file and `pebble convert-project` is
run (which will fully replace the file with a new compatible version), the
`wscript` will be copied to `wscript.backup`.

View 
[this GitHub gist](https://gist.github.com/pebble-gists/72a1a7c85980816e7f9b)
to see a sample of what the new format looks like, and re-add any customizations
afterwards.

## Changes to Timezones

With SDK 2.x, all time-related SDK functions returned values in local time, with
no concept of timezones. With SDK 3.x, the watch is aware of the user's timezone
(specified in Settings), and will return values adjusted for this value.

## API Changes Quick Reference

### Compatibility Macros

Since SDK 3.0-dp2, `pebble.h` includes compatibility macros enabling developers
to use the new APIs to access fields of opaque structures and still be
compatible with both platforms. An example is shown below:

```c
static GBitmap *s_bitmap;
```

```c
// SDK 2.9
GRect bounds = s_bitmap->bounds;

// SDK 3.x
GRect bounds = gbitmap_get_bounds(s_bitmap);
```

### Comparing Colors

Instead of comparing two GColor values directly, use the new ``gcolor_equal``
function to check for identical colors.

```c
GColor a, b;

// SDK 2.x, bad
if (a == b) { }

// SDK 3.x, good
if (gcolor_equal(a, b)) { }
```

> Note: Two colors with an alpha transparency(`.a`) component equal to `0`
> (completely transparent) are considered as equal.

### Assigning Colors From Integers

Specify a color previously stored as an `int` and convert it to a
`GColor`:

```c
GColor a;

// SDK 2.x
a = (GColor)persist_read_int(key);

// SDK 3.x
a.argb = persist_read_int(key);

/* OR */

a = (GColor){.argb = persist_read_int(key)};
```

### Specifying Black and White

The internal representation of SDK 2.x colors such as ``GColorBlack`` and
``GColorWhite`` have changed, but they can still be used with the same name.

### PebbleKit JS Account Token

In SDK 3.0 the behavior of `Pebble.getAccountToken()` changes slightly. In
previous versions, the token returned on Android could differ from that returned
on iOS by dropping some zero characters. The table below shows the different
tokens received for a single user across platforms and versions:

| Platform | Token |
|:---------|-------|
| iOS 2.6.5 | 29f00dd7872ada4bd14b90e5d49568a8 |
| iOS 3.x | 29f00dd7872ada4bd14b90e5d49568a8 |
| Android 2.3 | 29f0dd7872ada4bd14b90e5d49568a8 |
| Android 3.x | 29f00dd7872ada4bd14b90e5d49568a8 |

> Note: This process should **only** be applied to new tokens obtained from
> Android platforms, to compare to tokens from older app versions.

To account for this difference, developers should adapt the new account token as
shown below.

**JavaScript**

```js
function newToOld(token) {
  return token.split('').map(function (x, i) {
    return (x !== '0' || i % 2 == 1) ? x : '';
  }).join('');
}
```

**Python**

```python
def new_to_old(token):
    return ''.join(x for i, x in enumerate(token) if x != '0' or i % 2 == 1)
```

**Ruby**

```ruby
def new_to_old(token)
  token.split('').select.with_index { |c, i| (c != '0' or i % 2 == 1) }.join('')
end
```

**PHP**

<div>

function newToOld($token) {
    $array = str_split($token);
    return implode('', array_map(function($char, $i) {
        return ($char !== '0' || $i % 2 == 1) ? $char : '';
    }, $array, array_keys($array)));
}

</div>

### Using the Status Bar

To help apps integrate aesthetically with the new system experience, all
``Window``s are now fullscreen-only in SDK 3.x. To keep the time-telling
functionality, developers should use the new ``StatusBarLayer`` API in their
`.load` handler.

> Note: Apps built with SDK 2.x will still keep the system status bar unless
> specified otherwise with `window_set_fullscreen(window, true)`. As a result,
> such apps that have been recompiled will be shifted up sixteen pixels, and
> should account for this in any window layouts.

```c
static StatusBarLayer *s_status_bar;
```

```c
static void main_window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);

  /* other UI code */

  // Set up the status bar last to ensure it is on top of other Layers
  s_status_bar = status_bar_layer_create();
  layer_add_child(window_layer, status_bar_layer_get_layer(s_status_bar));
}
```

By default, the status bar will look the same as it did on 2.x, minus the
battery meter.

![status-bar-default >{pebble-screenshot,pebble-screenshot--time-red}](/images/sdk/status-bar-default.png)

To display the legacy battery meter on the Basalt platform, simply add an
additional ``Layer`` after the ``StatusBarLayer``, and use the following code in
its ``LayerUpdateProc``.

```c
static void battery_proc(Layer *layer, GContext *ctx) {
  // Emulator battery meter on Aplite
  graphics_context_set_stroke_color(ctx, GColorWhite);
  graphics_draw_rect(ctx, GRect(126, 4, 14, 8));
  graphics_draw_line(ctx, GPoint(140, 6), GPoint(140, 9));

  BatteryChargeState state = battery_state_service_peek();
  int width = (int)(float)(((float)state.charge_percent / 100.0F) * 10.0F);
  graphics_context_set_fill_color(ctx, GColorWhite);
  graphics_fill_rect(ctx, GRect(128, 6, width, 4), 0, GCornerNone);
}
```

```c
static void main_window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  /* other UI code */

  // Set up the status bar last to ensure it is on top of other Layers
  s_status_bar = status_bar_layer_create();
  layer_add_child(window_layer, status_bar_layer_get_layer(s_status_bar));

  // Show legacy battery meter
  s_battery_layer = layer_create(GRect(bounds.origin.x, bounds.origin.y, 
                                      bounds.size.w, STATUS_BAR_LAYER_HEIGHT));
  layer_set_update_proc(s_battery_layer, battery_proc);
  layer_add_child(window_layer, s_battery_layer);
}
```

> Note: To update the battery meter more frequently, use ``layer_mark_dirty()``
> in a ``BatteryStateService`` subscription. Unless the current ``Window`` is
> long-running, this should not be neccessary.

The ``StatusBarLayer`` can also be extended by the developer in similar ways to
the above. The API also allows setting the layer's separator mode and
foreground/background colors:

```c
status_bar_layer_set_separator_mode(s_status_bar, 
                                            StatusBarLayerSeparatorModeDotted);
status_bar_layer_set_colors(s_status_bar, GColorClear, GColorWhite);
```

This results in a a look that is much easier to integrate into a color app.

![status-bar-color >{pebble-screenshot,pebble-screenshot--time-red}](/images/sdk/status-bar-color.png)

### Using PropertyAnimation

The internal structure of ``PropertyAnimation`` has changed, but it is still
possible to access the underlying ``Animation``:

```c
// SDK 2.x
Animation *animation = &prop_animation->animation;
animation = (Animation*)prop_animation;

// SDK 3.x
Animation *animation = property_animation_get_animation(prop_animation);
animation = (Animation*)prop_animation;
```

Accessing internal fields of ``PropertyAnimation`` has also changed. For
example, to access the ``GPoint`` in the `from` member of an animation:

```c
GPoint p;
PropertyAnimation *prop_anim;

// SDK 2.x
prop_animation->values.from.gpoint = p;

// SDK 3.x
property_animation_set_from_gpoint(prop_anim, &p);
```

Animations are now automatically freed when they have finished. This means that
code using ``animation_destroy()`` should be corrected to no longer do this
manually when building with SDK 3.x, which will fail. **SDK 2.x code must still
manually free Animations as before.**

Developers can now create complex synchronized and chained animations using the
new features of the Animation Framework. Read

to learn more.

### Accessing GBitmap Members

``GBitmap`` is now opaque, so accessing structure members directly is no longer
possible. However, direct references to members can be obtained with the new
accessor functions provided by SDK 3.x:

```c
static GBitmap *s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);

// SDK 2.x
GRect image_bounds = s_bitmap->bounds;

// SDK 3.x
GRect image_bounds = gbitmap_get_bounds(s_bitmap);
```

### Drawing Rotated Bitmaps

<div class="alert alert--fg-white alert--bg-dark-red">

  The bitmap rotation API requires a significant amount of CPU power and will
  have a substantial effect on users' battery life.

  There will also be a large reduction in performance of the app and a lower
  framerate may be seen. Use alternative drawing methods such as 
  ``Draw Commands`` or [`GPaths`](``GPath``) wherever possible.

</div>

Alternatively, draw a ``GBitmap`` with a rotation angle and center point inside a
``LayerUpdateProc`` using ``graphics_draw_rotated_bitmap()``.

### Using InverterLayer

SDK 3.x deprecates the `InverterLayer` UI component which was primarily used
for ``MenuLayer`` highlighting. Developers can now make use of
`menu_cell_layer_is_highlighted()` inside a ``MenuLayerDrawRowCallback`` to
determine which text and selection highlighting colors they prefer.

> Using this for determining highlight behaviour is preferable to using
> ``menu_layer_get_selected_index()``. Row drawing callbacks may be invoked
> multiple times with a different highlight status on the same cell in order to
> handle partially highlighted cells during animation.

## SDK 4.x Migration Guide

This guide provides details of the changes to existing APIs in Pebble
SDK 4.x. To migrate an older app's code successfully from Pebble SDK 3.x to
Pebble SDK 4.x, consider the information outlined here and make the necessary
changes if the app uses a changed API.

The number of breaking changes in SDK 4.x for existing apps has been minimized
as much as possible. This means that:

* Apps built with SDK 3.x **will continue to run on firmware 4.x without any
  recompilation needed**.

* Apps built with SDK 4.x will generate a `.pbw` file that will run on firmware
  4.x.

## New APIs

* ``AppExitReason`` - API for the application to notify the system of the reason
it will exit.
* ``App Glance`` - API for the application to modify its glance.
* ``UnobstructedArea`` - Detect changes to the available screen real-estate
based on obstructions.

## Timeline Quick View

Although technically not a breaking change, the timeline quick view feature will
appear overlayed on a watchface which may impact the visual appearance and
functionality of a watchface. Developers should read the
 to
learn how to adapt their watchface to handle obstructions.

## appinfo.json

Since the [introduction of Pebble Packages in June 2016](/blog/2016/06/07/pebble-packages/), the `appinfo.json`
file has been deprecated and replaced with `package.json`. Your project can
automatically be converted when you run `pebble convert-project` inside your
project folder.

You can read more about the `package.json` file in the
 guide.

## Launcher Icon

The new launcher in 4.0 allows developers to provide a custom icon for
their watchapps and watchfaces.

<div class="pebble-dual-image">
  <div class="panel">
  
  ![Launcher Icon](/images/blog/2016-08-19-pikachu-icon.png)
  
  </div>
  <div class="panel">
  
  ![Launcher >{pebble-screenshot,pebble-screenshot--time-red}](/images/blog/2016-08-19-pikachu-launcher.png)
  
  </div>
</div>

> If your `png` file is color, we will use the luminance of the image to add
> some subtle gray when rendering it in the launcher, rather than just black
> and white. Transparency will be preserved.

You should add a 25x25 `png` to the `resources.media` section of the
`package.json` file, and set `"menuIcon": true`.
Please note that icons that are larger will be ignored and 
your app will have the default icon instead.

```js
"resources": {
  "media": [
    {
      "menuIcon": true,
      "type": "png",
      "name": "IMAGE_MENU_ICON",
      "file": "images/icon.png"
    }
  ]
}
```

## SDK 2.x Migration Guide

This page is outdated, intended for updating SDK 1.x apps to SDK 2.x. All app
should now be created with SDK 3.x. For migrating an app from SDK 2.x to SDK
3.x, the read .

## Introduction

This guide provides you with a summary and a detailed list of the changes,
updates and new APIs available in Pebble SDK 2.0. To migrate your code successfully
from Pebble SDK 1.x to Pebble SDK 2.x, you should read this guide.

In addition to updated and new Pebble APIs, you'll find updated developer tools
and a simplified build system that makes it easier to create, build, and deploy
Pebble apps.

**Applications written for Pebble SDK 1.x do not work on Pebble 2.0.** It is
extremely important that you upgrade your apps, so that your users can continue
to enjoy your watchfaces and watchapps.

These are the essential steps to perform the upgrade:

* You'll need to upgrade Pebble SDK on your computer, the firmware on your
  Pebble, and the Pebble mobile application on your phone.
* You need to upgrade the `arm-cs-tools`. The version shipped with Pebble SDK 2
  contains several important improvements that help reduce the size of the
  binaries generated and improve the performance of your app.
* You need to upgrade the python dependencies
  `pip install --user -r /requirements.txt`).

## Discovering the new Pebble tools (Native SDK only)

One of the new features introduced in Pebble native SDK 2.0 is the `pebble` command
line tool. This tool is used to create new apps, build and install those apps on
your Pebble.

The tool was designed to simplify and optimize the build process for your Pebble
watchfaces and watchapps. Give it a try right now:

```c
$ pebble new-project helloworld
$ cd helloworld
$ ls
appinfo.json      resources    src          wscript
```

Notice that the new SDK does not require symlinks as the earlier SDK did. There
is also a new `appinfo.json` file, described in greater detail later in this
guide. The file provides you with a more readable format and includes all the
metadata about your app.

```c
$ pebble build
...

Memory usage:
=============
Total app footprint in RAM:        801 bytes / ~24kb
Free RAM available (heap):       23775 bytes

[12/13] inject-metadata: build/pebble-app.raw.bin build/app_resources.pbpack.data -> build/pebble-app.bin
[13/13] helloworld.pbw: build/pebble-app.bin build/app_resources.pbpack -> build/helloworld.pbw

...

'build' finished successfully (0.562s)
```

You don't need to call the `waf` tool to configure and then build the project
anymore (`pebble` still uses `waf`, however). The new SDK also gives you some
interesting information on how much memory your app will use and how much memory
will be left for you in RAM.

```c
$  pebble install --phone 10.0.64.113 --logs
[INFO    ] Installation successful
[INFO    ] Enabling application logging...
[INFO    ] Displaying logs ... Ctrl-C to interrupt.
[INFO    ] D helloworld.c:58 Done initializing, pushed window: 0x2001a524
```

Installing an app with `pebble` is extremely simple. It uses your phone and the
official Pebble application as a gateway. You do need to configure your phone
first, however. For more information on working with this tool, read
.

You don't need to run a local HTTP server or connect with Bluetooth like you did
with SDK 1.x. You will also get logs sent directly to the console, which will
make development a lot easier!

## Upgrading a 1.x app to 2.0

Pebble 2.0 is a major release with many changes visible to users and developers
and some major changes in the system that are not visible at first sight but
will have a strong impact on your apps.

Here are the biggest changes in Pebble SDK 2.0 that will impact you when
migrating your app. The changes are discussed in more detail below:

* Every app now requires an `appinfo.json`, which includes your app name, UUID,
  resources and a few other new configuration parameters. For more information,
  refer to .
* Your app entry point is called `main()` and not `pbl_main()`.
* Most of the system structures are not visible to apps anymore, and instead of
  allocating the memory yourself, you ask the system to allocate the memory and
  return a pointer to the structure.

  > This means that you'll have to change most of your system calls and
  > significantly rework your app. This change was required to allow us to
  > update the structs in the future (for example, to add new fields in them)
  > without forcing you to recompile your app code.

* Pebble has redesigned many APIs to follow standard C best practices and
  futureproof the SDK.

### Application metadata

To upgrade your app for Pebble SDK 2.0, you should first run the
`pebble convert-project` command in your existing 1.x project. This will
automatically try to generate the `appinfo.json` file based on your existing
source code and resource file. It will not touch your C code.

Please review your `appinfo.json` file and make sure everything is OK. If it is,
you can safely remove the UUID and the `PBL_APP_INFO` in your C file.

Refer to 
for more information on application metadata and the basic structure of an app
in Pebble SDK 2.0.

### Pebble Header files

In Pebble SDK 1.x, you would reference Pebble header files with three include
statements:

```c
#include "pebble_os.h"
#include "pebble_app.h"
#include "pebble_fonts.h"
```

In Pebble SDK 2.x, you can replace them with one statement:

```c
#include <pebble.h>
```

### Initializing your app

In Pebble SDK 1.x, your app was initialized in a `pbl_main()` function:

```c
void pbl_main(void *params) {
  PebbleAppHandlers handlers = {
    .init_handler = &handle_init
  };
  app_event_loop(params, &handlers);
}
```

In Pebble SDK 2.0:

* `pbl_main` is replaced by `main`.
* The `PebbleAppHandlers` structure no longer exists. You call your init and
  destroy handlers directly from the `main()` function.

```c
int main(void) {
  handle_init();
  app_event_loop();
  handle_deinit();
}
```

There were other fields in the `PebbleAppHandlers`:

* `PebbleAppInputHandlers`:
   Use a ``ClickConfigProvider`` instead.
* `PebbleAppMessagingInfo`: Refer to the section below on ``AppMessage``
 changes.
* `PebbleAppTickInfo`: Refer to the section below on Tick events.
* `PebbleAppTimerHandler`: Refer to the section below on ``Timer`` events.
* `PebbleAppRenderEventHandler`: Use a ``Layer`` and call
  ``layer_set_update_proc()`` to provide your own function to render.

### Opaque structures and Dynamic Memory allocation

In Pebble SDK 2.0, system structures are opaque and your app can't directly
allocate memory for them. Instead, you use system functions that allocate memory
and initialize the structure at the same time.

#### Allocating dynamic memory: A simple example

In Pebble SDK 1.x, you would allocate memory for system structures inside your
app with static global variables. For example, it was very common to write:

```c
Window my_window;
TextLayer text_layer;

void handle_init(AppContextRef ctx) {
  window_init(&my_window, "My App");
  text_layer_init(&text_layer, GRect(0, 0, 144, 20));
}
```

In Pebble SDK 2, you can't allocate memory statically in your program because
the compiler doesn't know at compile time how big the system structures are
(here, in the above code snippet ``Window`` and ``TextLayer``). Instead, you use
pointers and ask the system to allocate the memory for you.

This simple example becomes:

```c
Window *my_window;
TextLayer *text_layer;

void handle_init(void) {
  my_window = window_create();

  text_layer = text_layer_create(GRect(0, 0, 144, 20));
}
```

Instead of using `*_init()` functions and passing them a pointer to the structure,
in SDK 2.0, you call functions that end in `_create()`, and these functions will
allocate memory and return to your app a pointer to a structure that is
initialized.

Because the memory is dynamically allocated, it is extremely important that you
release that memory when you are finished using the structure. This can be done
with the `*_destroy()` functions. For our example, we could write:

```c
void handle_deinit(void) {
  text_layer_destroy(text_layer);
  window_destroy(my_window);
}
```

#### Dynamic memory: General rules in Pebble SDK 2.0

* Replace all statically allocated system structures with a pointer to the
  structure.
* Replace functions that ended in `_init()` with their equivalent that end in
  `_create()`.
* Keep pointers to the structures that you have initialized. Call the
  `*_destroy()` functions to release the memory.

### AppMessage changes

 * Instead of defining your buffer sizes in `PebbleAppMessagingInfo`, you pass
   them to ``app_message_open()``
 * Instead of using a `AppMessageCallbacksNode` structure and
   `app_message_register_callbacks()`, you register handler for the different
   ``AppMessage`` events with:
   * ``app_message_register_inbox_received()``
   * ``app_message_register_inbox_dropped()``
   * ``app_message_register_outbox_failed()``
   * ``app_message_register_outbox_sent()``
   * ``app_message_set_context(void *context)``: To set the context that will be
     passed to all the handlers.

* `app_message_out_get()` is replaced by ``app_message_outbox_begin()``.
* `app_message_out_send()` is replaced by ``app_message_outbox_send()``.
* `app_message_out_release()` is removed. You do not need to call this anymore.

For more information, please review the ``AppMessage`` API Documentation.

For working examples using AppMessage and AppSync in SDK 2.0, refer to:

 * `/PebbleSDK-2.x/Examples/pebblekit-js/quotes`:
   Demonstrates how to use PebbleKit JS to fetch price quotes from the web.
   It uses AppMessage on the C side.
 * `/PebbleSDK-2.x/Examples/pebblekit-js/weather`:
   A PebbleKit JS version of the traditional `weather-demo` example. It uses
   AppSync on the C side.

### Dealing with Tick events

Callbacks for tick events can't be defined through `PebbleAppHandlers` anymore.
Instead, use the Tick Timer Event service with:
``tick_timer_service_subscribe()``.

For more information, read /

### Timer changes

`app_timer_send_event()` is replaced by ``app_timer_register()``.

For more information, refer to the ``Timer`` API documentation.

### WallTime API changes

* `PblTm` has been removed and replaced by the libc standard struct. Use struct
  `tm` from `#include <time.h>`.

* `tm string_format_time()` function is replaced by ``strftime()``.

* `get_time()` is replaced by `localtime(time(NULL))`. This lets you convert a
  timestamp into a struct.

* Pebble OS does not, as yet, support timezones. However, Pebble SDK 2
  introduces `gmtime()` and `localtime()` functions to prepare for timezone
  support.

### Click handler changes

In SDK 1.x, you would set up click handlers manually by modifying an array of
config structures to contain the desired configuration. In SDK 2.x, how click
handlers are registered and used has changed.

The following functions for subscribing to events have been added in SDK 2.x:

```c
void window_set_click_context();
void window_single_click_subscribe();
void window_single_repeating_click_subscribe();
void window_multi_click_subscribe();
void window_multi_click_subscribe();
void window_long_click_subscribe();
void window_raw_click_subscribe();
```

For more information, refer to the ``Window`` API documentation.

For example, in SDK 1.x you would do this:

```c
void click_config_provider(ClickConfig **config, void *context) {
  config[BUTTON_ID_UP]->click.handler = up_click_handler;
  config[BUTTON_ID_UP]->context = context;
  config[BUTTON_ID_UP]->click.repeat_interval_ms = 100;

  config[BUTTON_ID_SELECT]->click.handler = select_click_handler;

  config[BUTTON_ID_DOWN]->multi_click.handler = down_click_handler;
  config[BUTTON_ID_DOWN]->multi_click.min = 2;
  config[BUTTON_ID_DOWN]->multi_click.max = 10;
  config[BUTTON_ID_DOWN]->multi_click.timeout = 0; /* default timeout */
  config[BUTTON_ID_DOWN]->multi_click.last_click_only = true;

  config[BUTTON_ID_SELECT]->long_click.delay_ms = 1000;
  config[BUTTON_ID_SELECT]->long_click.handler = select_long_click_handler;
}
```

In SDK 2.x, you would use the following calls instead:

```c
void click_config_provider(void *context) {
  window_set_click_context(BUTTON_ID_UP, context);
  window_single_repeating_click_subscribe(BUTTON_ID_UP, 100, up_click_handler);

  window_single_click_subscribe(BUTTON_ID_SELECT, select_click_handler);

  window_multi_click_subscribe(BUTTON_ID_DOWN, 2, 10, 0, true, down_click_handler);

  window_long_click_subscribe(BUTTON_ID_SELECT, 1000, select_long_click_handler, NULL /* No handler on button release */);
}
```

Notice that the signature of ``ClickConfigProvider`` has also changed. These
``Clicks`` API functions **must** be called from within the
ClickConfigProvider function. If they are not, your app code will fail.

### Other changes

* `graphics_text_draw()` has been renamed to ``graphics_draw_text()``, matching
  the rest of Pebble's graphics_draw_ functions. There are no changes with the
  usage of the function.

## Quick reference for the upgrader

**Table 1. API changes from SDK 1.x to 2.x**

   API Call in SDK 1.x   |    API Call in SDK 2.x     |
:-----------|:------------|
 `#define APP_TIMER_INVALID_HANDLE ((AppTimerHandle)0)` | Changed. No longer needed; `app_timer_register()` always succeeds. See [``Timer``.
 `#define INT_MAX 32767`      | Changed. See `#include <limits.h>`
 `AppTimerHandle app_timer_send_event();` | See ``app_timer_register()`` for more information at ``Timer``.
 `ARRAY_MAX`      | Removed from Pebble headers. Now use limits.h
 `bool app_timer_cancel_event();`      | Changed. See ``app_timer_cancel()`` for more information at ``Timer``.
 `GContext *app_get_current_graphics_context();`      | Removed. Use the context supplied to you in the drawing callbacks.
 `GSize text_layer_get_max_used_size();`      | Use ``text_layer_get_content_size()``. See ``TextLayer``.
 `INT_MAX`      | Removed from Pebble headers. Now use limits.h
 `void get_time();`      | Use `localtime(time(NULL))` from `#include <time.h>`.
 `void resource_init_current_app();`      | No longer needed.
 `void string_format_time();`      | Use ``strftime`` from `#include <time.h>`.
 `void window_render();`      | No longer available.

### Using `*_create()/*_destroy()` instead of `*_init()/*_deinit()` functions

If you were using the following `_init()/_deinit()` functions, you should now
use `*_create()/*_destroy()` instead when making these calls:

* `bool rotbmp_init_container();` See ``BitmapLayer``.
* `bool rotbmp_pair_init_container();` ``BitmapLayer``.
* `void action_bar_layer_init();` See ``ActionBarLayer``.
* `void animation_init();` See ``Animation``.
* `void bitmap_layer_init();` ``BitmapLayer``.
* `void gbitmap_init_as_sub_bitmap();` See [Graphics Types](``Graphics Types``).
* `void gbitmap_init_with_data();` See [Graphics Types](``Graphics Types``).
* `void inverter_layer_init();` Now `InverterLayer` (deprecated in SDK 3.0).
* `void layer_init();` See ``Layer``.
* `void menu_layer_init();` See ``MenuLayer``.
* `void number_window_init();`
* `void property_animation_init_layer_frame();` See ``Animation``.
* `void property_animation_init();` See ``Animation``.
* `void rotbmp_deinit_container();` ``BitmapLayer``.
* `void rotbmp_pair_deinit_container();` ``BitmapLayer``.
* `void scroll_layer_init();` See ``ScrollLayer``.
* `void simple_menu_layer_init();` See ``SimpleMenuLayer``.
* `void text_layer_deinit();` See ``TextLayer``.
* `void text_layer_init();` See ``TextLayer``.
* `void window_deinit();` See ``Window``.
* `void window_init();` See ``Window``.

## PebbleKit iOS 3.0 Migration Guide

With previous Pebble firmware versions, iOS users had to manage two different
Bluetooth pairings to Pebble. A future goal is removing the Bluetooth *Classic*
pairing and keeping only the *LE* (Low Energy) one. This has a couple of
advantages. By using only one Bluetooth connection Pebble saves energy,
improving the battery life of both Pebble and the phone. It also has the
potential to simplify the onboarding experience. In general, fewer moving parts
means less opportunity for failures and bugs.

The plan is to remove the Bluetooth *Classic* connection and switch to *LE* in
gradual steps. The first step is to make the Pebble app communicate over *LE* if
it is available. The Bluetooth *Classic* pairing and connection will be kept
since as of today most iOS companion apps rely on the *Classic* connection in
order to work properly.

Building a companion app against PebbleKit iOS 3.0 will make it compatible with
the new *LE* connection, while still remaining compatible with older Pebble
watches which don't support the *LE* connection. Once it is decided to cut the
Bluetooth *Classic* cord developers won't have to do anything, existing apps
will continue to work.

> Note: Pebble Time Round (the chalk platform) uses only Bluetooth LE, and so
> companion apps **must** use PebbleKit iOS 3.0 to connect with it.

## What's New

### Sharing No More: Dedicated Channels per App

A big problem with the Bluetooth *Classic* connection is that all iOS companion
apps have to share a single communication channel which gets assigned on a "last
one wins" basis. Another problem is that a "session" on this channel has to be
opened and closed by the companion app.

PebbleKit iOS 3.0 solved both these problems with *LE* based connections. When
connected over *LE* each companion app has a dedicated and persistent
communication channel to Pebble.

This means that an app can stay connected as long as there is a physical
Bluetooth LE connection, and it does not have to be closed before that other
apps can use it!

### Starting an App from Pebble

Since each companion app using the *LE* connection will have a dedicated and
persistent channel, the user can now start using an app from the watch without
having to pull out the phone to open the companion app. The companion app will
already be connected and listening. However there are a few caveats to this:

* The user must have launched the companion app at least once after rebooting
  the iOS device.

* If the user force-quits the companion app (by swiping it out of the app
  manager) the channel to the companion app will be disconnected.

Otherwise the channel is pretty robust. iOS will revive the companion app in the
background when the watchapp sends a message if the companion app is suspended,
has crashed, or was stopped/killed by iOS because it used too much memory.

## How to Upgrade

1. Download the new `PebbleKit.framework` from the
   [`pebble-ios-sdk`](https://github.com/pebble/pebble-ios-sdk/) repository.

2. Replace the existing `PebbleKit.framework` directory in the iOS project.

3. The `PebbleVendor.framework` isn't needed anymore. If it is not used, remove
   it from the project to reduce its size.

3. See the [Breaking API Changes](#breaking-api-changes) section below.

4. When submitting the iOS companion to the
  [Pebble appstore](), make sure to check the
  checkbox shown below.

![](/images/guides/migration/companion-checkbox.png)

> **Important**: Make sure to invoke `[[PBPebbleCentral defaultCentral] run]`
> after the iOS app is launched, or watches won't connect!

## Breaking API Changes

### App UUIDs Are Now NSUUIDs

Older example code showed how to use the `appUUID` property of the
`PBPebbleCentral` object, which was passed as an `NSData` object. Now it is
possible to directly use an `NSUUID` object. This also applies to the `PBWatch`
APIs requiring `appUUID:` parameters. An example of each case is shown below.

**Previous Versions of PebbleKit iOS**

```obj-c
uuid_t myAppUUIDbytes;
NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"226834ae-786e-4302-a52f-6e7efc9f990b"];
[myAppUUID getUUIDBytes:myAppUUIDbytes];
[PBPebbleCentral defaultCentral].appUUID = [NSData dataWithBytes:myAppUUIDbytes length:16];
```

**With PebbleKit iOS 3.0**

```obj-c
NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"226834ae-786e-4302-a52f-6e7efc9f990b"];
[PBPebbleCentral defaultCentral].appUUID = myAppUUID;
```

### Cold PBPebbleCentral

As soon as PebbleKit uses a `CoreBluetooth` API a pop-up asking for Bluetooth
permissions will appear. Since it is undesirable for this pop-up to jump right
into users' faces when they launch the iOS app, `PBPebbleCentral` will start in
a "cold" state.

This gives developers the option to explain to app users that this pop-up will
appear, in order to provide a smoother onboarding experience. As soon as a
pop-up would be appropriate to show (e.g.: during the app's onboarding flow),
 call `[central run]`, and the pop-up will be shown to the user.

To help personalize the experience, add some custom text to the pop-up by adding
a `NSBluetoothPeripheralUsageDescription` ("Privacy - Bluetooth Peripheral Usage
Description") value to the project's `Info.plist` file.

```obj-c
// MyAppDelegate.m - Set up PBPebbleCentral and run if the user has already
// performed onboarding
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [PBPebbleCentral defaultCentral].delegate = self;
  [PBPebbleCentral defaultCentral].appUUID = myAppUUID;
  if ([MySettings sharedSettings].userDidPerformOnboarding) {
    [[PBPebbleCentral defaultCentral] run];
  }
}
```

```obj-c
// MyOnboarding.m - Once the pop-up has been accepted, begin PBPebbleCentral
- (IBAction)didTapGrantBluetoothPermissionButton:(id)sender {
  [MySettings sharedSettings].userDidPerformOnboarding = YES;
  [[PBPebbleCentral defaultCentral] run]; // will trigger pop-up
}
```

It is very unlikely that the Pebble watch represented by the `PBWatch` object
returned by `lastConnectedWatch` is connected instantly after invoking `[central
run]`. Instead, it is guaranteed that the delegate will receive
`pebbleCentral:watchDidConnect:` as soon as the watch connects (which might take
a few seconds). Once this has occurred, the app may then perform operations on
the `PBWatch` object.

## New Features

### 8K AppMessage Buffers

In previous versions of PebbleKit iOS, if an app wanted to transmit large
amounts of data it had to split it up into packets of 126 bytes. As of firmware
version 3.5, this is no longer the case - the maximum message size is now such
that a dictionary with one byte array (`NSData`) of 8192 bytes fits in a single
app message. The maximum available buffer sizes are increased for messages in
both directions (i.e.: inbox and outbox buffer sizes). Note that the watchapp
should be compiled with SDK 3.5 or later in order to use this capability.

To check whether the connected watch supports the increased buffer sizes, use
`getVersionInfo:` as shown below.

```obj-c
[watch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo) {
  // If 8k buffers are supported...
  if ((versionInfo.remoteProtocolCapabilitiesFlags & PBRemoteProtocolCapabilitiesFlagsAppMessage8kSupported) != 0) {
    // Send a larger message!
    NSDictionary *update = @{ @(0): someHugePayload };
    [watch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
      // ...
    }];
  } else {
    // Fall back to sending smaller 126 byte messages...
  }
}];
```

###  Swift Support

The library now exports a module which makes using PebbleKit iOS in
[Swift](https://developer.apple.com/swift/) projects much easier. PebbleKit iOS
3.0 also adds nullability and generic annotations so that developers get the
best Swift experience possible.

```obj-c
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
  let pebbleCentral = PBPebbleCentral.defaultCentral()
  pebbleCentral.appUUID = PBGolfUUID
  pebbleCentral.delegate = self
  pebbleCentral.run()

  return true
}
```

## Minor Changes and Deprecations

* Removed the PebbleVendor framework.

  * Also removed CocoaLumberjack from the framework. This should
    reduce conflicts if the app is using CocoaLumberjack itself.

  * If the project need these classes, it can keep the PebbleVendor dependency,
    therwise just remove it.

* Added `[watch releaseSharedSession]` which will close *Classic* sessions that
  are shared between iOS apps (but not *LE* sessions as they are not shared).

  * If the app doesn't need to talk to Pebble in the background, it doesn't have
    to use it.

  * If the app does talk to Pebble while in the background, call this method as
    soon as it is done talking.

* Deprecated `[watch closeSession:]` - please use `[watch releaseSharedSession]`
  if required (see note above). The app can't close *LE* sessions actively.

* Deprecated `[defaultCentral hasValidAppUUID]` - please use `[defaultCentral
  appUUID]` and check that it is not `nil`.

* Added `[defaultCentral addAppUUID:]` if the app talks to multiple app UUIDs from
  the iOS application, allowing `PebbleCentral` to eagerly create *LE*
  sessions.

* Added logging - PebbleKit iOS 3.0 now logs internal warnings and errors via
  `NSLog`. To change the verbosity, use `[PBPebbleCentral setLogLevel:]` or even
  override the `PBLog` function (to forward it to CocoaLumberjack for example).

* Changed `[watch appMessagesAddReceiveUpdateHandler:]` - the handler must not
  be `nil`.

## Other Recommendations

### Faster Connection

Set `central.appUUID` before calling `[central run]`. If using multiple app
UUIDs please use the new `addAppUUID:` API before calling `[central run]` for
every app UUID that the app will talk to.

### Background Apps

If the app wants to run in the background (please remember that Apple might
reject it unless it provides reasonable cause) add the following entries to the
`UIBackgroundModes` item in the project's `Info.plist` file:

* `bluetooth-peripheral` ("App shares data using CoreBluetooth") which is used
  for communication.

* `bluetooth-central` ("App communicates using CoreBluetooth") which is used for
  discovering and reconnecting Pebbles.

### Compatibility with Older Pebbles

Most of the Pebble users today will be using a firmware that is not capable of
connecting to an iOS application using *LE*. *LE* support will gradually roll
out to all Pebble watches. However, this will not happen overnight. Therefore,
both *LE* and *Classic* PebbleKit connections have to be supported for some
period of time. This has several implications for apps:

* Apps still need to be whitelisted. Read
   for more information and to
  whitelist a new app.

* Because the *Classic* communication channel is shared on older Pebble firmware
  versions, iOS apps still need to provide a UI to let the user connect to/disconnect
  from the Pebble app. For example, a "Disconnect" button would cause `[watch
  releaseSharedSession]` to be called.

* In the project's `Info.plist` file:

  * The `UISupportedExternalAccessoryProtocols` key still needs to be added with
    the value `com.getpebble.public`.

  * The `external-accessory` value needs to be added to the `UIBackgroundModes`
    array, if you want to support using the app while backgrounded.

## Migrating Older Apps

When the Pebble SDK major version is increased (such as from 2.x to 3.x), some
breaking API and build process changes are made. This means that some apps
written for an older SDK may no longer compile with the newer one.

To help developers transition their code, these guides detail the specific
changes they should look out for and highlighting the changes to APIs they may
have previously been using. When breaking changes are made in the future, new
guides will be added here to help developers make the required changes.

## Contents

