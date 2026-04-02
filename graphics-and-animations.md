# Graphics And Animations

> Information on using animations and drawing shapes, text, and images, as well as more advanced techniques.

## Animations

The ``Animation`` API allows a variety of different types of value to be
smoothly animated from an initial value to a new value over time. Animations can
also use built-in easing curves to affect how the transition behaves.

## Using PropertyAnimations

The most common use of animations is to move a ``Layer`` (or similar) around the
display. For example, to show or hide some information or animate the time
changing in a watchface.

The simplest method of animating a ``Layer`` (such as a ``TextLayer``) is to use
a ``PropertyAnimation``, which animates a property of the target object. In this
example, the target is the frame property, which is a ``GRect`` To animate the
this property, ``property_animation_create_layer_frame()`` is used, which is a
convenience ``PropertyAnimation`` implementation provided by the SDK.

```c
static Layer *s_layer;
```

Create the Layer during ``Window`` initialization:

```c
// Create the Layer
s_layer = layer_create(some_bounds);
```

Determine the start and end values of the ``Layer``'s frame. These are the
'from' and 'to' locations and sizes of the ``Layer`` before and after the
animation takes place:

```c
// The start and end frames - move the Layer 40 pixels to the right
GRect start = GRect(10, 10, 20, 20);
GRect finish = GRect(50, 10, 20, 20);
```

At the appropriate time, create a ``PropertyAnimation`` to animate the
``Layer``, specifying the `start` and `finish` values as parameters:

```c
// Animate the Layer
PropertyAnimation *prop_anim = property_animation_create_layer_frame(s_layer, 
                                                               &start, &finish);
```

Configure the attributes of the ``Animation``, such as the delay before
starting, and total duration (in milliseconds):

```c
// Get the Animation
Animation *anim = property_animation_get_animation(prop_anim);

// Choose parameters
const int delay_ms = 1000;
const int duration_ms = 500;

// Configure the Animation's curve, delay, and duration
animation_set_curve(anim, AnimationCurveEaseOut);
animation_set_delay(anim, delay_ms);
animation_set_duration(anim, duration_ms);
```

Finally, schedule the ``Animation`` to play at the next possible opportunity
(usually immediately):

```c
// Play the animation
animation_schedule(anim);
```

If the app requires knowledge of the start and end times of an ``Animation``, it
is possible to register ``AnimationHandlers`` to be notified of these events.
The handlers should be created with the signature of these examples shown below:

```c
static void anim_started_handler(Animation *animation, void *context) {
  APP_LOG(APP_LOG_LEVEL_DEBUG, "Animation started!");
}

static void anim_stopped_handler(Animation *animation, bool finished, void *context) {
  APP_LOG(APP_LOG_LEVEL_DEBUG, "Animation stopped!");
}
```

Register the handlers with an optional third context parameter **before**
scheduling the ``Animation``:

```c
// Set some handlers
animation_set_handlers(anim, (AnimationHandlers) {
  .started = anim_started_handler,
  .stopped = anim_stopped_handler
}, NULL);
```

With the handlers registered, the start and end times of the ``Animation`` can
be detected by the app and used as appropriate.

### Other Types of PropertyAnimation

In addition to ``property_animation_create_layer_frame()``, it is also possible
to animate the origin of a ``Layer``'s bounds using
``property_animation_create_bounds_origin()``. Animation of more types of data
can be achieved using custom implementations and one the following provided
update implementations and the associated 
[getters and setters](``property_animation_update_int16``):

* ``property_animation_update_int16`` - Animate an `int16`.
* ``property_animation_update_uint32`` - Animate a `uint32`.
* ``property_animation_update_gpoint`` - Animate a ``GPoint``.
* ``property_animation_update_grect`` - Animate a ``GRect``
* ``property_animation_update_gcolor8`` - Animate a ``GColor8``.

## Custom Animation Implementations

Beyond the convenience functions provided by the SDK, apps can implement their
own ``Animation`` by using custom callbacks for each stage of the animation
playback process. A ``PropertyAnimation`` is an example of such an
implementation.

The callbacks to implement are the `.setup`, `.update`, and `.teardown` members
of an ``AnimationImplementation`` object. Some example implementations are shown
below. It is in the `.update` callback where the value of `progress` can be used
to modify the custom target of the animation. For example, some percentage of
completion:

