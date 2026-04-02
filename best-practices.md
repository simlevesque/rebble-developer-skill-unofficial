# Best Practices

> Information to help optimize apps and ensure a good user experience.

## Building for Every Pebble

The difference in capabilities between the various Pebble hardware platforms are
listed in
. For example, the
Basalt, Chalk and Emery platforms support 64 colors, whereas the Aplite, Diorite
and Flint platforms only support two colors. This can make developing apps with
rich color layouts difficult when considering compatibility with other non-color
hardware. Another example is using platform specific APIs such as Health or
Dictation.

To make life simple for users, developers should strive to write one app that
can be used on all platforms. To help make this task simpler for developers, the
Pebble SDK provides numerous methods to accommodate different hardware
capabilities in code.

## Preprocessor Directives

It is possible to specify certain blocks of code to be compiled for specific
purposes by using the `#ifdef` preprocessor statement. For example, the
``Dictation`` API should be excluded on platforms with no microphone:

```c
#if defined(PBL_MICROPHONE)
  // Start dictation UI
  dictation_session_start(s_dictation_session);
#else
  // Microphone is not available
  text_layer_set_text(s_some_layer, "Dictation not available!");
#endif
```

When designing UI layouts, any use of colors on compatible platforms can be
adapted to either black or white on non-color platforms. The `PBL_COLOR` and
`PBL_BW` symbols will be defined at compile time when appropriate capabilities
are available:

```c
#if defined(PBL_COLOR)
  text_layer_set_text_color(s_text_layer, GColorRed);
  text_layer_set_background_color(s_text_layer, GColorChromeYellow);
#else
  text_layer_set_text_color(s_text_layer, GColorWhite);
  text_layer_set_background_color(s_text_layer, GColorBlack);
#endif
```

This is useful for blocks of multiple statements that change depending on the
availability of color support. For single statements, this can also be achieved
by using the ``PBL_IF_COLOR_ELSE()`` macro.

```c
window_set_background_color(s_main_window, PBL_IF_COLOR_ELSE(GColorJaegerGreen, GColorBlack));
```

See below for a complete list of defines and macros available.

## Available Defines and Macros

The tables below show a complete summary of all the defines and associated
macros available to conditionally compile or omit feature-dependant code. The
macros are well-suited for individual value selection, whereas the defines are
better used to select an entire block of code.

| Define | MACRO |Available |
|--------|-------|----------|
| `PBL_BW` | `PBL_IF_BW_ELSE()` | Running on hardware that supports only black and white. |
| `PBL_COLOR` | `PBL_IF_COLOR_ELSE()` | Running on hardware that supports 64 colors. |
| `PBL_MICROPHONE` | `PBL_IF_MICROPHONE_ELSE()` | Running on hardware that includes a microphone. |
| `PBL_COMPASS` | None | Running on hardware that includes a compass. |
| `PBL_SMARTSTRAP` | `PBL_IF_SMARTSTRAP_ELSE()` | Running on hardware that includes a smartstrap connector, but does not indicate that the connector is capable of supplying power. |
| `PBL_SMARTSTRAP_POWER` | None | Running on hardware that includes a smartstrap connector capable of supplying power. |
| `PBL_HEALTH` | `PBL_IF_HEALTH_ELSE()` | Running on hardware that supports Pebble Health and the `HealthService` API. |
| `PBL_RECT` | `PBL_IF_RECT_ELSE()` | Running on hardware with a rectangular display. |
| `PBL_ROUND` | `PBL_IF_ROUND_ELSE()` | Running on hardware with a round display. |
| `PBL_DISPLAY_WIDTH` | None | Determine the screen width in pixels. |
| `PBL_DISPLAY_HEIGHT` | None | Determine the screen height in pixels. |
| `PBL_PLATFORM_APLITE` | None | Built for Pebble/Pebble Steel. |
| `PBL_PLATFORM_BASALT` | None | Built for Pebble Time/Pebble Time Steel. |
| `PBL_PLATFORM_CHALK` | None | Built for Pebble Time Round. |
| `PBL_PLATFORM_DIORITE` | None | Built for Pebble 2. |
| `PBL_PLATFORM_EMERY` | None | Built for Pebble Time 2. |
| `PBL_PLATFORM_FLINT` | None | Built for Pebble 2 Duo. |
| `PBL_SDK_2` | None | Compiling with SDK 2.x (deprecated). |
| `PBL_SDK_3` | None | Compiling with SDK 3.x. or 4.x. |

