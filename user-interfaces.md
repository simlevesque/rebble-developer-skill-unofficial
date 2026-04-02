# User Interfaces

> How to build app user interfaces. Includes information on events, persistent storage, background worker, wakeups and app configuration.

## App Configuration

Many watchfaces and watchapps in the Pebble appstore include the ability to
customize their behavior or appearance through the use of a configuration page.

[Clay for Pebble](https://github.com/pebble-dev/clay) is the recommended approach
for creating configuration pages, and is what will be covered in this guide.
If you need to host your own configuration pages, please follow our
 guide.

![Clay Sample](/images/guides/user-interfaces/app-configuration/clay-sample.png =200)

Clay for Pebble dramatically simplifies the process of creating a configuration
page, by allowing developers to define their application settings using a
simple [JSON](https://en.wikipedia.org/wiki/JSON) file. Clay processes the
JSON file and then dynamically generates a configuration page which matches the
existing style of the Pebble mobile application, and it even works without an
Internet connection.

## Enabling Configuration

For an app to be configurable, it must include the 'configurable' item in
`package.json`.

```json
"capabilities": [ "configurable" ]
```

The presence of this value tells the mobile app to display the gear icon that
is associated with the ability to launch the config page next to the app itself.

## Installing Clay

Clay is available as a , so it
takes minimal effort to install.

Within your project folder, just type:

```nc|text
$ pebble package install @rebble/clay
```

## Choosing messageKeys

When passing data between the configuration page and the watch application, we
define `messageKeys` to help us easily identify the different values.

In this example, we're going to allow users to control the background color,
foreground color, whether the watchface ticks on seconds and whether any
animations are displayed.

We define `messageKeys` in the `package.json` file for each configuration
setting in our application:

```json
"messageKeys": [
  "BackgroundColor",
  "ForegroundColor",
  "SecondTick",
  "Animations"
]
```

## Creating the Clay Configuration

The Clay configuration file (`config.js`) should be created in your
`src/pkjs/` folder. It allows the easy definition of each type of HTML form
entity that is required. These types include:

* [Section](https://github.com/pebble-dev/clay#section)
* [Heading](https://github.com/pebble-dev/clay#heading)
* [Text](https://github.com/pebble-dev/clay#text)
* [Input](https://github.com/pebble-dev/clay#input)
* [Toggle](https://github.com/pebble-dev/clay#toggle)
* [Select](https://github.com/pebble-dev/clay#select)
* [Color Picker](https://github.com/pebble-dev/clay#color-picker)
* [Radio Group](https://github.com/pebble-dev/clay#radio-group)
* [Checkbox Group](https://github.com/pebble-dev/clay#checkbox-group)
* [Generic Button](https://github.com/pebble-dev/clay#generic-button)
* [Range Slider](https://github.com/pebble-dev/clay#range-slider)
* [Submit Button](https://github.com/pebble-dev/clay#submit)

In our example configuration page, we will add some introductory text, and group
our fields into two sections. All configuration pages must have a submit button
at the end, which is used to send the JSON data back to the watch.

![Clay](/images/guides/user-interfaces/app-configuration/clay-actual.png =200)

Now start populating the configuration file with the sections you require, then
add the required elements to each section. Be sure to assign the correct
`messageKey` to each field.

```js
module.exports = [
  {
    "type": "heading",
    "defaultValue": "App Configuration"
  },
  {
    "type": "text",
    "defaultValue": "Here is some introductory text."
  },
  {
    "type": "section",
    "items": [
      {
        "type": "heading",
        "defaultValue": "Colors"
      },
      {
        "type": "color",
        "messageKey": "BackgroundColor",
        "defaultValue": "0x000000",
        "label": "Background Color"
      },
      {
        "type": "color",
        "messageKey": "ForegroundColor",
        "defaultValue": "0xFFFFFF",
        "label": "Foreground Color"
      }
    ]
  },
  {
    "type": "section",
    "items": [
      {
        "type": "heading",
        "defaultValue": "More Settings"
      },
      {
        "type": "toggle",
        "messageKey": "SecondTick",
        "label": "Enable Seconds",
        "defaultValue": false
      },
      {
        "type": "toggle",
        "messageKey": "Animations",
        "label": "Enable Animations",
        "defaultValue": false
      }
    ]
  },
  {
    "type": "submit",
    "defaultValue": "Save Settings"
  }
];
```

## Initializing Clay

To initialize Clay, all you need to do is add the following JavaScript into
your `index.js` file.

```js
// Import the Clay package
var Clay = require('@rebble/clay');
// Load our Clay configuration file
var clayConfig = require('./config');
// Initialize Clay
var clay = new Clay(clayConfig);
```

> When using the local SDK, it is possible to use a pure JSON
> configuration file (`config.json`). If this is the case, you must not include
> the `module.exports = []` in your configuration file, and you need to
> `var clayConfig = require('./config.json');`

## Receiving Config Data

Within our watchapp we need to open a connection with ``AppMessage`` to begin
listening for data from Clay, and also provide a handler to process the data
once it has been received.

```c
void prv_init(void) {
  // ...

  // Open AppMessage connection
  app_message_register_inbox_received(prv_inbox_received_handler);
  app_message_open(128, 128);

  // ...
}
```

Once triggered, our handler will receive a ``DictionaryIterator`` containing
``Tuple`` objects for each `messageKey`. Note that the key names need to be
prefixed with `MESSAGE_KEY_`.

```c
static void prv_inbox_received_handler(DictionaryIterator *iter, void *context) {
  // Read color preferences
  Tuple *bg_color_t = dict_find(iter, MESSAGE_KEY_BackgroundColor);
  if(bg_color_t) {
    GColor bg_color = GColorFromHEX(bg_color_t->value->int32);
  }

  Tuple *fg_color_t = dict_find(iter, MESSAGE_KEY_ForegroundColor);
  if(fg_color_t) {
    GColor fg_color = GColorFromHEX(fg_color_t->value->int32);
  }

  // Read boolean preferences
  Tuple *second_tick_t = dict_find(iter, MESSAGE_KEY_SecondTick);
  if(second_tick_t) {
    bool second_ticks = second_tick_t->value->int32 == 1;
  }

  Tuple *animations_t = dict_find(iter, MESSAGE_KEY_Animations);
  if(animations_t) {
    bool animations = animations_t->value->int32 == 1;
  }

}
```

## Persisting Settings

By default, Clay will persist your settings in localStorage within the
mobile application. It is common practice to also save settings within the
persistent storage on the watch. This creates a seemless experience for users
launching your application, as their settings can be applied on startup. This
means there isn't an initial delay while the settings are loaded from the phone.

You could save each individual value within the persistent storage, or you could
create a struct to hold all of your settings, and save that entire object. This
has the benefit of simplicity, and because writing to persistent storage is
slow, it also provides improved performance.

```c
// Persistent storage key
#define SETTINGS_KEY 1

// Define our settings struct
typedef struct ClaySettings {
  GColor BackgroundColor;
  GColor ForegroundColor;
  bool SecondTick;
  bool Animations;
} ClaySettings;

// An instance of the struct
static ClaySettings settings;

// AppMessage receive handler
static void prv_inbox_received_handler(DictionaryIterator *iter, void *context) {
  // Assign the values to our struct
  Tuple *bg_color_t = dict_find(iter, MESSAGE_KEY_BackgroundColor);
  if (bg_color_t) {
    settings.BackgroundColor = GColorFromHEX(bg_color_t->value->int32);
  }
  // ...
  prv_save_settings();
}

// Save the settings to persistent storage
static void prv_save_settings() {
  persist_write_data(SETTINGS_KEY, &settings, sizeof(settings));
}
```

You can see a complete implementation of persisting a settings struct in the
[Pebble Clay Example](/clay-example).

## What's Next

If you're thinking that Clay won't be as flexible as hand crafting your own
configuration pages, you're mistaken.

Developers can extend the functionality of Clay in a number of ways:

* Define a
[custom function](https://github.com/pebble-dev/clay#custom-function) to enhance the
interactivity of the page.
* [Override events](https://github.com/pebble-dev/clay#handling-the-showconfiguration-and-webviewclosed-events-manually)
and transform the format of the data before it's transferred to the watch.
* Create and share your own
[custom components](https://github.com/pebble-dev/clay#custom-components).

Why not find out more about [Clay for Pebble](https://github.com/pebble-dev/clay)
and perhaps even
[contribute](https://github.com/pebble-dev/clay/blob/master/CONTRIBUTING.md) to the
project, it's open source!

## App Configuration (manual setup)

> This guide provides the steps to manually create an app configuration page.
> The preferred approach is to use
>  instead.

Many watchfaces and apps in the Pebble appstore include the ability to customize
their behavior or appearance through the use of a configuration page. This
mechanism consists of an HTML form that passes the user's chosen configuration
data to PebbleKit JS, which in turn relays it to the watchface or watchapp.

The HTML page created needs to be hosted online, so that it is accessible to
users via the Pebble application. If you do not want to host your own HTML
page, you should follow the
 to create a
local config page.

App configuration pages are powered by PebbleKit JS. To find out more about
PebbleKit JS,
.

## Adding Configuration

For an app to be configurable, it must marked as 'configurable' in the
app's 
`capabilities` array. The presence of this value tells the mobile app to
display a gear icon next to the app, allowing users to access the configuration
page.

```json
"capabilities": [ "configurable" ]
```

## Choosing Key Values

Since the config page must transmit the user's preferred options to the
watchapp, the first step is to decide upon the ``AppMessage`` keys defined in
`package.json` that will be used to represent the chosen value for each option
on the config page:

```json
"messageKeys": [
  "BackgroundColor",
  "ForegroundColor",
  "SecondTick",
  "Animations"
]
```

These keys will automatically be available both in C on the watch and in
PebbleKit JS on the phone.

Each of these keys will apply to the appropriate input element on the config
page, with the user's chosen value transmitted to the watchapp's
``AppMessageInboxReceived`` handler once the page is submitted.

## Showing the Config Page

Once an app is marked as `configurable`, the PebbleKit JS component must
implement `Pebble.openURL()` in the `showConfiguration` event handler in
`index.js` to present the developer's HTML page when the user wants to configure
the app:

```js
Pebble.addEventListener('showConfiguration', function() {
  var url = 'http://example.com/config.html';

  Pebble.openURL(url);
});
```

## Creating the Config Page

The basic structure of an HTML config page begins with a template HTML file:

> Note: This page will be plain and unstyled. CSS styling must be performed
> separately, and is not covered here.

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Example Configuration</title>
  </head>
  <body>
    <p>This is an example HTML forms configuration page.</p>
  </body>
</html>
```

The various UI elements the user will interact with to choose their preferences
must be placed within the `body` tag, and will most likely take the form of
HTML `input` elements. For example, a text input field for each of the example
color options will look like the following:

```html
<input id='background_color_input' type='text' value='#000000'>
  Background Color
</input>
<input id='foreground_color_input' type='text' value='#000000'>
  Foreground Color
</input>
```

Other components include checkboxes, such as the two shown below for each of
the example boolean options:

```html
<input id='second_tick_checkbox' type='checkbox'>
  Enable Second Ticks
</input>
<input id='animations_checkbox' type='checkbox'>
  Show Animations
</input>
```

The final element should be the 'Save' button, used to trigger the sending of
the user's preferences back to PebbleKit JS.

```html
<input id='submit_button' type='button' value='Save'>
```

## Submitting Config Data

Once the 'Save' button is pressed, the values of all the input elements should
be encoded and included in the return URL as shown below:

```html

```

> Note: Remember to use `encodeURIComponent()` and `decodeURIComponent()` to
> ensure the JSON data object is transmitted without error.

## Hosting the Config Page

In order for users to access your configuration page, it needs to be hosted
online somewhere. One potential free service to host your configuration page
is Github Pages:

[Github Pages](https://pages.github.com/) allow you to host your HTML, CSS and
JavaScript files and directly access them from a special branch within your
Github repo. This also has the added advantage of encouraging the use of
version control.

## Relaying Data through PebbleKit JS

When the user submits the HTML form, the page will close and the result is
passed to the `webviewclosed` event handler in the PebbleKit JS `index.js` file:

```js
Pebble.addEventListener('webviewclosed', function(e) {
  // Decode the user's preferences
  var configData = JSON.parse(decodeURIComponent(e.response));
}
```

The data from the config page should be converted to the appropriate keys and
value types expected by the watchapp, and sent via ``AppMessage``:

```js
// Send to the watchapp via AppMessage
var dict = {
  'BackgroundColor': configData.background_color,
  'ForegroundColor': configData.foreground_color,
  'SecondTick': configData.second_ticks,
  'Animations': configData.animations
};

// Send to the watchapp
Pebble.sendAppMessage(dict, function() {
  console.log('Config data sent successfully!');
}, function(e) {
  console.log('Error sending config data!');
});
```

## Receiving Config Data

Once the watchapp has called ``app_message_open()`` and registered an
``AppMessageInboxReceived`` handler, that handler will be called once the data
has arrived on the watch. This occurs once the user has pressed the submit
button.

To obtain the example keys and values shown in this guide, simply look for and
read the keys as ``Tuple`` objects using the ``DictionaryIterator`` provided:

```c
static void inbox_received_handler(DictionaryIterator *iter, void *context) {
  // Read color preferences
  Tuple *bg_color_t = dict_find(iter, MESSAGE_KEY_BackgroundColor);
  if(bg_color_t) {
    GColor bg_color = GColorFromHEX(bg_color_t->value->int32);
  }

  Tuple *fg_color_t = dict_find(iter, MESSAGE_KEY_ForegroundColor);
  if(fg_color_t) {
    GColor fg_color = GColorFromHEX(fg_color_t->value->int32);
  }

  // Read boolean preferences
  Tuple *second_tick_t = dict_find(iter, MESSAGE_KEY_SecondTick);
  if(second_tick_t) {
    bool second_ticks = second_tick_t->value->int32 == 1;
  }

  Tuple *animations_t = dict_find(iter, MESSAGE_KEY_Animations);
  if(animations_t) {
    bool animations = animations_t->value->int32 == 1;
  }

  // App should now update to take the user's preferences into account
  reload_config();
}
```

Read the  guides for more information about using
the ``AppMessage`` API.

If you're looking for a simpler option, we recommend using
 instead.

## App Exit Reason

Introduced in SDK v4.0, the ``AppExitReason`` API allows developers to provide a
reason when terminating their application. The system uses these reasons to
determine where the user should be sent when the current application terminates.

At present, there are only two ``AppExitReason`` states when exiting an application, but this may change in future updates.

### APP_EXIT_NOT_SPECIFIED

This is the default state and when the current watchapp terminates. The user is
returned to their previous location. If you do not specify an ``AppExitReason``,
this state will be used automatically.

```c
static void prv_deinit() {
    // Optional, default behavior
    // App will exit to the previous location in the system
    exit_reason_set(APP_EXIT_NOT_SPECIFIED);
}
```

### APP_EXIT_ACTION_PERFORMED_SUCCESSFULLY

This state is primarily provided for developers who are creating one click
action applications. When the current watchapp terminates, the user is returned
to the default watchface.

```c
static void prv_deinit() {
    // App will exit to default watchface
    exit_reason_set(APP_EXIT_ACTION_PERFORMED_SUCCESSFULLY);
}
```

## AppGlance C API

## Overview

An app's "glance" is the visual representation of a watchapp in the launcher and
provides glanceable information to the user. The ``App Glance`` API, added in SDK
4.0, enables developers to programmatically set the icon and subtitle that
appears alongside their app in the launcher.

> The ``App Glance`` API is only applicable to watchapps, it is not supported by
watchfaces.

## Glances and AppGlanceSlices

An app's glance can change over time, and is defined by zero or more
``AppGlanceSlice`` each consisting of a layout (including a subtitle and icon),
as well as an expiration time. AppGlanceSlices are displayed in the order they
were added, and will persist until their expiration time, or another call to
``app_glance_reload()``.

> To create an ``AppGlanceSlice`` with no expiration time, use
> ``APP_GLANCE_SLICE_NO_EXPIRATION``

Developers can change their watchapp’s glance by calling the
``app_glance_reload()`` method, which first clears any existing app glance
slices, and then loads zero or more ``AppGlanceSlice`` as specified by the
developer.

The ``app_glance_reload()`` method is invoked with two parameters: a pointer to an
``AppGlanceReloadCallback`` that will be invoked after the existing app glance
slices have been cleared, and a pointer to context data. Developers can add new
``AppGlanceSlice`` to their app's glance in the ``AppGlanceReloadCallback``.

```c
// ...
// app_glance_reload callback
static void prv_update_app_glance(AppGlanceReloadSession *session,
                                       size_t limit, void *context) {
  // Create and add app glance slices...
}

static void prv_deinit() {
  // deinit code
  // ...

  // Reload the watchapp's app glance
  app_glance_reload(prv_update_app_glance, NULL);
}
```

## The app_glance_reload Callback

The ``app_glance_reload()`` is invoked with 3 parameters, a pointer to an
``AppGlanceReloadSession`` (which is used when invoking
``app_glance_add_slice()``) , the maximum number of slices you are able to add
(as determined by the system at run time), and a pointer to the context data
that was passed into ``app_glance_reload()``. The context data should contain
all the information required to build the ``AppGlanceSlice``, and is typically
cast to a specific type before being used.

> The `limit` is currently set to 8 app glance slices per watchapp, though there
> is no guarantee that this value will remain static, and developers should
> always ensure they are not adding more slices than the limit.

![Hello World >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/appglance-c/hello-world-app-glance.png)

In this example, we’re passing the string we would like to set as the subtitle,
by using the context parameter. The full code for this example can be found in
the [AppGlance-Hello-World](https://github.com/pebble-examples/app-glance-hello-world)
repository.

```c
static void prv_update_app_glance(AppGlanceReloadSession *session,
                                       size_t limit, void *context) {
  // This should never happen, but developers should always ensure they are
  // not adding more slices than are available
  if (limit < 1) return;

  // Cast the context object to a string
  const char *message = context;

  // Create the AppGlanceSlice
  // NOTE: When .icon is not set, the app's default icon is used
  const AppGlanceSlice entry = (AppGlanceSlice) {
    .layout = {
      .icon = APP_GLANCE_SLICE_DEFAULT_ICON,
      .subtitle_template_string = message
    },
    .expiration_time = APP_GLANCE_SLICE_NO_EXPIRATION
  };

  // Add the slice, and check the result
  const AppGlanceResult result = app_glance_add_slice(session, entry);

  if (result != APP_GLANCE_RESULT_SUCCESS) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "AppGlance Error: %d", result);
  }
}
```

> **NOTE:** When an ``AppGlanceSlice`` is loaded with the
> ``app_glance_add_slice()`` method, the slice's
> `layout.subtitle_template_string` is copied to the app's glance, meaning the
> string does not need to persist after the call to ``app_glance_add_slice()``
> is made.

## Using Custom Icons

In order to use custom icons within an ``AppGlanceSlice``, you need to use the
new `publishedMedia` entry in the `package.json` file.

* Create your images as 25px x 25px PNG files.
* Add your images as media resources in the `package.json`.
* Then add the `publishedMedia` declaration.

You should end up with something like this:

```js
"resources": {
  "media": [
    {
      "name": "WEATHER_HOT_ICON_TINY",
      "type": "bitmap",
      "file": "hot_tiny.png"
    }
  ],
  "publishedMedia": [
    {
      "name": "WEATHER_HOT",
      "id": 1,
      "glance": "WEATHER_HOT_ICON_TINY"
    }
  ]
}
```

Then you can reference the `icon` by `name` in your ``AppGlanceSlice``. You must
use the prefix `PUBLISHED_ID_`. E.g. `PUBLISHED_ID_WEATHER_HOT`.

## Subtitle Template Strings

The `subtitle_template_string` field provides developers with a string
formatting language for app glance subtitles. Developers can create a single
app glance slice which updates automatically based upon a timestamp.

For example, the template can be used to create a countdown until a timestamp
(`time_until`), or the duration since a timestamp (`time_since`). The result
from the timestamp evaluation can be output in various different time-format's,
such as:

* It's 50 days until New Year
* Your Uber will arrive in 5 minutes
* You are 15515 days old

### Template Structure

The template string has the following structure:

<code>{<strong><em>evaluation</em></strong>(<strong><em>timestamp</em></strong>)|format(<strong><em>parameters</em></strong>)}</code>

Let's take a look at a simple countdown example:

`Your Uber will arrive in 1 hr 10 min 4 sec`

In this example, we need to know the time until our timestamp:
`time_until(1467834606)`, then output the duration using an abbreviated
time-format: `%aT`.

`Your Uber will arrive in {time_until(1467834606)|format('%aT')}`

### Format Parameters

Each format parameter is comprised of an optional predicate, and a time-format,
separated by a colon. The time-format parameter is only output if the predicate
evaluates to true. If a predicate is not supplied, the time-format is output by
default.

<code>format(<strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>')</code>

#### Predicate

The predicates are composed of a comparator and time value. For example, the
difference between `now` and the timestamp evaluation is:

* `>1d` Greater than 1 day
* `<12m` Less than 12 months
* `>=6m` Greater than or equal to 6 months
* `<=1d12h` Less than or equal to 1 day, 12 hours.

The supported time units are:

* `d` (Day)
* `H` (Hour)
* `M` (Minute)
* `S` (Second)

#### Time Format

The time-format is a single quoted string, comprised of a percent sign and an
optional format flag, followed by a time unit. For example:

`'%aT'` Abbreviated time. e.g. 1 hr 10 min 4 sec

The optional format flags are:

* `a` Adds abbreviated units (translated and with proper pluralization) (overrides 'u' flag)
* `u` Adds units (translated and with proper pluralization) (overrides 'a' flag)
* `-` Negates the input for this format specifier
* `0` Pad value to the "expected" number of digits with zeros
* `f` Do not modulus the value

The following table demonstrates sample output for each time unit, and the
effects of the format flags.

|<small>Time Unit</small>|<small>No flag</small>|<small>'u' flag</small>|<small>'a' flag</small>|<small>'0' flag</small>|<small>'f' flag</small>|
| --- | --- | --- | --- | --- | --- |
| <small>**y**</small> | <small>&lt;year&gt;</small> | <small>&lt;year&gt; year(s)</small> | <small>&lt;year&gt; yr(s)</small> | <small>&lt;year, pad to 2&gt;</small> | <small>&lt;year, no modulus&gt;</small> |
| <small>output:</small> | <small>4</small> | <small>4 years</small> | <small>4 yr</small> | <small>04</small> | <small>4</small> |
| <small>**m**</small> | <small>&lt;month&gt;</small> | <small>&lt;month&gt; month(s)</small> | <small>&lt;month&gt; mo(s)</small> | <small>&lt;month, pad to 2&gt;</small> | <small>&lt;month, no modulus&gt;</small> |
| <small>output:</small> | <small>8</small> | <small>8 months</small> | <small>8 mo</small> | <small>08</small> | <small>16</small> |
| <small>**d**</small> | <small>&lt;day&gt;</small> | <small>&lt;day&gt; days</small> | <small>&lt;day&gt; d</small> | <small>&lt;day, pad to 2&gt;</small> | <small>&lt;day, no modulus&gt;</small> |
| <small>output:</small> | <small>7</small> | <small>7 days</small> | <small>7 d</small> | <small>07</small> | <small>38</small> |
| <small>**H**</small> | <small>&lt;hour&gt;</small> | <small>&lt;hour&gt; hour(s)</small> | <small>&lt;hour&gt; hr</small> | <small>&lt;hour, pad to 2&gt;</small> | <small>&lt;hour, no modulus&gt;</small> |
| <small>output:</small> | <small>1</small> | <small>1 hour</small> | <small>1 hr</small> | <small>01</small> | <small>25</small> |
| <small>**M**</small> | <small>&lt;minute&gt;</small> | <small>&lt;minute&gt; minute(s)</small> | <small>&lt;minute&gt; min</small> | <small>&lt;minute, pad to 2&gt;</small> | <small>&lt;minute, no modulus&gt;</small> |
| <small>output:</small> | <small>22</small> | <small>22 minutes</small> | <small>22 min</small> | <small>22</small> | <small>82</small> |
| <small>**S**</small> | <small>&lt;second&gt;</small> | <small>&lt;second&gt; second(s)</small> | <small>&lt;second&gt; sec</small> | <small>&lt;second, pad to 2&gt;</small> | <small>&lt;second, no modulus&gt;</small> |
| <small>output:</small> | <small>5</small> | <small>5 seconds</small> | <small>5 sec</small> | <small>05</small> | <small>65</small> |
| <small>**T**</small> | <small>%H:%0M:%0S (if &gt;= 1hr)<hr />%M:%0S (if &gt;= 1m)<hr />%S (otherwise)</small> | <small>%uH, %uM, and %uS<hr />%uM, and %uS<hr />%uS</small> | <small>%aH %aM %aS<hr />%aM %aS<hr />%aS</small> | <small>%0H:%0M:%0S (always)</small> | <small>%fH:%0M:%0S<hr />%M:%0S<hr />%S</small> |
| <small>output:</small> | <small>1:53:20<hr />53:20<hr />20</small> | <small>1 hour, 53 minutes, and 20 seconds<hr />53 minutes, and 20 seconds<hr />20 seconds</small> | <small>1 hr 53 min 20 sec<hr />53 min 20 sec<hr />20 sec</small> | <small>01:53:20<hr />00:53:20<hr />00:00:20</small> | <small>25:53:20<hr />53:20<hr />20</small> |
| <small>**R**</small> | <small>%H:%0M (if &gt;= 1hr)<hr />%M (otherwise)</small> | <small>%uH, and %uM<hr />%uM</small> | <small>%aH %aM<hr />%aM</small> | <small>%0H:%0M (always)</small> | <small>%fH:%0M<hr />%M</small> |
| <small>output:</small> | <small>23:04<hr />15</small> | <small>23 hours, and 4 minutes<hr />15 minutes</small> | <small>23 hr 4 min<hr />15 min</small> | <small>23:04<hr />00:15</small> | <small>47:04<hr />15</small> |

> Note: The time units listed above are not all available for use as predicates,
but can be used with format flags.

#### Advanced Usage

We've seen how to use a single parameter to generate our output, but for more
advanced cases, we can chain multiple parameters together. This allows for a
single app glance slice to produce different output as each parameter evaluates
successfully, from left to right.

<code>format(<strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>', <strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>', <strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>')</code>

For example, we can generate a countdown which displays different output before,
during and after the event:

* 100 days left
* 10 hr 5 min 20 sec left
* It's New Year!
* 10 days since New Year

To produce this output we could use the following template:

`{time_until(1483228800)|format(>=1d:'%ud left',>0S:'%aT left',>-1d:\"It's New Year!\", '%-ud since New Year')}`

## Adding Multiple Slices

An app's glance can change over time, with the slices being displayed in the
order they were added, and removed after the `expiration_time`. In order to add
multiple app glance slices, we simply need to create and add multiple
``AppGlanceSlice`` instances, with increasing expiration times.

![Virtual Pet >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/appglance-c/virtual-pet-app-glance.png)

In the following example, we create a basic virtual pet that needs to be fed (by
opening the app) every 12 hours, or else it runs away. When the app closes, we
update the app glance to display a new message and icon every 3 hours until the
virtual pet runs away. The full code for this example can be found in the
[AppGlance-Virtual-Pet](https://github.com/pebble-examples/app-glance-virtual-pet)
repository.

```c
// How often pet needs to be fed (12 hrs)
#define PET_FEEDING_FREQUENCY 3600*12
// Number of states to show in the launcher
#define NUM_STATES 4

// Icons associated with each state
const uint32_t icons[NUM_STATES] = {
  PUBLISHED_ID_ICON_FROG_HAPPY,
  PUBLISHED_ID_ICON_FROG_HUNGRY,
  PUBLISHED_ID_ICON_FROG_VERY_HUNGRY,
  PUBLISHED_ID_ICON_FROG_MISSING
};

// Message associated with each state
const char *messages[NUM_STATES] = {
  "Mmm, that was delicious!!",
  "I'm getting hungry..",
  "I'm so hungry!! Please feed me soon..",
  "Your pet ran away :("
};

static void prv_update_app_glance(AppGlanceReloadSession *session,
                                       size_t limit, void *context) {

  // Ensure we have sufficient slices
  if (limit < NUM_STATES) {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "Error: app needs %d slices (%zu available)",
                                                            NUM_STATES, limit);
  }

  time_t expiration_time = time(NULL);

  // Build and add NUM_STATES slices
  for (int i = 0; i < NUM_STATES; i++) {
    // Increment the expiration_time of the slice on each pass
    expiration_time += PET_FEEDING_FREQUENCY / NUM_STATES;

    // Set it so the last slice never expires
    if (i == (NUM_STATES - 1)) expiration_time = APP_GLANCE_SLICE_NO_EXPIRATION;

    // Create the slice
    const AppGlanceSlice slice = {
      .layout = {
        .icon = icons[i],
        .subtitle_template_string = messages[i]
      },
      .expiration_time = expiration_time
    };

    // add the slice, and check the result
    AppGlanceResult result = app_glance_add_slice(session, slice);
    if (result != APP_GLANCE_RESULT_SUCCESS) {
      APP_LOG(APP_LOG_LEVEL_ERROR, "Error adding AppGlanceSlice: %d", result);
    }
  }
}

static void prv_deinit() {
  app_glance_reload(prv_update_app_glance, NULL);
}

void main() {
  app_event_loop();
  prv_deinit();
}
```

## AppGlance in PebbleKit JS

## Overview

This guide explains how to manage your app's glances via PebbleKit JS. The
``App Glance`` API was added in SDK 4.0 and enables developers to
programmatically set the icon and subtitle that appears alongside their app in
the launcher.

If you want to learn more about ``App Glance``, please read the
 guide.

#### Creating Slices

To create a slice, call `Pebble.appGlanceReload()`. The first parameter is an
array of AppGlance slices, followed by a callback for success and one for
failure.

```javascript
  // Construct the app glance slice object
  var appGlanceSlices = [{
    "layout": {
      "icon": "system://images/HOTEL_RESERVATION",
      "subtitleTemplateString": "Nice Slice!"
    }
  }];

  function appGlanceSuccess(appGlanceSlices, appGlanceReloadResult) {
    console.log('SUCCESS!');
  };

  function appGlanceFailure(appGlanceSlices, appGlanceReloadResult) {
    console.log('FAILURE!');
  };

  // Trigger a reload of the slices in the app glance
  Pebble.appGlanceReload(appGlanceSlices, appGlanceSuccess, appGlanceFailure);
```

#### Slice Icons

There are two types of resources which can be used for AppGlance icons.

* You can use system images. E.g. `system://images/HOTEL_RESERVATION`
* You can use custom images by utilizing the

`name`. E.g. `app://images/*name*`

#### Subtitle Template Strings

The `subtitle_template_string` field provides developers with a string
formatting language for app glance subtitles. Read more in the
.

#### Expiring Slices

When you want your slice to expire automatically, just provide an
`expirationTime` in
[ISO date-time](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString)
format and the system will automatically remove it upon expiry.

```javascript
  var appGlanceSlices = [{
    "layout": {
      "icon": "system://images/HOTEL_RESERVATION",
      "subtitleTemplateString": "Nice Slice!"
    },
    "expirationTime": "2016-12-31T23:59:59.000Z"
  }];
```

#### Creating Multiple Slices

Because `appGlanceSlices` is an array, we can pass multiple slices within a
single function call. The system is responsible for displaying the correct
entries based on the `expirationTime` provided in each slice.

```javascript
  var appGlanceSlices = [{
    "layout": {
      "icon": "system://images/DINNER_RESERVATION",
      "subtitleTemplateString": "Lunchtime!"
    },
    "expirationTime": "2017-01-01T12:00:00.000Z"
  },
  {
    "layout": {
      "icon": "system://images/RESULT_MUTE",
      "subtitleTemplateString": "Nap Time!"
    },
    "expirationTime": "2017-01-01T14:00:00.000Z"
  }];
```

#### Updating Slices

There isn't a concept of updating an AppGlance slice, just call
`Pebble.appGlanceReload()` with the new slices and any existing slices will be
replaced.

#### Deleting Slices

All you need to do is pass an empty slices array and any existing slices will
be removed.

```javascript
Pebble.appGlanceReload([], appGlanceSuccess, appGlanceFailure);
```

## AppGlance REST API

<div class="alert alert--fg-white alert--bg-purple">
  
  **Important Note**

  This API requires the forthcoming v4.1 of the Pebble mobile application in
  order to display App Glances on the connected watch.
  
</div>

## Overview

This guide explains how to use the AppGlance REST API. The ``App Glance`` API
was added in SDK 4.0 and enables developers to programmatically set the icon and
subtitle that appears alongside their app in the launcher.

If you want to learn more about ``App Glance``, please read the
 guide.

## The REST API

The AppGlance REST API shares many similarities with the existing
.
Developers can push slices to the their app's glance using their own backend
servers. Slices are created using HTTPS requests to the Pebble AppGlance REST
API.

#### Creating Slices

To create a slice, send a `PUT` request to the following URL scheme:

```text
PUT https://timeline-api.rebble.io/v1/user/glance
```

Use the following headers, where `X-User-Token` is the user's
timeline token (read

to learn how to get a token):

```text
Content-Type: application/json
X-User-Token: a70b23d3820e9ee640aeb590fdf03a56
```

Include the JSON object as the request body from a file such as `glance.json`. A
sample of an object is shown below:

```json
{
  "slices": [
    {
      "layout": {
        "icon": "system://images/GENERIC_CONFIRMATION",
        "subtitleTemplateString": "Success!"
      }
    }
  ]
}
```

#### Curl Example

```bash
$ curl -X PUT https://timeline-api.rebble.io/v1/user/glance \
    --header "Content-Type: application/json" \
    --header "X-User-Token: a70b23d3820e9ee640aeb590fdf03a56" \
    -d @glance.json
OK
```

#### Slice Icons

There are two types of resources which can be used for AppGlance icons.

* You can use system images. E.g. `system://images/HOTEL_RESERVATION`
* You can use custom images by utilizing the

`name`. E.g. `app://images/*name*`

#### Subtitle Template Strings

The `subtitle_template_string` field provides developers with a string
formatting language for app glance subtitles. Read more in the
.

#### Expiring Slices

When you want your slice to expire automatically, just provide an
`expirationTime` in
[ISO date-time](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString)
format and the system will automatically remove it upon expiry.

```json
{
  "slices": [
    {
      "layout": {
        "icon": "system://images/GENERIC_CONFIRMATION",
        "subtitleTemplateString": "Success!"
      },
      "expirationTime": "2016-12-31T23:59:59.000Z"
    }
  ]
}
```

#### Creating Multiple Slices

Because `slices` is an array, you can send multiple slices within a single
request. The system is responsible for displaying the correct entries based on
the `expirationTime` provided in each slice.

```json
{
  "slices": [
    {
      "layout": {
        "icon": "system://images/DINNER_RESERVATION",
        "subtitleTemplateString": "Lunchtime!"
      },
      "expirationTime": "2017-01-01T12:00:00.000Z"
    },
    {
      "layout": {
        "icon": "system://images/RESULT_MUTE",
        "subtitleTemplateString": "Nap Time!"
      },
      "expirationTime": "2017-01-01T14:00:00.000Z"
    }
  ]
}
```

#### Updating Slices

There isn't a concept of updating an AppGlance slice, just send a request to
the REST API with new slices and any existing slices will be replaced.

#### Deleting Slices

All you need to do is send an empty slices array to the REST API and any
existing slices will be removed.

```json
{
  "slices": []
}
```

### Additional Notes

We will not display App Glance slices for SDK 3.0 applications under any
circumstances. Your watchapp needs to be compiled with SDK 4.0 in order to
support App Glances.

## Content Size

The ContentSize API is currently only available in SDK 4.2-BETA.

The [ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)
API, added in SDK 4.2, allows developers to dynamically
adapt their watchface and watchapp design based upon the system `Text Size`
preference (*Settings > Notifications > Text Size*).

While this allows developers to create highly accessible designs, it also serves
to provide a mechanism for creating designs which are less focused upon screen
size, and more focused upon content size.

![ContentSize >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/content-size/anim.gif)

The `Text Size` setting displays the following options on all platforms:

* Small
* Medium
* Large

Whereas, the
[ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)
API will return different content sizes based on
the `Text Size` setting, varying by platform. The list of content sizes is:

* Small
* Medium
* Large
* Extra Large

An example of the varying content sizes:

* `Text Size`: `small` on `Basalt` is `ContentSize`: `small`
* `Text Size`: `small` on `Emery` is `ContentSize`: `medium`

The following table describes the relationship between `Text Size`, `Platform`
and `ContentSize`:

Platform | Text Size: Small | Text Size: Medium | Text Size: Large
---------|------------------|-------------------|-----------------
Aplite, Basalt, Chalk, Diorite, Flint | ContentSize: Small | ContentSize: Medium | ContentSize: Large
Emery | ContentSize: Medium | ContentSize: Large | ContentSize: Extra Large

> *At present the Text Size setting only affects notifications and some system
UI components, but other system UI components will be updated to support
ContentSize in future versions.*

We highly recommend that developers begin to build and update their applications
with consideration for
[ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)
 to provide the best experience to users.

## Detecting ContentSize

In order to detect the current
[ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)
 developers can use the
``preferred_content_size()`` function.

The [ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)
will never change during runtime, so it's perfectly
acceptable to check this once during `init()`.

```c
static PreferredContentSize s_content_size;

void init() {
  s_content_size = preferred_content_size();
  // ...
}
```

## Adapting Layouts

There are a number of different approaches to adapting the screen layout based
upon content size. You could change font sizes, show or hide design elements, or
even present an entirely different UI.

In the following example, we will change font sizes based on the
[ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)

```c
static TextLayer *s_text_layer;
static PreferredContentSize s_content_size;

void init() {
  s_content_size = preferred_content_size();

  // ...
  switch (s_content_size) {
    case PreferredContentSizeMedium:
      // Use a medium font
      text_layer_set_font(s_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_18_BOLD));
      break;
    case PreferredContentSizeLarge:
    case PreferredContentSizeExtraLarge:
      // Use a large font
      text_layer_set_font(s_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_28_BOLD));
      break;
    default:
      // Use a small font
      text_layer_set_font(s_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_14_BOLD));
      break;
  }
  // ...
}
```

## Additional Considerations

When developing an application which dynamically adjusts based on the
[ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)
setting, try to avoid using fixed widths and heights. Calculate
coordinates and dimensions based upon the size of the root layer,
``UnobstructedArea`` and
[ContentSize](/docs/c/preview/User_Interface/Preferences/#preferred_content_size)

## Layers

The ``Layer`` and associated subclasses (such as ``TextLayer`` and
``BitmapLayer``) form the foundation of the UI for every Pebble watchapp or
watchface, and are added to a ``Window`` to construct the UI's design. Each
``Layer`` type contains at least three basic elements:

* Frame - contains the position and dimensions of the ``Layer``, relative to the
  parent object.

* Bounds - contains the drawable bounding box within the frame. This allows only
  a portion of the layer to be visible, and is relative to the ``Layer`` frame.

* Update procedure - the function that performs the drawing whenever the
  ``Layer`` is rendered. The subclasses implement a convenience update procedure
  with additional data to achieve their specialization.

## Layer Heirachy

Every app must consist of at least one ``Window`` in order to successfully
launch. Mutiple ``Layer`` objects are added as children of the ``Window``, which
itself contains a ``Layer`` known as the 'root layer'. When the ``Window`` is
rendered, each child ``Layer`` is rendered in the order in which they were
added. For example:

```c
static Window *s_main_window;

static BitmapLayer *s_background_layer;
static TextLayer *s_time_layer;
```

```c
// Get the Window's root layer
Layer *root_layer = window_get_root_layer(s_main_window);

/* set up BitmapLayer and TextLayer */

// Add the background layer first, so that it is drawn behind the time
layer_add_child(root_layer, bitmap_layer_get_layer(s_background_layer));

// Add the time layer second
layer_add_child(root_layer, text_layer_get_layer(s_time_layer));
```

Once added to a ``Window``, the ordering of each ``Layer`` cannot be modified,
but one can be placed at the front by removing and re-adding it to the heirachy:

```c
// Bring a layer to the front
layer_remove_from_parent(s_some_layer);
layer_add_child(root_layer, s_some_layer);
```

## Update Procedures

For creating custom drawing implementations, the basic ``Layer`` update
procedure can be reassigned to one created by a developer. This takes the form
of a ``LayerUpdateProc``, and provides a [`GContext`](``Graphics Context``)
object which can be used for drawing primitive shapes, paths, text, and images.

> Note: See  for more information on
> drawing with the graphics context.

```c
static void layer_update_proc(Layer *layer, GContext *ctx) {
  // Custom drawing happens here
}
```

This function must then be assigned to the ``Layer`` that will be drawn with it:

```c
// Set this Layer's update procedure
layer_set_update_proc(s_some_layer, layer_update_proc);
```

The update procedure will be called every time the ``Layer`` must be redrawn.
This is typically when any other ``Layer`` requests a redraw, the ``Window`` is
shown/hidden, the heirarchy changes, or a modal (such as a notification) appears.
The ``Layer`` can also be manually marked as 'dirty', and will be redrawn at the
next opportunity (usually immediately):

```c
// Request a redraw
layer_mark_dirty(s_some_layer);
```

## Layer Subclasses

For convenience, there are multiple subclasses of ``Layer`` included in the
Pebble SDK to allow developers to easily construct their app's UI. Each should
be created when the ``Window`` is loading (using the `.load` ``WindowHandler``)
and destroyed when it is unloading (using `.the unload` ``WindowHandler``).

These are briefly outlined below, alongside a simple usage example split into
three code snippets - the element declarations, the setup procedure, and the
teardown procedure.

### TextLayer

The ``TextLayer`` is the most commonly used subclass of ``Layer``, and allows
apps to render text using any available font, with built-in behavior to handle
text color, line wrapping, alignment, etc.

```c
static TextLayer *s_text_layer;
```

```c
// Create a TextLayer
s_text_layer = text_layer_create(bounds);

// Set some properties
text_layer_set_text_color(s_text_layer, GColorWhite);
text_layer_set_background_color(s_text_layer, GColorBlack);
text_layer_set_overflow_mode(s_text_layer, GTextOverflowModeWordWrap);
text_layer_set_alignment(s_text_layer, GTextAlignmentCenter);

// Set the text shown
text_layer_set_text(s_text_layer, "Hello, World!");

// Add to the Window
layer_add_child(root_layer, text_layer_get_layer(s_text_layer));
```

```c
// Destroy the TextLayer
text_layer_destroy(s_text_layer);
```

### BitmapLayer

The ``BitmapLayer`` provides an easy way to show images loaded into ``GBitmap``
objects from an image resource. Images shown using a ``BitmapLayer`` are
automatically centered within the bounds provided to ``bitmap_layer_create()``.
Read  to learn more about using image
resources in apps.

> Note: PNG images with transparency should use `bitmap` resource type, and use
> the ``GCompOpSet`` compositing mode when being displayed, as shown below.

```c
static BitmapLayer *s_bitmap_layer;
static GBitmap *s_bitmap;
```

```c
// Load the image
s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);

// Create a BitmapLayer
s_bitmap_layer = bitmap_layer_create(bounds);

// Set the bitmap and compositing mode
bitmap_layer_set_bitmap(s_bitmap_layer, s_bitmap);
bitmap_layer_set_compositing_mode(s_bitmap_layer, GCompOpSet);

// Add to the Window
layer_add_child(root_layer, bitmap_layer_get_layer(s_bitmap_layer));
```

```c
// Destroy the BitmapLayer
bitmap_layer_destroy(s_bitmap_layer);
```

### StatusBarLayer

If a user needs to see the current time inside an app (instead of exiting to the
watchface), the ``StatusBarLayer`` component can be used to display this
information at the top of the ``Window``. Colors and separator display style can
be customized.

```c
static StatusBarLayer *s_status_bar;
```

```c
// Create the StatusBarLayer
s_status_bar = status_bar_layer_create();

// Set properties
status_bar_layer_set_colors(s_status_bar, GColorBlack, GColorBlueMoon);
status_bar_layer_set_separator_mode(s_status_bar, 
                                            StatusBarLayerSeparatorModeDotted);

// Add to Window
layer_add_child(root_layer, status_bar_layer_get_layer(s_status_bar));
```

```c
// Destroy the StatusBarLayer
status_bar_layer_destroy(s_status_bar);
```

### MenuLayer

The ``MenuLayer`` allows the user to scroll a list of options using the Up and
Down buttons, and select an option to trigger an action using the Select button.
It differs from the other ``Layer`` subclasses in that it makes use of a number
of ``MenuLayerCallbacks`` to allow the developer to fully control how it renders
and behaves. Some minimum example callbacks are shown below:

```c
static MenuLayer *s_menu_layer;
```

```c
static uint16_t get_num_rows_callback(MenuLayer *menu_layer, 
                                      uint16_t section_index, void *context) {
  const uint16_t num_rows = 5;
  return num_rows;
}

static void draw_row_callback(GContext *ctx, const Layer *cell_layer, 
                                        MenuIndex *cell_index, void *context) {
  static char s_buff[16];
  snprintf(s_buff, sizeof(s_buff), "Row %d", (int)cell_index->row);

  // Draw this row's index
  menu_cell_basic_draw(ctx, cell_layer, s_buff, NULL, NULL);
}

static int16_t get_cell_height_callback(struct MenuLayer *menu_layer, 
                                        MenuIndex *cell_index, void *context) {
  const int16_t cell_height = 44;
  return cell_height;
}

static void select_callback(struct MenuLayer *menu_layer, 
                                        MenuIndex *cell_index, void *context) {
  // Do something in response to the button press
  
}
```

```c
// Create the MenuLayer
s_menu_layer = menu_layer_create(bounds);

// Let it receive click events
menu_layer_set_click_config_onto_window(s_menu_layer, window);

// Set the callbacks for behavior and rendering
menu_layer_set_callbacks(s_menu_layer, NULL, (MenuLayerCallbacks) {
    .get_num_rows = get_num_rows_callback,
    .draw_row = draw_row_callback,
    .get_cell_height = get_cell_height_callback,
    .select_click = select_callback,
});

// Add to the Window
layer_add_child(root_layer, menu_layer_get_layer(s_menu_layer));
```

```c
// Destroy the MenuLayer
menu_layer_destroy(s_menu_layer);
```

### ScrollLayer

The ``ScrollLayer`` provides an easy way to use the Up and Down buttons to
scroll large content that does not all fit onto the screen at the same time. The
usage of this type differs from the others in that the ``Layer`` objects that
are scrolled are added as children of the ``ScrollLayer``, which is then in turn
added as a child of the ``Window``.

The ``ScrollLayer`` frame is the size of the 'viewport', while the content size
determines how far the user can scroll in each direction. The example below
shows a ``ScrollLayer`` scrolling some long text, the total size of which is
calculated with ``graphics_text_layout_get_content_size()`` and used as the
``ScrollLayer`` content size.

> Note: The scrolled ``TextLayer`` frame is relative to that of its parent, the
> ``ScrollLayer``.

```c
static TextLayer *s_text_layer;
static ScrollLayer *s_scroll_layer;
```

```c
GFont font = fonts_get_system_font(FONT_KEY_GOTHIC_28_BOLD);

// Find the bounds of the scrolling text
GRect shrinking_rect = GRect(0, 0, bounds.size.w, 2000);
char *text = "Example text that is really really really really really \
                              really really really really really really long";
GSize text_size = graphics_text_layout_get_content_size(text, font, 
                shrinking_rect, GTextOverflowModeWordWrap, GTextAlignmentLeft);
GRect text_bounds = bounds;
text_bounds.size.h = text_size.h;

// Create the TextLayer
s_text_layer = text_layer_create(text_bounds);
text_layer_set_overflow_mode(s_text_layer, GTextOverflowModeWordWrap);
text_layer_set_font(s_text_layer, font);
text_layer_set_text(s_text_layer, text);

// Create the ScrollLayer
s_scroll_layer = scroll_layer_create(bounds);

// Set the scrolling content size
scroll_layer_set_content_size(s_scroll_layer, text_size);

// Let the ScrollLayer receive click events
scroll_layer_set_click_config_onto_window(s_scroll_layer, window);

// Add the TextLayer as a child of the ScrollLayer
scroll_layer_add_child(s_scroll_layer, text_layer_get_layer(s_text_layer));

// Add the ScrollLayer as a child of the Window
layer_add_child(root_layer, scroll_layer_get_layer(s_scroll_layer));
```

```c
// Destroy the ScrollLayer and TextLayer
scroll_layer_destroy(s_scroll_layer);
text_layer_destroy(s_text_layer);
```

### ActionBarLayer

The ``ActionBarLayer`` allows apps to use the familiar black right-hand bar,
featuring icons denoting the action that will occur when each button on the
right hand side is pressed. For example, 'previous track', 'more actions', and
'next track' in the built-in Music app. 

For three or fewer actions, the ``ActionBarLayer`` can be more appropriate than
a ``MenuLayer`` for presenting the user with a list of actionable options. Each
action's icon must also be loaded into a ``GBitmap`` object from app resources.
The example below demonstrates show to set up an ``ActionBarLayer`` showing an
up, down, and checkmark icon for each of the buttons.

```c
static ActionBarLayer *s_action_bar;
static GBitmap *s_up_bitmap, *s_down_bitmap, *s_check_bitmap;
```

```c
// Load icon bitmaps
s_up_bitmap = gbitmap_create_with_resource(RESOURCE_ID_UP_ICON);
s_down_bitmap = gbitmap_create_with_resource(RESOURCE_ID_DOWN_ICON);
s_check_bitmap = gbitmap_create_with_resource(RESOURCE_ID_CHECK_ICON);

// Create ActionBarLayer
s_action_bar = action_bar_layer_create();
action_bar_layer_set_click_config_provider(s_action_bar, click_config_provider);

// Set the icons
action_bar_layer_set_icon(s_action_bar, BUTTON_ID_UP, s_up_bitmap);
action_bar_layer_set_icon(s_action_bar, BUTTON_ID_DOWN, s_down_bitmap);
action_bar_layer_set_icon(s_action_bar, BUTTON_ID_SELECT, s_check_bitmap);

// Add to Window
action_bar_layer_add_to_window(s_action_bar, window);
```

```c
// Destroy the ActionBarLayer
action_bar_layer_destroy(s_action_bar);

// Destroy the icon GBitmaps
gbitmap_destroy(s_up_bitmap);
gbitmap_destroy(s_down_bitmap);
gbitmap_destroy(s_check_bitmap);
```

## Round App UI

> This guide is about creating round apps in code. For advice on designing a
> round app, read .

With the addition of Pebble Time Round (the Chalk platform) to the Pebble
family, developers face a new challenge - circular apps! With this display
shape, traditional layouts will not display properly due to the obscuring of the
corners. Another potential issue is the increased display resolution. Any UI
elements that were not previously centered correctly (or drawn with hardcoded
coordinates) will also display incorrectly.

However, the Pebble SDK provides additions and functionality to help developers
cope with this way of thinking. In many cases, a round display can be an
aesthetic advantage. An example of this is the traditional circular dial
watchface, which has been emulated on Pebble many times, but also wastes corner
space. With a round display, these watchfaces can look better than ever.

![time-dots >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/time-dots.png)

## Detecting Display Shape

The first step for any app wishing to correctly support both display shapes is
to use the available compiler directives to conditionally create the UI. This
can be done as shown below:

```c
#if defined(PBL_RECT)
  printf("This code is run on a rectangular display!");

  /* Rectangular UI code */
#elif defined(PBL_ROUND)
  printf("This code is run on a round display!");

  /* Round UI code */
#endif
```

Another approach for single value selection is the ``PBL_IF_RECT_ELSE()`` and
``PBL_IF_ROUND_ELSE()`` macros, which accept two parameters for each of the
respective round and rectangular cases. For example, ``PBL_IF_RECT_ELSE()`` will
compile the first parameter on a rectangular display, and the second one
otherwise:

```c
// Conditionally print out the shape of the display
printf("This is a %s display!", PBL_IF_RECT_ELSE("rectangular", "round"));
```

## Circular Drawing

In addition to the older ``graphics_draw_circle()`` and
``graphics_fill_circle()`` functions, the Pebble SDK for the chalk platform
contains additional functions to help draw shapes better suited for a round
display. These include:

* ``graphics_draw_arc()`` - Draws a line arc clockwise between two angles within
  a given ``GRect`` area, where 0° is the top of the circle.

* ``graphics_fill_radial()`` - Fills a circle clockwise between two angles
  within a given ``GRect`` area, with adjustable inner inset radius allowing the
  creation of 'doughnut-esque' shapes.

* ``gpoint_from_polar()`` - Returns a ``GPoint`` object describing a point given
  by a specified angle within a centered ``GRect``.

In the Pebble SDK angles between `0` and `360` degrees are specified as values
scaled between `0` and ``TRIG_MAX_ANGLE`` to preserve accuracy and avoid
floating point math. These are most commonly used when dealing with drawing
circles. To help with this conversion, developers can use the
``DEG_TO_TRIGANGLE()`` macro.

An example function to draw the letter 'C' in a yellow color is shown below for
use in a ``LayerUpdateProc``.

```c
static void draw_letter_c(GRect bounds, GContext *ctx) {
  GRect frame = grect_inset(bounds, GEdgeInsets(30));

  graphics_context_set_fill_color(ctx, GColorYellow);
  graphics_fill_radial(ctx, frame, GOvalScaleModeFitCircle, 30,
                                  DEG_TO_TRIGANGLE(-225), DEG_TO_TRIGANGLE(45));
}
```

This produces the expected result, drawn with a smooth antialiased filled circle
arc between the specified angles.

![letter-c >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/letter-c.png)

## Adaptive Layouts

With not only a difference in display shape, but also in resolution, it is very
important that an app's layout not be created using hardcoded coordinates.
Consider the examples below, designed to create a child ``Layer`` to fill the
size of the parent layer.

```c
// Bad - only works on Aplite and Basalt rectangular displays
Layer *layer = layer_create(GRect(0, 0, 144, 168));

// Better - uses the native display size
GRect bounds = layer_get_bounds(parent_layer);
Layer *layer = layer_create(bounds);
```

Using this style, the child layer will always fill the parent layer, regardless
of its actual dimensions.

In a similar vein, when working with the Pebble Time Round display it can be
important that the layout is centered correctly. A set of layout values that are
in the center of the classic 144 x 168 pixel display will not be centered when
displayed on a 180 x 180 display. The undesirable effect of this can be seen in
the example shown below:

![cut-corners >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/cut-corners.png)

By using the technique described above, the layout's ``GRect`` objects can
specify their `origin` and `size` as a function of the dimensions of the layer
they are drawn into, solving this problem.

![centered >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/centered.png)

## Text Flow and Pagination

A chief concern when working with a circular display is the rendering of large
amounts of text. As demonstrated by an animation in
, continuous
reflowing of text makes it much harder to read.

A solution to this problem is to render text while flowing within the
constraints of the shape of the display, and to scroll/animate it one page at a
time. There are three approaches to this available to developers, which are
detailed below. For full examples of each, see the
[`text-flow-techniques`](https://github.com/pebble-examples/text-flow-techniques)
example app.

### Using TextLayer

Additions to the ``TextLayer`` API allow text rendered within it to be
automatically flowed according to the curve of the display, and paged correctly
when the layer is moved or animated further. After a ``TextLayer`` is created in
the usual way, text flow can then be enabled:

```c
// Create TextLayer
TextLayer *s_text_layer = text_layer_create(bounds);

/* other properties set up */

// Add to parent Window
layer_add_child(window_layer, text_layer_get_layer(s_text_layer));

// Enable paging and text flow with an inset of 5 pixels
text_layer_enable_screen_text_flow_and_paging(s_text_layer, 5);
```

> Note: The ``text_layer_enable_screen_text_flow_and_paging()`` function must be
> called **after** the ``TextLayer`` is added to the view heirachy (i.e.: after
> using ``layer_add_child()``), or else it will have no effect.

An example of two ``TextLayer`` elements flowing their text within the
constraints of the display shape is shown below:

![text-flow >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/text-flow.png)

### Using ScrollLayer

The ``ScrollLayer`` UI component also contains round-friendly functionality,
allowing it to scroll its child ``Layer`` elements in pages of the same height
as its frame (usually the size of the parent ``Window``). This allows consuming
long content to be a more consistent experience, whether it is text, images, or
some other kind of information.

```c
// Enable ScrollLayer paging
scroll_layer_set_paging(s_scroll_layer, true);
```

When combined with a ``TextLayer`` as the main child layer, it becomes easy to
display long pieces of textual content on a round display. The ``TextLayer`` can
be set up to handle the reflowing of text to follow the display shape, and the
``ScrollLayer`` handles the paginated scrolling.

```c
// Add the TextLayer and ScrollLayer to the view heirachy
scroll_layer_add_child(s_scroll_layer, text_layer_get_layer(s_text_layer));
layer_add_child(window_layer, scroll_layer_get_layer(s_scroll_layer));

// Set the ScrollLayer's content size to the total size of the text
scroll_layer_set_content_size(s_scroll_layer,
                              text_layer_get_content_size(s_text_layer));

// Enable TextLayer text flow and paging
const int inset_size = 2;
text_layer_enable_screen_text_flow_and_paging(s_text_layer, inset_size);

// Enable ScrollLayer paging
scroll_layer_set_paging(s_scroll_layer, true);
```

### Manual Text Drawing

The drawing of text into a [`Graphics Context`](``Drawing Text``) can also be
performed with awareness of text flow and paging preferences. This can be used
to emulate the behavior of the two previous approaches, but with more
flexibility. This approach involves the use of the ``GTextAttributes`` object,
which is given to the Graphics API to allow it to flow text and paginate when
being animated.

When initializing the ``Window`` that will do the drawing:

```c
// Create the attributes object used for text rendering
GTextAttributes *s_attributes = graphics_text_attributes_create();

// Enable text flow with an inset of 5 pixels
graphics_text_attributes_enable_screen_text_flow(s_attributes, 5);

// Enable pagination with a fixed reference point and bounds, used for animating
graphics_text_attributes_enable_paging(s_attributes, bounds.origin, bounds);
```

When drawing some text in a ``LayerUpdateProc``:

```c
static void update_proc(Layer *layer, GContext *ctx) {
  GRect bounds = layer_get_bounds(layer);

  // Calculate size of the text to be drawn with current attribute settings
  GSize text_size = graphics_text_layout_get_content_size_with_attributes(
    s_sample_text, fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD), bounds,
    GTextOverflowModeWordWrap, GTextAlignmentCenter, s_attributes
  );

  // Draw the text in this box with the current attribute settings
  graphics_context_set_text_color(ctx, GColorBlack);
  graphics_draw_text(ctx, s_sample_text, fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD),
    GRect(bounds.origin.x, bounds.origin.y, text_size.w, text_size.h),
    GTextOverflowModeWordWrap, GTextAlignmentCenter, s_attributes
  );
}
```

Once this setup is complete, the text will display correctly when moved or
scrolled via a ``PropertyAnimation``, such as one that moves the ``Layer`` that
draws the text upwards, and at the same time extending its height to display
subsequent pages. An example animation is shown below:

```c
GRect window_bounds = layer_get_bounds(window_get_root_layer(s_main_window));
const int duration_ms = 1000;

// Animate the Layer upwards, lengthening it to allow the next page to be drawn
GRect start = layer_get_frame(s_layer);
GRect finish = GRect(start.origin.x, start.origin.y - window_bounds.size.h,
                     start.size.w, start.size.h * 2);

// Create and scedule the PropertyAnimation
PropertyAnimation *prop_anim = property_animation_create_layer_frame(
                                                      s_layer, &start, &finish);
Animation *animation = property_animation_get_animation(prop_anim);
animation_set_duration(animation, duration_ms);
animation_schedule(animation);
```

## Working With a Circular Framebuffer

The traditional rectangular Pebble app framebuffer is a single continuous memory
segment that developers could access with ``gbitmap_get_data()``. With a round
display, Pebble saves memory by clipping sections of each line of difference
between the display area and the rectangle it occupies. The resulting masking
pattern looks like this:

![mask](/images/guides/pebble-apps/display-animations/mask.png)

> Download this mask by saving the PNG image above, or get it as a
> [Photoshop PSD layer](/assets/images/guides/pebble-apps/display-animations/round-mask-layer.psd).

This has an important implication - the memory segment of the framebuffer can no
longer be accessed using classic `y * row_width + x` formulae. Instead,
developers should use the ``gbitmap_get_data_row_info()`` API. When used with a
given y coordinate, this will return a ``GBitmapDataRowInfo`` object containing
a pointer to the row's data, as well as values for the minumum and maximum
visible values of x coordinate on that row. For example:

```c
static void round_update_proc(Layer *layer, GContext *ctx) {
  // Get framebuffer
  GBitmap *fb = graphics_capture_frame_buffer(ctx);
  GRect bounds = layer_get_bounds(layer);

  // Write a value to all visible pixels
  for(int y = 0; y < bounds.size.h; y++) {
    // Get the min and max x values for this row
    GBitmapDataRowInfo info = gbitmap_get_data_row_info(fb, y);

    // Iterate over visible pixels in that row
    for(int x = info.min_x; x < info.max_x; x++) {
      // Set the pixel to black
      memset(&info.data[x], GColorBlack.argb, 1);
    }
  }

  // Release framebuffer
  graphics_release_frame_buffer(ctx, fb);
}
```

## Displaying More Content

When more content is available than fits on the screen at any one time, the user
should be made aware using visual clues. The best way to do this is to use the
``ContentIndicator`` UI component.

![content-indicator >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/design-and-interaction/content-indicator.png)

A ``ContentIndicator`` can be obtained in two ways. It can be created from
scratch with ``content_indicator_create()`` and manually managed to determine
when the arrows should be shown, or a built-in instance can be obtained from a
``ScrollLayer``, as shown below:

```c
// Get the ContentIndicator from the ScrollLayer
s_indicator = scroll_layer_get_content_indicator(s_scroll_layer);
```

In order to draw the arrows indicating more information in each direction, the
``ContentIndicator`` must be supplied with two new ``Layer`` elements that will
be used to do the drawing. These should also be added as children to the main
``Window`` root ``Layer`` such that they are visible on top of all other
``Layer`` elements:

```c
static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  /* ... */

  // Create two Layers to draw the arrows
  s_indicator_up_layer = layer_create(
                          GRect(0, 0, bounds.size.w, STATUS_BAR_LAYER_HEIGHT));
  s_indicator_down_layer = layer_create(
                          GRect(0, bounds.size.h - STATUS_BAR_LAYER_HEIGHT,
                                bounds.size.w, STATUS_BAR_LAYER_HEIGHT));

  /* ... */

  // Add these Layers as children after all other components to appear below
  layer_add_child(window_layer, s_indicator_up_layer);
  layer_add_child(window_layer, s_indicator_down_layer);
}
```

Once the indicator ``Layer`` elements have been created, each of the up and down
directions for conventional vertical scrolling must be configured with data to
control its behavior. Aspects such as the color of the arrows and background,
whether or not the arrows time out after being brought into view, and the
alignment of the drawn arrow within the ``Layer`` itself are configured with a
`const` ``ContentIndicatorConfig`` object when each direction is being
configured:

```c
// Configure the properties of each indicator
const ContentIndicatorConfig up_config = (ContentIndicatorConfig) {
  .layer = s_indicator_up_layer,
  .times_out = false,
  .alignment = GAlignCenter,
  .colors = {
    .foreground = GColorBlack,
    .background = GColorWhite
  }
};
content_indicator_configure_direction(s_indicator, ContentIndicatorDirectionUp,
                                      &up_config);

const ContentIndicatorConfig down_config = (ContentIndicatorConfig) {
  .layer = s_indicator_down_layer,
  .times_out = false,
  .alignment = GAlignCenter,
  .colors = {
    .foreground = GColorBlack,
    .background = GColorWhite
  }
};
content_indicator_configure_direction(s_indicator, ContentIndicatorDirectionDown,
                                      &down_config);
```

Unless the ``ContentIndicator`` has been retrieved from another ``Layer`` type
that includes an instance, it should be destroyed along with its parent
``Window``:

```c
// Destroy a manually created ContentIndicator
content_indicator_destroy(s_indicator);
```

For layouts that use the ``StatusBarLayer``, the ``ContentIndicatorDirectionUp``
`.layer` in the ``ContentIndicatorConfig`` object can be given the status bar's
``Layer`` with ``status_bar_layer_get_layer()``, and the drawing routines for
each will be managed automatically.

## Unobstructed Area

The ``UnobstructedArea`` API, added in SDK 4.0, allows developers to dynamically
adapt their watchface design when an area of the screen is partially obstructed
by a system overlay. Currently, the Timeline Quick View feature is the only
system overlay.

Developers are not required to adjust their designs to cater for such system
overlays, but by using the ``UnobstructedArea`` API they can detect changes to
the available screen real-estate and then move, scale, or hide their layers to
achieve an optimal layout while the screen is partially obscured.

![Unobstructed-watchfaces](/images/guides/user-interfaces/unobstructed-area/01-unobstructed-watchfaces.jpg)
<p class="blog__image-text">Sample watchfaces with Timeline Quick View overlay
</p>

![Obstructed-watchfaces](/images/guides/user-interfaces/unobstructed-area/02-obstructed-watchfaces.jpg)
<p class="blog__image-text">Potential versions of sample watchfaces using the
UnobstructedArea API</p>

### Determining the Unobstructed Bounds

Prior to SDK 4.0, when displaying layers on screen you would calculate the
size of the display using ``layer_get_bounds()`` and then scale and position
your layers accordingly. Developers can now calculate the size of a layer,
excluding system obstructions, using the new
``layer_get_unobstructed_bounds()``.

```c
static Layer *s_window_layer;
static TextLayer *s_text_layer;

static void main_window_load(Window *window) {
  s_window_layer = window_get_root_layer(window);
  GRect unobstructed_bounds = layer_get_unobstructed_bounds(s_window_layer);
  s_text_layer = text_layer_create(GRect(0, unobstructed_bounds.size.h / 4, unobstructed_bounds.size.w, 50));
}
```

If you still want a fullscreen entities such as a background image, regardless
of any obstructions, just combine both techniques as follows:

```c
static Layer *s_window_layer;
static BitmapLayer *s_image_layer;
static TextLayer *s_text_layer;

static void main_window_load(Window *window) {
  s_window_layer = window_get_root_layer(window);
  GRect full_bounds = layer_get_bounds(s_window_layer);
  GRect unobstructed_bounds = layer_get_unobstructed_bounds(s_window_layer);
  s_image_layer = bitmap_layer_create(full_bounds);
  s_text_layer = text_layer_create(GRect(0, unobstructed_bounds.size.h / 4, unobstructed_bounds.size.w, 50));
}
```

The approach outlined above is perfectly fine to use when your watchface is
initially launched, but you’re also responsible for handling the obstruction
appearing and disappearing while your watchface is running.

### Rendering with LayerUpdateProc

If your application controls its own rendering process using a
``LayerUpdateProc`` you can just dynamically adjust your rendering
each time your layer updates.

In this example, we use ``layer_get_unobstructed_bounds()`` instead of
``layer_get_bounds()``. The graphics are then positioned or scaled based upon
the available screen real-estate, instead of the screen dimensions.

> You must ensure you fill the entire window, not just the unobstructed
> area, when drawing the screen - failing to do so may cause unexpected
> graphics to be drawn behind the quick view, during animations.

```c
static void hands_update_proc(Layer *layer, GContext *ctx) {
  GRect bounds = layer_get_unobstructed_bounds(layer);
  GPoint center = grect_center_point(&bounds);
  const int16_t second_hand_length = (bounds.size.w / 2);
  time_t now = time(NULL);
  struct tm *t = localtime(&now);
  int32_t second_angle = TRIG_MAX_ANGLE * t->tm_sec / 60;
  GPoint second_hand = {
    .x = (int16_t)(sin_lookup(second_angle) * (int32_t)second_hand_length / TRIG_MAX_RATIO) + center.x,
    .y = (int16_t)(-cos_lookup(second_angle) * (int32_t)second_hand_length / TRIG_MAX_RATIO) + center.y,
  };

  // second hand
  graphics_context_set_stroke_color(ctx, GColorWhite);
  graphics_draw_line(ctx, second_hand, center);

  // minute/hour hand
  graphics_context_set_fill_color(ctx, GColorWhite);
  graphics_context_set_stroke_color(ctx, GColorBlack);
  gpath_rotate_to(s_minute_arrow, TRIG_MAX_ANGLE * t->tm_min / 60);
  gpath_draw_filled(ctx, s_minute_arrow);
  gpath_draw_outline(ctx, s_minute_arrow);

  gpath_rotate_to(s_hour_arrow, (TRIG_MAX_ANGLE * (((t->tm_hour % 12) * 6) +
                  (t->tm_min / 10))) / (12 * 6));
  gpath_draw_filled(ctx, s_hour_arrow);
  gpath_draw_outline(ctx, s_hour_arrow);

  // dot in the middle
  graphics_context_set_fill_color(ctx, GColorBlack);
  graphics_fill_rect(ctx, GRect(bounds.size.w / 2 - 1, bounds.size.h / 2 - 1, 3,
  3), 0, GCornerNone);
}
```

### Using Unobstructed Area Handlers

If you are not overriding the default rendering of a ``Layer``, you will need to
subscribe to one or more of the ``UnobstructedAreaHandlers`` to adjust the sizes
and positions of layers.

There are 3 events available using ``UnobstructedAreaHandlers``.
These events will notify you when the unobstructed area is: *about to change*,
*is currently changing*, or *has finished changing*. You can use these handlers
to perform any necessary alterations to your layout.

`.will_change` - an event to inform you that the unobstructed area size is about
to change. This provides a ``GRect`` which lets you know the size of the screen
after the change has finished.

`.change` - an event to inform you that the unobstructed area size is currently
changing. This event is called several times during the animation of an
obstruction appearing or disappearing. ``AnimationProgress`` is provided to let
you know the percentage of progress towards completion.

`.did_change` - an event to inform you that the unobstructed area size has
finished changing. This is useful for deinitializing or destroying anything
created or allocated in the will_change handler.

These handlers are optional, but at least one must be specified for a valid
subscription. In the following example, we subscribe to two of the three
available handlers.

> **NOTE**: You must construct the
> ``UnobstructedAreaHandlers`` object *before* passing it to the
> ``unobstructed_area_service_subscribe()`` method.

```c
UnobstructedAreaHandlers handlers = {
  .will_change = prv_unobstructed_will_change,
  .did_change = prv_unobstructed_did_change
};
unobstructed_area_service_subscribe(handlers, NULL);
```

#### Hiding Layers

In this example, we’re going to hide a ``TextLayer`` containing the current
date, while the screen is obstructed.

Just before the Timeline Quick View appears, we’re going to hide the
``TextLayer`` and we’ll show it again after the Timeline Quick View disappears.

```c
static Window *s_main_window;
static Layer *s_window_layer;
static TextLayer *s_date_layer;
```

Subscribe to the `.did_change` and `.will_change` events:

```c
static void main_window_load(Window *window) {
  // Keep a handle on the root layer
  s_window_layer = window_get_root_layer(window);
  // Subscribe to the will_change and did_change events
  UnobstructedAreaHandlers handlers = {
    .will_change = prv_unobstructed_will_change,
    .did_change = prv_unobstructed_did_change
  };
  unobstructed_area_service_subscribe(handlers, NULL);
}
```

The `will_change` event fires before the size of the unobstructed area changes,
so we need to establish whether the screen is already obstructed, or about to
become obstructed. If there isn’t a current obstruction, that means the
obstruction must be about to appear, so we’ll need to hide our data layer.

```c
static void prv_unobstructed_will_change(GRect final_unobstructed_screen_area,
void *context) {
  // Get the full size of the screen
  GRect full_bounds = layer_get_bounds(s_window_layer);
  if (!grect_equal(&full_bounds, &final_unobstructed_screen_area)) {
    // Screen is about to become obstructed, hide the date
    layer_set_hidden(text_layer_get_layer(s_date_layer), true);
  }
}
```

The `did_change` event fires after the unobstructed size changes, so we can
perform the same check to see whether the screen is already obstructed, or
about to become obstructed. If the screen isn’t obstructed when this event
fires, then the obstruction must have just cleared and we’ll need to display
our date layer again.

```c
static void prv_unobstructed_did_change(void *context) {
  // Get the full size of the screen
  GRect full_bounds = layer_get_bounds(s_window_layer);
  // Get the total available screen real-estate
  GRect bounds = layer_get_unobstructed_bounds(s_window_layer);
  if (grect_equal(&full_bounds, &bounds)) {
    // Screen is no longer obstructed, show the date
    layer_set_hidden(text_layer_get_layer(s_date_layer), false);
  }
}
```

#### Animating Layer Positions

The `.change` event will fire several times while the unobstructed area is
changing size. This allows us to use this event to make our layers appear to
slide-in or slide-out of their initial positions.

In this example, we’re going to use percentages to position two text layers
vertically. One layer at the top of the screen and one layer at the bottom. When
the screen is obstructed, these two layers will shift to be closer together.
Because we’re using percentages, it doesn’t matter if the unobstructed area is
increasing or decreasing, our text layers will always be relatively positioned
in the available space.

```c
static const uint8_t s_offset_top_percent = 33;
static const uint8_t s_offset_bottom_percent = 10;
```

A simple helper function to simulate percentage based coordinates:

```c
uint8_t relative_pixel(int16_t percent, int16_t max) {
  return (max * percent) / 100;
}
```

Subscribe to the change event:

```c
static void main_window_load(Window *window) {
  UnobstructedAreaHandlers handler = {
    .change = prv_unobstructed_change
  };
  unobstructed_area_service_subscribe(handler, NULL);
}
```

Move the text layer each time the unobstructed area size changes:

```c
static void prv_unobstructed_change(AnimationProgress progress, void *context) {
  // Get the total available screen real-estate
  GRect bounds = layer_get_unobstructed_bounds(s_window_layer);
  // Get the current position of our top text layer
  GRect frame = layer_get_frame(text_layer_get_layer(s_top_text_layer));
  // Shift the Y coordinate
  frame.origin.y = relative_pixel(s_offset_top_percent, bounds.size.h);
  // Apply the new location
  layer_set_frame(text_layer_get_layer(s_top_text_layer), frame);
  // Get the current position of our bottom text layer
  GRect frame2 = layer_get_frame(text_layer_get_layer(s_top_text_layer));
  // Shift the Y coordinate
  frame2.origin.y = relative_pixel(s_offset_bottom_percent, bounds.size.h);
  // Apply the new position
  layer_set_frame(text_layer_get_layer(s_bottom_text_layer), frame2);
}
```

### Toggling Timeline Quick View

The `pebble` tool which shipped as part of [SDK 4.0](/sdk4),
allows developers to enable and disable Timeline Quick View, which is
incredibly useful for debugging purposes.

![Unobstructed animation >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/user-interfaces/unobstructed-area/unobstructed-animation.gif)

To enable Timeline Quick View, you can use:

```nc|text
$ pebble emu-set-timeline-quick-view on
```

To disable Timeline Quick View, you can use:

```nc|text
$ pebble emu-set-timeline-quick-view off
```

### Additional Considerations

If you're scaling or moving layers based on the unobstructed area, you must
ensure you fill the entire window, not just the unobstructed area. Failing to do
so may cause unexpected graphics to be drawn behind the quick view, during
animations.

At present, Timeline Quick View is not currently planned for the Chalk platform.

For design reference, the height of the Timeline Quick View overlay will be
*51px* in total, which includes a 2px border, but this may vary on newer
platforms and and the height should always be calculated at runtime.

```c
// Calculate the actual height of the Timeline Quick View
s_window_layer = window_get_root_layer(window);
GRect fullscreen = layer_get_bounds(s_window_layer);
GRect unobstructed_bounds = layer_get_unobstructed_bounds(s_window_layer);

int16_t obstruction_height = fullscreen.size.h - unobstructed_bounds.size.h;
```

## User Interfaces

The User Intefaces section of the developer guide contains information on using
other the Pebble SDK elements that contribute to interface with the user in some
way, shape, or form. For example, ``Layer`` objects form the foundation of all
app user interfaces, while a configuration page asks a user for their input in
terms of preferences.

Graphics-specific UI elements and resources are discussed in the
 and 
 sections.

## Contents