```c
static void implementation_setup(Animation *animation) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Animation started!");
}

static void implementation_update(Animation *animation, 
                                  const AnimationProgress progress) {
  // Animate some completion variable
  s_animation_percent = ((int)progress * 100) / ANIMATION_NORMALIZED_MAX;
  
  APP_LOG(APP_LOG_LEVEL_INFO, "Animation progress: %d%%", s_animation_percent);
}

static void implementation_teardown(Animation *animation) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Animation finished!");
}

// This needs to exist while the event loop runs
static const AnimationImplementation s_implementation = {
  .setup = implementation_setup,
  .update = implementation_update,
  .teardown = implementation_teardown
};
```

Once these are in place, create a new ``Animation`` , specifying the new custom
implementation as a `const` object pointer at the appropriate time:

```c
// Create a new Animation
Animation *animation = animation_create();
animation_set_delay(animation, 1000);
animation_set_duration(animation, 1000);

// Create the AnimationImplementation
animation_set_implementation(animation, &s_implementation);

// Play the Animation
animation_schedule(animation);
```

The output of the example above will look like the snippet shown below (edited
for brevity). Note the effect of the easing ``AnimationCurve`` on the progress
value:

```nc|text
[13:42:33] main.c:11> Animation started!
[13:42:34] main.c:19> Animation progress: 0%
[13:42:34] main.c:19> Animation progress: 0%
[13:42:34] main.c:19> Animation progress: 0%
[13:42:34] main.c:19> Animation progress: 2%
[13:42:34] main.c:19> Animation progress: 3%
[13:42:34] main.c:19> Animation progress: 5%
[13:42:34] main.c:19> Animation progress: 7%
[13:42:34] main.c:19> Animation progress: 10%
[13:42:34] main.c:19> Animation progress: 14%
[13:42:35] main.c:19> Animation progress: 17%
[13:42:35] main.c:19> Animation progress: 21%
[13:42:35] main.c:19> Animation progress: 26%

...

[13:42:35] main.c:19> Animation progress: 85%
[13:42:35] main.c:19> Animation progress: 88%
[13:42:35] main.c:19> Animation progress: 91%
[13:42:35] main.c:19> Animation progress: 93%
[13:42:35] main.c:19> Animation progress: 95%
[13:42:35] main.c:19> Animation progress: 97%
[13:42:35] main.c:19> Animation progress: 98%
[13:42:35] main.c:19> Animation progress: 99%
[13:42:35] main.c:19> Animation progress: 99%
[13:42:35] main.c:19> Animation progress: 100%
[13:42:35] main.c:23> Animation finished!
```

## Timers

[`AppTimer`](``Timer``) objects can be used to schedule updates to variables and
objects at a later time. They can be used to implement frame-by-frame animations
as an alternative to using the ``Animation`` API. They can also be used in a
more general way to schedule events to occur at some point in the future (such
as UI updates) while the app is open.

A thread-blocking alternative for small pauses is ``psleep()``, but this is
**not** recommended for use in loops updating UI (such as a counter), or for
scheduling ``AppMessage`` messages, which rely on the event loop to do their
work.

> Note: To create timed events in the future that persist after an app is
> closed, check out the ``Wakeup`` API.

When a timer elapses, it will call a developer-defined ``AppTimerCallback``.
This is where the code to be executed after the timed interval should be placed.
The callback will only be called once, so use this opportunity to re-register
the timer if it should repeat.

```c
static void timer_callback(void *context) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Timer elapsed!");
}
```

Schedule the timer with a specific `delay` interval, the name of the callback to
fire, and an optional context pointer:

```c
const int delay_ms = 5000;

// Schedule the timer
app_timer_register(delay_ms, timer_callback, NULL);
```

If the timer may need to be cancelled or rescheduled at a later time, ensure a
reference to it is kept for later use:

```c
static AppTimer *s_timer;
```

```c
// Register the timer, and keep a handle to it
s_timer = app_timer_register(delay_ms, timer_callback, NULL);
```

If the timer needs to be cancelled, use the previous reference. If it has
already elapsed, nothing will occur:

```c
// Cancel the timer
app_timer_cancel(s_timer);
```

## Sequence and Spawn Animations

The Pebble SDK also includes the capability to build up composite animations
built from other ``Animation`` objects. There are two types: a
sequence animation and a spawn animation.