> Note: It is strongly recommended to conditionally compile code using
> applicable feature defines instead of `PBL_PLATFORM` defines to be as specific
> as possible.

## API Detection

In addition to platform and capabilities detection, we now provide API
detection to detect if a specific API method is available. This approach could
be considered future-proof, since platforms and capabilities may come and go.
Let's take a look at a simple example:

```c
#if PBL_API_EXISTS(health_service_peek_current_value)
 // Do something if specific Health API exists
#endif
```

## Avoid Hardcoded Layout Values

With the multiple display shapes and resolutions available, developers should
try and avoid hardcoding layout values. Consider the example
below:

```c
static void window_load(Window *window) {
  // Create a full-screen Layer - BAD
  s_some_layer = layer_create(GRect(0, 0, 144, 168));
}
```

The hardcoded width and height of this layer will cover the entire screen on
Aplite, Basalt, Diorite and Flint, but not on Chalk or Emery. This kind of screen
size-dependant calculation should use the ``UnobstructedArea`` bounds of the
``Window`` itself:

```c
static void window_load(Window *window) {
  // Get the unobstructed bounds of the Window
  Layer window_layer = window_get_root_layer(window);
  GRect window_bounds = layer_get_unobstructed_bounds(window_layer);

  // Properly create a full-screen Layer - GOOD
  s_some_layer = layer_create(window_bounds);
}
```

Another common use of this sort of construction is to make a ``Layer`` that is
half the unobstructed screen height. This can also be correctly achieved using
the ``Window`` unobstructed bounds:

```c
GRect layer_bounds = window_bounds;
layer_bounds.size.h /= 2;

// Create a Layer that is half the screen height
s_some_layer = layer_create(layer_bounds);
```

This approach is also advantageous in simplifying updating an app for a future
new screen size, as proportional layout values will adapt as appropriate when
the ``Window`` unobstructed bounds change.

## Screen Sizes

To ease the introduction of the Emery platform, the Pebble SDK introduced new
compiler directives to allow developers to determine the screen width and
height. This is preferable to using platform detection, since multiple platforms
share the same screen width and height.

```c
#if PBL_DISPLAY_HEIGHT == 228
  uint8_t offset_y = 100;
#elif PBL_DISPLAY_HEIGHT == 180
  uint8_t offset_y = 80;
#else
  uint8_t offset_y = 60;
#endif
```

> Note: Although this method is preferable to platform detection, it is better
to dynamically calculate the display width and height based on the unobstructed
bounds of the root layer.

## Pebble C WatchInfo

The ``WatchInfo`` API can be used to determine exactly which Pebble model and
color an app is running on. Apps can use this information to dynamically
modify their layout or behavior depending on which Pebble the user is wearing.

For example, the display on Pebble Steel is located at a different vertical
position relative to the buttons than on Pebble Time. Any on-screen button hints
can be adjusted to compensate for this using ``WatchInfoModel``.

```c
static void window_load(Window *window) {
  Layer window_layer = window_get_root_layer(window);
  GRect window_bounds = layer_get_bounds(window_layer);

  int button_height, y_offset;

  // Conditionally set layout parameters
  switch(watch_info_get_model()) {
    case WATCH_INFO_MODEL_PEBBLE_STEEL:
      y_offset = 64;
      button_height = 44;
      break;
    case WATCH_INFO_MODEL_PEBBLE_TIME:
      y_offset = 58;
      button_height = 56;
      break;

    /* Other cases */

    default:
      y_offset = 0;
      button_height = 0;
      break;

  }

  // Set the Layer frame
  GRect layer_frame = GRect(0, y_offset, window_bounds.size.w, button_height);

  // Create the Layer
  s_label_layer = text_layer_create(layer_frame);
  layer_add_child(window_layer, text_layer_get_layer(s_label_layer));

  /* Other UI code */

}
```