* A sequence animation is a set of two or more other animations that are played
  out in **series** (one after another). For example, a pair of timed animations
  to show and hide a ``Layer``.

* A spawn animation is a set of two or more other animations that are played out
  in **parallel**. A spawn animation acts the same as creating and starting two
  or more animations at the same time, but has the advantage that it can be
  included as part of a sequence animation.

> Note: Composite animations can be composed of other composite animations.

### Important Considerations

When incorporating an ``Animation`` into a sequence or spawn animation, there
are a couple of points to note:

* Any single animation cannot appear more than once in the list of animations
  used to create a more complex animation.

* A composite animation assumes ownership of its component animations once it
  has been created.

* Once an animation has been added to a composite animation, it becomes
  immutable. This means it can only be read, and not written to. Attempts to
  modify such an animation after it has been added to a composite animation will
  fail.

* Once an animation has been added to a composite animation, it cannot then be
  used to build a different composite animation.

### Creating a Sequence Animation

To create a sequence animation, first create the component ``Animation`` objects
that will be used to build it.

```c
// Create the first Animation
PropertyAnimation *prop_anim = property_animation_create_layer_frame(s_layer, 
                                                               &start, &finish);
Animation *animation_a = property_animation_get_animation(prop_anim);

// Set some properties
animation_set_delay(animation_a, 1000);
animation_set_duration(animation_a, 500);

// Clone the first, modify the duration and reverse it.
Animation *animation_b = animation_clone(animation_a);
animation_set_reverse(animation_b, true);
animation_set_duration(animation_b, 1000);
```

Use these component animations to create the sequence animation. You can either
specify the components as a list or pass an array. Both approaches are shown
below.

#### Using a List

You can specify up to 20 ``Animation`` objects as parameters to
`animation_sequence_create()`. The list must always be terminated with `NULL` to
mark the end.

```c
// Create the sequence
Animation *sequence = animation_sequence_create(animation_a, animation_b, NULL);

// Play the sequence
animation_schedule(sequence);
```

#### Using an Array

You can also specify the component animations using a dynamically allocated
array. Give this to `animation_sequence_create_from_array()` along with the size
of the array.

```c
const uint32_t array_length = 2;

// Create the array
Animation **arr = (Animation**)malloc(array_length * sizeof(Animation*));
arr[0] = animation_a;
arr[1] = animation_b;

// Create the sequence, set to loop forever
Animation *sequence = animation_sequence_create_from_array(arr, array_length);
animation_set_play_count(sequence, ANIMATION_DURATION_INFINITE);

// Play the sequence
animation_schedule(sequence);

// Destroy the array
free(arr);
```

### Creating a Spawn Animation

Creating a spawn animation is done in a very similiar way to a sequence
animation. The animation is built up from component animations which are then
all started at the same time. This simplifies the task of precisely timing
animations that are designed to coincide.

The first step is the same as for sequence animations, which is to create a
number of component animations to be spawned together.

```c
// Create the first animation
Animation *animation_a = animation_create();
animation_set_duration(animation_a, 1000);

// Clone the first, modify the duration and reverse it.
Animation *animation_b = animation_clone(animation_a);
animation_set_reverse(animation_b, true);
animation_set_duration(animation_b, 300);
```

Next, the spawn animation is created in a similar manner to the sequence
animation with a `NULL` terminated list of parameters:

```c
// Create the spawn animation
Animation *spawn = animation_spawn_create(animation_a, animation_b, NULL);

// Play the animation
animation_schedule(spawn);
```

Alternatively the spawn animation can be created with an array of ``Animation``
objects.

```c
const uint32_t array_length = 2;

// Create the array
Animation **arr = (Animation**)malloc(array_length * sizeof(Animation*));
arr[0] = animation_a;
arr[1] = animation_b;

// Create the sequence and set the play count to 3
Animation *spawn = animation_spawn_create_from_array(arr, array_length);
animation_set_play_count(spawn, 3);

// Play the spawn animation
animation_schedule(spawn);

// Destroy the array
free(arr);
```

## Drawing Primitives, Images and Text

While ``Layer`` types such as ``TextLayer`` and ``BitmapLayer`` allow easy
rendering of text and bitmaps, more precise drawing can be achieved through the
use of the ``Graphics Context`` APIs. Custom drawing of primitive shapes such as
line, rectangles, and circles is also supported. Clever use of these functions
can remove the need to pre-prepare bitmap images for many UI elements and icons.

## Obtaining a Drawing Context

All custom drawing requires a ``GContext`` instance. These cannot be created,
and are only available inside a ``LayerUpdateProc``. This update procedure is
simply a function that is called when a ``Layer`` is to be rendered, and is
defined by the developer as opposed to the system. For example, a
``BitmapLayer`` is simply a ``Layer`` with a ``LayerUpdateProc`` abstracted away
for convenience by the SDK.

First, create the ``Layer`` that will have a custom drawing procedure:

```c
static Layer *s_canvas_layer;
```

Allocate the ``Layer`` during ``Window`` creation:

```c
GRect bounds = layer_get_bounds(window_get_root_layer(window));

// Create canvas layer
s_canvas_layer = layer_create(bounds);
```

Next, define the ``LayerUpdateProc`` according to the function specification:

```c
static void canvas_update_proc(Layer *layer, GContext *ctx) {
  // Custom drawing happens here!

}
```

Assign this procedure to the canvas layer and add it to the ``Window`` to make
it visible:

```c
// Assign the custom drawing procedure
layer_set_update_proc(s_canvas_layer, canvas_update_proc);

// Add to Window
layer_add_child(window_get_root_layer(window), s_canvas_layer);
```

From now on, every time the ``Layer`` needs to be redrawn (for example, if other
layer geometry changes), the ``LayerUpdateProc`` will be called to allow the
developer to draw it. It can also be explicitly marked for redrawing at the next
opportunity:

```c
// Redraw this as soon as possible
layer_mark_dirty(s_canvas_layer);
```

## Drawing Primitive Shapes

The ``Graphics Context`` API allows drawing and filling of lines, rectangles,
circles, and arbitrary paths. For each of these, the colors of the output can be
set using the appropriate function:

```c
// Set the line color
graphics_context_set_stroke_color(ctx, GColorRed);

// Set the fill color
graphics_context_set_fill_color(ctx, GColorBlue);
```

In addition, the stroke width and antialiasing mode can also be changed:

```c
// Set the stroke width (must be an odd integer value)
graphics_context_set_stroke_width(ctx, 5);

// Disable antialiasing (enabled by default where available)
graphics_context_set_antialiased(ctx, false);
```

### Lines

Drawing a simple line requires only the start and end positions, expressed as
``GPoint`` values:

```c
GPoint start = GPoint(10, 10);
GPoint end = GPoint(40, 60);

// Draw a line
graphics_draw_line(ctx, start, end);
```

### Rectangles

Drawing a rectangle requires a bounding ``GRect``, as well as other parameters
if it is to be filled:

```c
GRect rect_bounds = GRect(10, 10, 40, 60);

// Draw a rectangle
graphics_draw_rect(ctx, rect_bounds);

// Fill a rectangle with rounded corners
int corner_radius = 10;
graphics_fill_rect(ctx, rect_bounds, corner_radius, GCornersAll);
```

It is also possible to draw a rounded unfilled rectangle:

```c
// Draw outline of a rounded rectangle
graphics_draw_round_rect(ctx, rect_bounds, corner_radius);
```

### Circles

Drawing a circle requries its center ``GPoint`` and radius:

```c
GPoint center = GPoint(25, 25);
uint16_t radius = 50;

// Draw the outline of a circle
graphics_draw_circle(ctx, center, radius);

// Fill a circle
graphics_fill_circle(ctx, center, radius);
```

In addition, it is possble to draw and fill arcs. In these cases, the
``GOvalScaleMode`` determines how the shape is adjusted to fill the rectangle,
and the cartesian angle values are transformed to preserve accuracy:

```c
int32_t angle_start = DEG_TO_TRIGANGLE(0);
int32_t angle_end = DEG_TO_TRIGANGLE(45);

// Draw an arc
graphics_draw_arc(ctx, rect_bounds, GOvalScaleModeFitCircle, angle_start, 
                                                                    angle_end);
```

Lastly, a filled circle with a sector removed can also be drawn in a similar
manner. The value of `inset_thickness` determines the inner inset size that is
removed from the full circle:

```c
uint16_t inset_thickness = 10; 

// Fill a radial section of a circle
graphics_fill_radial(ctx, rect_bounds, GOvalScaleModeFitCircle, inset_thickness,
                                                        angle_start, angle_end);
```