Developers can also use ``WatchInfoColor`` values to theme an app for each
available color of Pebble.

```c
static void window_load(Window *window) {
  GColor text_color, background_color;

  // Choose different theme colors per watch color
  switch(watch_info_get_color()) {
    case WATCH_INFO_COLOR_RED:
      // Red theme
      text_color = GColorWhite;
      background_color = GColorRed;
      break;
    case WATCH_INFO_COLOR_BLUE:
      // Blue theme
      text_color = GColorBlack;
      background_color = GColorVeryLightBlue;
      break;

    /* Other cases */

    default:
      text_color = GColorBlack;
      background_color = GColorWhite;
      break;

  }

  // Use the conditionally set value
  text_layer_set_text_color(s_label_layer, text_color);
  text_layer_set_background_color(s_label_layer, background_color);

  /* Other UI code */

}
```

## PebbleKit JS Watch Info

Similar to [*Pebble C WatchInfo*](#pebble-c-watchinfo) above, the PebbleKit JS
``Pebble.getActiveWatchInfo()`` method allows developers to determine
which model and color of Pebble the user is wearing, as well as the firmware
version running on it. For example, to obtain the model of the watch:

> Note: See the section below to avoid problem using this function on older app
> version.

```js
// Get the watch info
var info = Pebble.getActiveWatchInfo();

console.log('Pebble model: ' + info.model);
```

## Detecting Platform-specific JS Features

A number of features in PebbleKit JS (such as ``Pebble.timelineSubscribe()`` and
``Pebble.getActiveWatchInfo()``) exist on SDK 3.x. If an app tries to use any of
these on an older Pebble mobile app version where they are not available, the JS
app will crash.

To prevent this, be sure to check for the availability of the function before
calling it. For example, in the case of ``Pebble.getActiveWatchInfo()``:

```js
if (Pebble.getActiveWatchInfo) {
  // Available.
  var info = Pebble.getActiveWatchInfo();

  console.log('Pebble model: ' + info.model);
} else {
  // Gracefully handle no info available

}
```

## Platform-specific Resources

With the availability of color support on Basalt, Chalk and Emery, developers
may wish to include color versions of resources that had previously been
pre-processed for Pebble's black and white display. Including both versions of
the resource is expensive from a resource storage perspective, and lays the
burden of packing redundant color resources in an Aplite, Diorite or Flint app when
built for multiple platforms.

To solve this problem, the Pebble SDK allows developers to specify which version
of an image resource is to be used for each display type, using `~bw` or
`~color` appended to a file name. Resources can also be bundled only with
specific platforms using the `targetPlatforms` property for each resource.

For more details about packaging resources specific to each platform, as well as
more tags available similar to `~color`, read
.

## Multiple Display Shapes

With the introduction of the Chalk platform, a new round display type is
available with increased pixel resolution. To distinguish between the two
possible shapes of display, developers can use defines to conditionally
include code segments:

```c
#if defined(PBL_RECT)
  printf("This is a rectangular display!");
#elif defined(PBL_ROUND)
  printf("This is a round display!");
#endif
```

Another approach to this conditional compilation is to use the
``PBL_IF_RECT_ELSE()`` and ``PBL_IF_ROUND_ELSE()`` macros, allowing values to be
inserted into expressions that might otherwise require a set of `#define`
statements similar to the previous example. This would result in needless
verbosity of four extra lines of code when only one is actually needed. These
are used in the following manner:

```c
// Conditionally print out the shape of the display
printf("This is a %s display!", PBL_IF_RECT_ELSE("rectangular", "round"));
```

This mechanism is best used with window bounds-derived layout size and position
value. See the [*Avoid Hardcoded Layout Values*](#avoid-hardcoded-layout-values)
section above for more information. Making good use of the builtin ``Layer``
types will also help safeguard apps against display shape and size changes.

Another thing to consider is rendering text on a round display. Due to the
rounded corners, each horizontal line of text will have a different available
width, depending on its vertical position.

## Conserving Battery Life

One of Pebble's strengths is its long battery life. This is due in part to using
a low-power display technology, conservative use of the backlight, and allowing
the processor to sleep whenever possible. It therefore follows that apps which
misuse high-power APIs or prevent power-saving mechanisms from working will
detract from the user's battery life. Several common causes of battery drain in
apps are discussed in this guide, alongside suggestions to help avoid them.

## Time Awake

Because the watch tries to sleep as much as possible to conserve power, any app
that keeps the watch awake will incur significant a battery penalty. Examples of
such apps include those that frequently use animations, sensors, Bluetooth
communications, and vibrations.

### Animations and Display Updates

A common cause of such a drain are long-running animations that cause frequent
display updates. For example, a watchface that plays a half-second ``Animation``
for every second that ticks by will drain the battery faster than one that does
so only once per minute. The latter approach will allow a lot more time for the
watch to sleep.

```c
static void tick_handler(struct tm *tick_time, TimeUnits changed) {
  // Update time
  set_time_digits(tick_time);

  // Only update once a minute
  if(tick_time->tm_sec == 0) {
    play_animation();
  }
}
```

This also applies to apps that make use of short-interval ``Timer``s, which is
another method of creating animations. Consider giving users the option to
reduce or disable animations to further conserve power, as well as removing or
shortening animations that are not essential to the app's function or aesthetic.

However, not all animations are bad. Efficient use of the battery can be
maintained if the animations are played at more intelligent times. For example,
when the user is holding their arm to view the screen (see
[`pebble_glancing_demo`](https://github.com/pebble-hacks/pebble_glancing_demo))
or only when a tap or wrist shake is detected:

```c
static void accel_tap_handler(AccelAxisType axis, int32_t direction) {
  // Animate when the user flicks their wrist
  play_animation();
}
```

```c
accel_tap_service_subscribe(tap_handler);
```

### Tick Updates

Many watchfaces unecessarily tick once a second by using the ``SECOND_UNIT``
constant value with the ``TickTimerService``, when they only update the display
once a minute. By using the ``MINUTE_UNIT`` instead, the amount of times the
watch is woken up per minute is reduced.

```c
// Only tick once a minute, much more time asleep
tick_timer_service_subscribe(MINUTE_UNIT, tick_handler);
```

If possible, give users the choice to disable the second hand tick and/or
animation to further save power. Extremely minimal watchfaces may also use the
``HOUR_UNIT`` value to only be updated once per hour.

This factor is especially important for Pebble Time Round users. On this
platform the reduced battery capacity means that a watchface with animations
that play every second could reduce this to one day or less. Consider offering
configuration options to reducing tick updates on this platform to save power
where it at a premium.

### Sensor Usage

Apps that make frequent usage of Pebble's onboard accelerometer and compass
sensors will also prevent the watch from going to sleep and consume more battery
power. The ``AccelerometerService`` API features the ability to configure the
sampling rate and number of samples received per update, allowing batching of
data into less frequent updates. By receiving updates less frequently, the
battery will last longer.

```c
// Batch samples into sets of 10 per callback
const uint32_t num_samples = 10;

// Sample at 10 Hz
accel_service_set_sampling_rate(ACCEL_SAMPLING_10HZ);

// With this combination, only wake up the app once per second!
accel_data_service_subscribe(num_samples, accel_data_handler);
```

Similarly, the ``CompassService`` API allows a filter to be set on the heading
updates, allowing an app to only be notified per every 45 degree angle change,
for example.

```c
// Only update if the heading changes significantly
compass_service_set_heading_filter(TRIG_MAX_ANGLE / 36);
```

In addition, making frequent use of the ``Dictation`` API will also keep the
watch awake, and also incur a penalty for keeping the Bluetooth connection
alive. Consider using the ``Storage`` API to remember previous user input and
instead present a list of previous inputs if appropriate to reduce usage of this
API.

```c
static void dictation_session_callback(DictationSession *session, DictationSessionStatus status,
                                       char *transcription, void *context) {
  if(status == DictationSessionStatusSuccess) {
    // Display the dictated text
    snprintf(s_last_text, sizeof(s_last_text), "Transcription:\n\n%s",
                                                                transcription);
    text_layer_set_text(s_output_layer, s_last_text);

    // Save for later!
    const int last_text_key = 0;
    persist_write_string(last_text_key, s_last_text);
  }
}
```

### Bluetooth Usage

Hinted at above, frequent use of the ``AppMessage`` API to send and recieve data
will cause the Bluetooth connection to enter a more responsive state, which
consumes much more power. A small time after a message is sent, the connection
will return back to a low-power state.

The 'sniff interval' determines how often the API checks for new messages from
the phone, and should be let in the default ``SNIFF_INTERVAL_NORMAL`` state as
much as possible. Consider how infrequent communication activities can be to
save power and maintain functionality, and how data obtained over the Bluetooth
connection can be cached using the ``Storage`` API to reduce the frequency of
updates (for example, weather information in watchface).

If the reduced sniff state must be used to transfer large amounts of data
quickly, be sure to return to the low-power state as soon as the transfer is
complete:

```c
// Return to low power Bluetooth state
app_comm_set_sniff_interval(SNIFF_INTERVAL_NORMAL);
```

## Backlight Usage

The backlight LED is another large consumer of battery power. System-level
backlight settings may see the backlight turn on for a few seconds every time a
button is pressed. While this setting is out of the hands of developers, apps
can work to reduce the backlight on-time by minimizing the number of button
presses required to operate them. For example, use an ``ActionBarLayer`` to
execute common actions with one button press instead of a long scrolling
``MenuLayer``.

While the ``Light`` API is available to manually turn the backlight on, it
should not be used for more than very short periods, if at all. Apps that keep
the backlight on all the time will not last more than a few hours. If the
backlight must be kept on for an extended period, make sure to return to the
automatic mode as soon as possible:

```c
// Return to automatic backlight control
light_enable(false);
```

## Vibration Motor Usage

As a physical converter of electrical to mechanical energy, the vibration motor
also consumes a lot of power. Users can elect to use Quiet Time or turn off
vibration for notifications to save power, but apps can also contribute to this
effort. Try and keep the use of the ``Vibes`` API to a minimum and giving user
the option to disable any vibrations the app emits. Another method to reduce
vibrator power consumtion is to shorten the length of any custom sequences used.

## Learn More

To learn more about power consumtion on Pebble and how battery life can be
extended through app design choices, watch the presentation below given at the
2014 Developer Retreat.

[EMBED](//www.youtube.com/watch?v=TS0FPfgxAso)

## Modular App Architecture

Most Pebble projects (such as a simple watchface) work fine as a single-file
project. This means that all the code is located in one `.c` file. However, as
the size of a single-file Pebble project increases, it can become harder to keep
track of where all the different components are located, and to track down how
they interact with each other. For example, a hypothetical app may have many
``Window``s, perform communication over ``AppMessage`` with many types of data
items, store and persist a large number of data items, or include components
that may be valuable in other projects.

As a first example, the Pebble SDK is already composed of separate modules such
as ``Window``, ``Layer``, ``AppMessage`` etc. The implementation of each is
separate from the rest and the interface for developers to use in each module is
clearly defined and will rarely change.

This guide aims to provide techniques that can be used to break up such an app.
The advantages of a modular approach include:

* App ``Window``s can be kept separate and are easier to work on.

* A clearly defined interface between components ensures internal changes do not
  affect other modules.

* Modules can be re-used in other projects, or even made into sharable
  libraries.

* Inter-component variable dependencies do not occur, which can otherwise cause
  problems if their type or size changes.

* Sub-component complexity is hidden in each module.

* Simpler individual files promote maintainability.

* Modules can be more easily tested.

## A Basic Project

A basic Pebble project starts life with the `new-project` command:

```bash
$ pebble new-project modular-project
```

This new project will contain the following default file structure. The
`modular-project.c` file will contain the entire app, including `main()`,
`init()` and `deinit()`, as well as a ``Window`` and a child ``TextLayer``.

```text
modular-project/
  resources/
  src/
    modular-project.c
  package.json
  wscript
```

For most projects, this structure is perfectly adequate. When the `.c` file
grows to several hundred lines long and incorporates several sub-components with
many points of interaction with each other through shared variables, the
complexity reaches a point where some new techniques are needed.

## Creating a Module

In this context, a 'module' can be thought of as a C header and source file
'pair', a `.h` file describing the module's interface and a `.c` file containing
the actual logic and code. The header contains standard statements to prevent
redefinition from being `#include`d multiple times, as well as all the function
prototypes the module makes available for other modules to use. 

By making a sub-component of the app into a module, the need for messy global
variables is removed and a clear interface between them is defined. The files
themselves are located in a `modules` directory inside the project's main `src`
directory, keeping them in a separate location to other components of the app.
Thus the structure of the project with a `data` module added (and explained
below) is now this:

```text
modular-project/
  resources/
  src/
    modules/
      data.h
      data.c
    modular-project.c
  package.json
  wscript
```

The example module's pair of files is shown below. It manages a dynamically
allocated array of integers, and includes an interface to setting and getting
values from the array. The array itself is private to the module thanks for the
[`static`](https://en.wikipedia.org/wiki/Static_(keyword)) keyword. This
technique allows other components of the app to call the 'getters' and 'setters'
with the correct parameters as per the module's interface, without worrying
about the implementation details.

`src/modules/data.h`

```c
#pragma once         // Prevent errors by being included multiple times
  
#include <pebble.h>  // Pebble SDK symbols

void data_init(int array_length);

void data_deinit();

void data_set_array_value(int index, int new_value);

int data_get_array_value(int index);
```

`src/modules/data.c`

```c
#include "data.h"

static int* s_array;

void data_init(int array_length) {
  if(!s_array) {
    s_array = (int*)malloc(array_length * sizeof(int));
  }
}

void data_deinit() {
  if(s_array) {
    free(s_array);
    s_array = NULL;
  }
}

void data_set_array_value(int index, int new_value) {
  s_array[index] = new_value;
}

int data_get_array_value(int index) {
  return s_array[index];
}
```

## Keep Multiple Windows Separate

The ``Window Stack`` lifecycle makes the task of keeping each ``Window``
separate quite easy. Each one has a `.load` and `.unload` handler which should
be used to create and destroy its UI components and other data.

The first step to modularizing the new app is to keep each ``Window`` in its own
module. The first ``Window``'s code can be moved out of `src/modular-project.c`
into a new module in `src/windows/` called 'main_window':

`src/windows/main_window.h`

```c
#pragma once

#include <pebble.h>

void main_window_push();
```

`src/windows/main_window.c`

```c
#include "main_window.h"

static Window *s_window;

static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);
}

static void window_unload(Window *window) {
  window_destroy(s_window);
}

void main_window_push() {
  if(!s_window) {
    s_window = window_create();
    window_set_window_handlers(s_window, (WindowHandlers) {
      .load = window_load,
      .unload = window_unload,
    });
  }
  window_stack_push(s_window, true);
}
```

## Keeping Main Clear

After moving the ``Window`` code out of the main `.c` file, it can be safely
renamed `main.c` to reflect its contents. This allows the main `.c` file to show
a high-level overview of the app as a whole. Simply `#include` the required
modules and windows to initialize and deinitialize the rest of the app as
necessary:

`src/main.c`

```c
#include <pebble.h>

#include "modules/data.h"
#include "windows/main_window.h"

static void init() {
  const int array_size = 16;
  data_init(array_size);

  main_window_push();
}

static void deinit() {
  data_deinit();
}

int main() {
  init();
  app_event_loop();
  deinit();
}
```

Thus the structure of the project is now:

```text
modular-project/
  resources/
  src/
    modules/
      data.h
      data.c
    windows/
      main_window.h
      main_window.c
    main.c
  package.json
  wscript
```

With this structured approach to organizing the different functional components
of an app, the maintainability of the project will not suffer as it grows in
size and complexity. A useful module can even be shared and reused as a library,
which is preferrable to pasting chunks of code that may have other messy
dependencies elsewhere in the project.

## Best Practices

In order to get the most out of the Pebble SDK, there are numerous opportunities
for optimization that can allow apps to use power more efficiently, display
correctly on all display shapes and sizes, and help keep large projects
maintainable. 

Information on these topics is contained in this collection of guides. Pebble
recommends that developers try and incorporate as many of these practices into
their apps as possible, to give themselves and users the best experience of
their app.

## Contents