For more guidance on using round elements in apps, watch the presentation given
at the 2015 Developer Retreat on 
[developing for Pebble Time Round](https://www.youtube.com/watch?v=3a1V4n9HDvY).

## Bitmaps

Manually drawing ``GBitmap`` images with the ``Graphics Context`` API is a
simple task, and has much in common with the alternative approach of using a
``BitmapLayer`` (which provides additional convenience funcionality).

The first step is to load the image data from resources (read 
 to learn how to include images in a
Pebble project):

```c
static GBitmap *s_bitmap;
```

```c
// Load the image data
s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);
```

When the appropriate ``LayerUpdateProc`` is called, draw the image inside the
desired rectangle:

> Note: Unlike ``BitmapLayer``, the image will be drawn relative to the
> ``Layer``'s origin, and not centered.

```c
// Get the bounds of the image
GRect bitmap_bounds = gbitmap_get_bounds(s_bitmap);

// Set the compositing mode (GCompOpSet is required for transparency)
graphics_context_set_compositing_mode(ctx, GCompOpSet);

// Draw the image
graphics_draw_bitmap_in_rect(ctx, s_bitmap, bitmap_bounds);
```

Once the image is no longer needed (i.e.: the app is exiting), free the data:

```c
// Destroy the image data
gbitmap_destroy(s_bitmap);
```

## Drawing Text

Similar to the ``TextLayer`` UI component, a ``LayerUpdateProc`` can also be
used to draw text. Advantages can include being able to draw in multiple fonts
with only one ``Layer`` and combining text with other drawing operations.

The first operation to perform inside the ``LayerUpdateProc`` is to get or load
the font to be used for drawing and set the text's color:

```c
// Load the font
GFont font = fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD);
// Set the color
graphics_context_set_text_color(ctx, GColorBlack);
```

Next, determine the bounds that will guide the text's position and overflow
behavior. This can either be the size of the ``Layer``, or a more precise bounds
of the text itself. This information can be useful for drawing multiple text
items after one another with automatic spacing.

```c
char *text = "Example test string for the Developer Website guide!";

// Determine a reduced bounding box
GRect layer_bounds = layer_get_bounds(layer);
GRect bounds = GRect(layer_bounds.origin.x, layer_bounds.origin.y,
                     layer_bounds.size.w / 2, layer_bounds.size.h);

// Calculate the size of the text to be drawn, with restricted space
GSize text_size = graphics_text_layout_get_content_size(text, font, bounds,
                              GTextOverflowModeWordWrap, GTextAlignmentCenter);
```

Finally, the text can be drawn into the appropriate bounding rectangle:

```c
// Draw the text
graphics_draw_text(ctx, text, font, bounds, GTextOverflowModeWordWrap, 
                                            GTextAlignmentCenter, NULL);
```

## Framebuffer Graphics

In the context of a Pebble app, the framebuffer is the data region used to store
the contents of the what is shown on the display. Using the ``Graphics Context``
API allows developers to draw primitive shapes and text, but at a slower speed
and with a restricted set of drawing patterns. Getting direct access to the
framebuffer allows arbitrary transforms, special effects, and other
modifications to be applied to the display contents, and allows drawing at a
much greater speed than standard SDK APIs.

## Accessing the Framebuffer

Access to the framebuffer can only be obtained during a ``LayerUpdateProc``,
when redrawing is taking place. When the time comes to update the associated
``Layer``, the framebuffer can be obtained as a ``GBitmap``:

```c
static void layer_update_proc(Layer *layer, GContext *ctx) {
  // Get the framebuffer
  GBitmap *fb = graphics_capture_frame_buffer(ctx);

  // Manipulate the image data...

  // Finally, release the framebuffer
  graphics_release_frame_buffer(ctx, fb);
}
```

> Note: Once obtained, the framebuffer **must** be released back to the app so
> that it may continue drawing.

The format of the data returned will vary by platform, as will the
representation of a single pixel, shown in the table below.

| Platform | Framebuffer Bitmap Format | Pixel Format |
|:--------:|---------------------------|--------------|
| Aplite | ``GBitmapFormat1Bit`` | One bit (black or white) |
| Basalt | ``GBitmapFormat8Bit`` | One byte (two bits per color) |
| Chalk | ``GBitmapFormat8BitCircular`` | One byte (two bits per color) |

## Modifying the Framebuffer Data

Once the framebuffer has been captured, the underlying data can be manipulated
on a row-by-row or even pixel-by-pixel basis. This data region can be obtained
using ``gbitmap_get_data()``, but the recommended approach is to make use of
``gbitmap_get_data_row_info()`` objects to cater for platforms (such as Chalk),
where not every row is of the same width. The ``GBitmapDataRowInfo`` object
helps with this by providing a `min_x` and `max_x` value for each `y` used to
build it.

To iterate over all rows and columns, safely avoiding those with irregular start
and end indices, use two nested loops as shown below. The implementation of
`set_pixel_color()` is shown in 
[*Getting and Setting Pixels*](#getting-and-setting-pixels):

> Note: it is only necessary to call ``gbitmap_get_data_row_info()`` once per
> row. Calling it more often (such as for every pixel) will incur a sigificant
> speed penalty.

```c
GRect bounds = layer_get_bounds(layer);

// Iterate over all rows
for(int y = 0; y < bounds.size.h; y++) {
  // Get this row's range and data
  GBitmapDataRowInfo info = gbitmap_get_data_row_info(fb, y);

  // Iterate over all visible columns
  for(int x = info.min_x; x <= info.max_x; x++) {
    // Manipulate the pixel at x,y...
    const GColor random_color = (GColor){ .argb = rand() % 255 };

    // ...to be a random color
    set_pixel_color(info, GPoint(x, y), random_color);
  }
}
```

## Getting and Setting Pixels

To modify a pixel's value, simply set a new value at the appropriate position in
the `data` field of that row's ``GBitmapDataRowInfo`` object. This will modify
the underlying data, and update the display once the frame buffer is released.

This process will be different depending on the ``GBitmapFormat`` of the
captured framebuffer. On a color platform, each pixel is stored as a single
byte. However, on black and white platforms this will be one bit per byte. Using
``memset()`` to read or modify the correct pixel on a black and white display
requires a bit more logic, shown below:

```c
static GColor get_pixel_color(GBitmapDataRowInfo info, GPoint point) {
#if defined(PBL_COLOR)
  // Read the single byte color pixel
  return (GColor){ .argb = info.data[point.x] };
#elif defined(PBL_BW)
  // Read the single bit of the correct byte
  uint8_t byte = point.x / 8;
  uint8_t bit = point.x % 8; 
  return byte_get_bit(&info.data[byte], bit) ? GColorWhite : GColorBlack;
#endif
}
```

Setting a pixel value is achieved in much the same way, with different logic
depending on the format of the framebuffer on each platform:

```c
static void set_pixel_color(GBitmapDataRowInfo info, GPoint point, 
                                                                GColor color) {
#if defined(PBL_COLOR)
  // Write the pixel's byte color
  memset(&info.data[point.x], color.argb, 1);
#elif defined(PBL_BW)
  // Find the correct byte, then set the appropriate bit
  uint8_t byte = point.x / 8;
  uint8_t bit = point.x % 8; 
  byte_set_bit(&info.data[byte], bit, gcolor_equal(color, GColorWhite) ? 1 : 0);
#endif
}
```

The `byte_get_bit()` and `byte_set_bit()` implementations are shown here for
convenience:

```c
static bool byte_get_bit(uint8_t *byte, uint8_t bit) {
  return ((*byte) >> bit) & 1;
}

static void byte_set_bit(uint8_t *byte, uint8_t bit, uint8_t value) {
  *byte ^= (-value ^ *byte) & (1 << bit);
}
```

## Learn More

To see an example of what can be achieved with direct access to the framebuffer
and learn more about the underlying principles, watch the 
[talk given at the 2014 Developer Retreat](https://www.youtube.com/watch?v=lYoHh19RNy4).

[EMBED](//www.youtube.com/watch?v=lYoHh19RNy4)

## Vector Graphics

This is an overview of drawing vector images using Pebble Draw Command files.
See the [*Vector Animations*](/tutorials/advanced/vector-animations) tutorial
for more information.

## Vector Graphics on Pebble

As opposed to bitmaps which contain data for every pixel to be drawn, a vector
file contains only instructions about points contained in the image and how to
draw lines connecting them up. Instructions such as fill color, stroke color,
and stroke width are also included.

Vector images on Pebble are implemented using the ``Draw Commands`` API, which
allows apps to load and display PDC (Pebble Draw Command) images and sequences
that contain sets of these instructions. An example is the weather icon used in
weather timeline pins. The benefit of using vector graphics for this icon is
that is allows the image to stretch in the familiar manner as it moves between
the timeline view and the pin detail view:

![weather >{pebble-screenshot,pebble-screenshot--time-red}](/images/tutorials/advanced/weather.png)

The main benefits of vectors over bitmaps for simple images and icons are:

* Smaller resource size - instructions for joining points are less memory
  expensive than per-pixel bitmap data.

* Flexible rendering - vector images can be rendered as intended, or manipulated
  at runtime to move the individual points around. This allows icons to appear
  more organic and life-like than static PNG images. Scaling and distortion is
  also made possible.

However, there are also some drawbacks to choosing vector images in certain
cases:

* Vector files require more specialized tools to create than bitmaps, and so are
  harder to produce.

* Complicated vector files may take more time to render than if they were simply
  drawn per-pixel as a bitmap, depending on the drawing implementation.

## Creating Compatible Files

The file format of vector image files on Pebble is the PDC (Pebble Draw Command)
format, which includes all the instructions necessary to allow drawing of
vectors. These files are created from compatible SVG (Scalar Vector Graphics)
files. Read  for more
information.

<div class="alert alert--fg-white alert--bg-dark-red">
Pebble Draw Command files can only be used from app resources, and cannot be
created at runtime.
</div>

## Drawing Vector Graphics

Add the PDC file to the project resources in `package.json` with the
'type' field to `raw`:

```json
"media": [
  {
    "type": "raw",
    "name": "EXAMPLE_IMAGE",
    "file": "example_image.pdc"
  }
]
```

Drawing a Pebble Draw Command image is just as simple as drawing a normal
PNG image to a graphics context, requiring only one draw call. First, load the
`.pdc` file from resources as shown below.

First, declare a pointer of type ``GDrawCommandImage`` at the top of the file:

```c
static GDrawCommandImage *s_command_image;
```

Create and assign the ``GDrawCommandImage`` in `init()`, before calling
`window_stack_push()`:

```nc|c
// Create the object from resource file
s_command_image = gdraw_command_image_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);
```

Next, define the ``LayerUpdateProc`` that will be used to draw the PDC image:

```c
static void update_proc(Layer *layer, GContext *ctx) {
  // Set the origin offset from the context for drawing the image
  GPoint origin = GPoint(10, 20);

  // Draw the GDrawCommandImage to the GContext
  gdraw_command_image_draw(ctx, s_command_image, origin);
}
```

Next, create a ``Layer`` to display the image:

```c
static Layer *s_canvas_layer;
```

Assign the ``LayerUpdateProc`` that will do the rendering to the canvas
``Layer`` and add it to the desired ``Window`` during `window_load()`:

```c
// Create the canvas Layer
s_canvas_layer = layer_create(GRect(30, 30, bounds.size.w, bounds.size.h));

// Set the LayerUpdateProc
layer_set_update_proc(s_canvas_layer, update_proc);

// Add to parent Window
layer_add_child(window_layer, s_canvas_layer);
```

Finally, don't forget to free the memory used by the sub-components of the
``Window`` in `main_window_unload()`:

```c
// Destroy the canvas Layer
layer_destroy(s_canvas_layer);

// Destroy the PDC image
gdraw_command_image_destroy(s_command_image);
```

When run, the PDC image will be loaded, and rendered in the ``LayerUpdateProc``.
To put the image into contrast, optionally change the ``Window`` background
color after `window_create()`:

```c
window_set_background_color(s_main_window, GColorBlueMoon);
```

The result will look similar to the example shown below.

![weather-image >{pebble-screenshot,pebble-screenshot--time-red}](/images/tutorials/advanced/weather-image.png)

## Graphics and Animations

The Pebble SDK allows drawing of many types of graphics in apps. Using the
``Graphics Context``, ``GBitmap``, ``GDrawCommand`` and
[`Framebuffer`](``graphics_capture_frame_buffer``) APIs gives developers
complete control over the contents of the display, and also can be used to
complement UI created with the various types of ``Layer`` available to enable
more complex UI layouts.

Both image-based and property-based animations are available, as well as
scheduling regular updates to UI components with ``Timer`` objects. Creative use
of ``Animation`` and ``PropertyAnimation`` can help to delight and engage users,
as well as highlight important information inside apps.

## Contents

