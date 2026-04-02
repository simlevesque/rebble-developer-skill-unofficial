# Events And Services

> How to get data from the onboard sensors including the accelerometer, compass, and microphone.

## Accelerometer

The acceleromter sensor is included in every Pebble watch, and allows collection
of acceleration and orientation data in watchapps and watchfaces. Data is
available in two ways, each suitable to different types of watchapp:

* Taps events - Fires an event whenever a significant tap or shake of the watch
  occurs. Useful to 'shake to view' features.

* Data batches - Allows collection of data in batches at specific intervals.
  Useful for general accelerometer data colleciton.

As a significant source of regular callbacks, the accelerometer should be used
as sparingly as possible to allow the watch to sleep and conserve power. For
example, receiving data in batches once per second is more power efficient than
receiving a single sample 25 times per second.

## About the Pebble Accelerometer

The Pebble accelerometer is oriented according to the diagram below, showing the
direction of each of the x, y, and z axes.

![accel-axes](/images/guides/pebble-apps/sensors/accel.png)

In the API, each axis value contained in an ``AccelData`` sample is measured in
milli-Gs. The accelerometer is calibrated to measure a maximum acceleration of
±4G. Therefore, the range of possible values for each axis is -4000 to +4000.

The ``AccelData`` sample object also contains a `did_vibrate` field, set to
`true` if the vibration motor was active during the sample collection. This
could possibly contaminate those samples due to onboard vibration, so they
should be discarded. Lastly, the `timestamp` field allows tracking of obtained
accelerometer data over time.

## Using Taps

Adding a subscription to tap events allows a developer to react to any time the
watch is tapped or experiences a shake along one of three axes. Tap events are
received by registering an ``AccelTapHandler`` function, such as the one below:

```c
static void accel_tap_handler(AccelAxisType axis, int32_t direction) {
  // A tap event occured

}
```

The `axis` parameter describes which axis the tap was detected along. The
`direction` parameter is set to `1` for the positive direction, and `-1` for the
negative direction.

A subscription can be added or removed at any time. While subscribed,
`accel_tap_handler` will be called whenever a tap event is fired by the
accelerometer. Adding a subscription is simple:

```c
// Subscribe to tap events
accel_tap_service_subscribe(accel_tap_handler);
```

```c
// Unsubscribe from tap events
accel_tap_service_unsubscribe();
```

## Using Data Batches

Accelerometer data can be received in batches at a chosen sampling rate by
subscribing to the Accelerometer Data Service at any time:

```c
uint32_t num_samples = 3;  // Number of samples per batch/callback

// Subscribe to batched data events
accel_data_service_subscribe(num_samples, accel_data_handler);
```

The ``AccelDataHandler`` function (called `accel_data_handler` in the example
above) is called when a new batch of data is ready for consumption by the
watchapp. The rate at which these occur is dictated by two things:

* The sampling rate - The number of samples the accelerometer device measures
  per second. One value chosen from the ``AccelSamplingRate`` `enum`.

* The number of samples per batch.

Some simple math will determine how often the callback will occur. For example,
at the ``ACCEL_SAMPLING_50HZ`` sampling rate, and specifying 10 samples per
batch will result in five calls per second.

When an event occurs, the acceleromater data can be read from the ``AccelData``
pointer provided in the callback. An example reading the first set of values is
shown below:

```c
static void accel_data_handler(AccelData *data, uint32_t num_samples) {
  // Read sample 0's x, y, and z values
  int16_t x = data[0].x;
  int16_t y = data[0].y;
  int16_t z = data[0].z;

  // Determine if the sample occured during vibration, and when it occured
  bool did_vibrate = data[0].did_vibrate;
  uint64_t timestamp = data[0].timestamp;

  if(!did_vibrate) {
    // Print it out
    APP_LOG(APP_LOG_LEVEL_INFO, "t: %llu, x: %d, y: %d, z: %d",
                                                          timestamp, x, y, z);
  } else {
    // Discard with a warning
    APP_LOG(APP_LOG_LEVEL_WARNING, "Vibration occured during collection");
  }
}
```

The code above will output the first sample in each batch to app logs, which
will look similar to the following:

```nc|text
[15:33:18] -data-service.c:21> t: 1449012797098, x: -111, y: -280, z: -1153
[15:33:18] -data-service.c:21> t: 1449012797305, x: -77, y: 40, z: -1014
[15:33:18] -data-service.c:21> t: 1449012797507, x: -60, y: 4, z: -1080
[15:33:19] -data-service.c:21> t: 1449012797710, x: -119, y: -55, z: -921
[15:33:19] -data-service.c:21> t: 1449012797914, x: 628, y: 64, z: -506
```

## Background Worker

In addition to the main foreground task that every Pebble app implements, a
second background worker task can also be created. This worker is capable of
running even when the foreground task is closed, and is useful for tasks that
must continue for long periods of time. For example, apps that log sensor data.

There are several important points to note about the capabilities of this
worker when compared to those of the foreground task:

* The worker is constrained to 10.5 kB of memory.

* Some APIs are not available to the worker. See the 
  [*Available APIs*](#available-apis) section below for more information.

* There can only be one background worker active at a time. In the event that a
  second one attempts to launch from another watchapp, the user will be asked to
  choose whether the new worker can replace the existing one.

* The user can determine which app's worker is running by checking the
  'Background App' section of the Settings menu. Workers can also be launched
  from there.

* The worker can launch the foreground app using ``worker_launch_app()``. This
  means that the foreground app should be prepared to be launched at any time
  that the worker is running.

> Note: This API should not be used to build background timers; use the
> ``Wakeup`` API instead.

## Adding a Worker

The background worker's behavior is determined by code written in a
separate C file to the foreground app, created in the `/worker_src` project 
directory.

This project structure can also be generated using the 
[`pebble` tool](/guides/tools-and-resources/pebble-tool/) with the `--worker`
flag as shown below:

```bash
$ pebble new-project --worker project_name
```

The worker C file itself has a basic structure similar to a regular Pebble app,
but with a couple of minor changes, as shown below:

```c
#include <pebble_worker.h>

static void prv_init() {
  // Initialize the worker here
}

static void prv_deinit() {
  // Deinitialize the worker here
}

int main(void) {
  prv_init();
  worker_event_loop();
  prv_deinit();
}
```

## Launching the Worker

To launch the worker from the foreground app, use ``app_worker_launch()``:

```c
// Launch the background worker
AppWorkerResult result = app_worker_launch();
```

The ``AppWorkerResult`` returned will indicate any errors encountered as a
result of attempting to launch the worker. Possible result values include:

| Result | Value | Description |
|--------|-------|:------------|
| ``APP_WORKER_RESULT_SUCCESS`` | `0` | The worker launch was successful, but may not start running immediately. Use ``app_worker_is_running()`` to determine when the worker has started running. |
| ``APP_WORKER_RESULT_NO_WORKER`` | `1` | No worker found for the current app. |
| ``APP_WORKER_RESULT_ALREADY_RUNNING`` | `4` | The worker is already running. |
| ``APP_WORKER_RESULT_ASKING_CONFIRMATION`` | `5` | The user will be asked for confirmation. To determine whether the worker was given permission to launch, use ``app_worker_is_running()`` for a short period after receiving this result. |

## Communicating Between Tasks

There are three methods of passing data between the foreground and background 
worker tasks:

* Save the data using the ``Storage`` API, then read it in the other task.

* Send the data to a companion phone app using the ``DataLogging`` API. Details
  on how to do this are available in .

* Pass the data directly while the other task is running, using an
  ``AppWorkerMessage``. These messages can be sent bi-directionally by creating 
  an `AppWorkerMessageHandler` in each task. The handler will fire in both the 
  foreground and the background tasks, so you must identify the source 
  of the message using the `type` parameter. 

    ```c
    // Used to identify the source of a message
    #define SOURCE_FOREGROUND 0
    #define SOURCE_BACKGROUND 1
    ```

    **Foreground App**

    ```c
    static int s_some_value = 1;
    static int s_another_value = 2;

    static void worker_message_handler(uint16_t type, 
                                        AppWorkerMessage *message) {
      if(type == SOURCE_BACKGROUND) {
        // Get the data, only if it was sent from the background
        s_some_value = message->data0;
        s_another_value = message->data1;
      }
    }

    // Subscribe to get AppWorkerMessages
    app_worker_message_subscribe(worker_message_handler);

    // Construct a message to send
    AppWorkerMessage message = {
      .data0 = s_some_value,
      .data1 = s_another_value
    };

    // Send the data to the background app
    app_worker_send_message(SOURCE_FOREGROUND, &message);

    ```

    **Worker**

    ```c
    static int s_some_value = 3;
    static int s_another_value = 4;

    // Construct a message to send
    AppWorkerMessage message = {
      .data0 = s_some_value,
      .data1 = s_another_value
    };

    static void worker_message_handler(uint16_t type, 
                                        AppWorkerMessage *message) {
      if(type == SOURCE_FOREGROUND) {
        // Get the data, if it was sent from the foreground
        s_some_value = message->data0;
        s_another_value = message->data1;
      }
    }

    // Subscribe to get AppWorkerMessages
    app_worker_message_subscribe(worker_message_handler);

    // Send the data to the foreground app
    app_worker_send_message(SOURCE_BACKGROUND, &message);
    ```

## Managing the Worker

The current running state of the background worker can be determined using the
``app_worker_is_running()`` function:

```c
// Check to see if the worker is currently active
bool running = app_worker_is_running();
```

The user can tell whether the worker is running by checking the system
'Background App' settings. Any installed workers with be listed there.

The worker can be stopped using ``app_worker_kill()``:

```c
// Stop the background worker
AppWorkerResult result = app_worker_kill();
```

Possible `result` values when attempting to kill the worker are as follows:

| Result | Value | Description |
|--------|-------|:------------|
| ``APP_WORKER_RESULT_SUCCESS`` | `0` | The worker launch was killed successfully. |
| ``APP_WORKER_RESULT_DIFFERENT_APP`` | `2` | A worker from a different app is running, and cannot be killed by this app. |
| ``APP_WORKER_RESULT_NOT_RUNNING`` | `3` | The worker is not currently running. |

## Available APIs

Background workers do not have access to the UI APIs. They also cannot use the
``AppMessage`` API or load resources. Most other APIs are available including
(but not limited to) ``AccelerometerService``, ``CompassService``,
``DataLogging``, ``HealthService``, ``ConnectionService``,
``BatteryStateService``, ``TickTimerService`` and ``Storage``.

The compiler will throw an error if the developer attempts to use an API
unsupported by the worker. For a definitive list of available APIs, check
`pebble_worker.h` in the SDK bundle for the presence of the desired API.

## Buttons

Button [`Clicks`](``Clicks``) are the primary input method on Pebble. All Pebble
watches come with the same buttons available, shown in the diagram below for
Pebble Time:

![button-layout](/images/guides/sensors-and-input/button-layout.png)

These buttons are used in a logical fashion throughout the system:

* Back - Navigates back one ``Window`` until the watchface is reached.

* Up - Navigates to the previous item in a list, or opens the past timeline when
  pressed from the watchface.

* Select - Opens the app launcher from the watchface, accepts a selected option
  or list item, or launches the next ``Window``.

* Down - Navigates to the next item in a list, or opens the future timeline when
  pressed from the watchface.

Developers are highly encouraged to follow these patterns when using button
clicks in their watchapps, since users will already have an idea of what each
button will do to a reasonable degree, thus avoiding the need for lengthy usage
instructions for each app. Watchapps that wish to use each button for a specific
action should use the ``ActionBarLayer`` or ``ActionMenu`` to give hints about
what each button will do.

## Listening for Button Clicks

Button clicks are received via a subscription to one of the types of button
click events listed below. Each ``Window`` that wishes to receive button click
events must provide a ``ClickConfigProvider`` that performs these subscriptions.

The first step is to create the ``ClickConfigProvider`` function:

```c
static void click_config_provider(void *context) {
  // Subcribe to button click events here

}
```

The second step is to register the ``ClickConfigProvider`` with the current
``Window``, typically after ``window_create()``:

```c
// Use this provider to add button click subscriptions
window_set_click_config_provider(window, click_config_provider);
```

The final step is to write a ``ClickHandler`` function for each different type
of event subscription required by the watchapp. An example for a single click
event is shown below:

```c
static void select_click_handler(ClickRecognizerRef recognizer, void *context) {
  // A single click has just occured

}
```

## Types of Click Events

There are five types of button click events that apps subscribe to, enabling
virtually any combination of up/down/click events to be utilized in a watchapp.
The usage of each of these is explained below:

### Single Clicks

Most apps will use this type of click event, which occurs whenever the button
specified is pressed and then immediately released. Use
``window_single_click_subscribe()`` from a ``ClickConfigProvider`` function,
supplying the ``ButtonId`` value for the chosen button and the name of the
``ClickHandler`` that will receive the events:

```c
static void click_config_provider(void *context) {
  ButtonId id = BUTTON_ID_SELECT;  // The Select button

  window_single_click_subscribe(id, select_click_handler);
}
```

### Single Repeating Clicks

Similar to the single click event, the single repeating click event allows
repeating events to be received at a specific interval if the chosen button
is held down for a longer period of time. This makes the task of scrolling
through many list items or incrementing a value significantly easier for the
user, and uses fewer button clicks.

```c
static void click_config_provider(void *context) {
  ButtonId id = BUTTON_ID_DOWN;       // The Down button
  uint16_t repeat_interval_ms = 200;  // Fire every 200 ms while held down

  window_single_repeating_click_subscribe(id, repeat_interval_ms,
                                                down_repeating_click_handler);
}
```

After an initial press (but not release) of the button `id` subscribed to, the
callback will be called repeatedly with an interval of `repeat_interval_ms`
until it is then released.

Developers can determine if the button is still held down after the first
callback by using ``click_recognizer_is_repeating()``, as well as get the number
of callbacks counted so far with ``click_number_of_clicks_counted()``:

```c
static void down_repeating_click_handler(ClickRecognizerRef recognizer,
                                                              void *context) {
  // Is the button still held down?
  bool is_repeating = click_recognizer_is_repeating(recognizer);

  // How many callbacks have been recorded so far?
  uint8_t click_count = click_number_of_clicks_counted(recognizer);
}
```

> Single click and single repeating click subscriptions conflict, and cannot be
> registered for the same button.

### Multiple Clicks

A multi click event will call the ``ClickHandler`` after a specified number of
single clicks has been recorded. A good example of usage is to detect a double
or triple click gesture:

```c
static void click_config_provider(void *context) {
  ButtonId id = BUTTON_ID_SELECT;  // The Select button
  uint8_t min_clicks = 2;          // Fire after at least two clicks
  uint8_t max_clicks = 3;          // Don't fire after three clicks
  uint16_t timeout = 300;          // Wait 300ms before firing
  bool last_click_only = true;     // Fire only after the last click

  window_multi_click_subscribe(id, min_clicks, max_clicks, timeout,
                                 last_click_only, multi_select_click_handler);
}
```

Similar to the single repeating click event, the ``ClickRecognizerRef`` can be
used to determine how many clicks triggered this multi click event using
``click_number_of_clicks_counted()``.

### Long Clicks

A long click event is fired after a button is held down for the specified amount
of time. The event also allows two ``ClickHandler``s to be registered - one for
when the button is pressed, and another for when the button is released. Only
one of these is required.

```c
static void click_config_provider(void *context) {
  ButtonId id = BUTTON_ID_SELECT;  // The select button
  uint16_t delay_ms = 500;         // Minimum time pressed to fire

  window_long_click_subscribe(id, delay_ms, long_down_click_handler,
                                                       long_up_click_handler);
}
```

### Raw Clicks

The last type of button click subcsription is used to track raw button click
events. Like the long click event, two ``ClickHandler``s may be supplied to
receive each of the pressed and depressed events.

```c
static void click_config_provider(void *context) {
  ButtonId id = BUTTON_ID_SELECT;  // The select button

  window_raw_click_subscribe(id, raw_down_click_handler, raw_up_click_handler,
                                                                        NULL);
}
```

> The last parameter is an optional pointer to a context object to be passed to
> the callback, and is set to `NULL` if not used.

## Compass

The ``CompassService`` combines data from Pebble's accelerometer and
magnetometer to automatically calibrate the compass and produce a
``CompassHeading``, containing an angle measured relative to magnetic north.

The compass service provides magnetic north and information about its status 
and accuracy through the ``CompassHeadingData`` structure.

## Calibration

The compass service requires an initial calibration before it can return
accurate results. Calibration is performed automatically by the system when
first required. The [`compass_status`](``CompassHeadingData``) field indicates
whether the compass service is calibrating. To help the calibration process, the
app should show a message to the user asking them to move their wrists in
different directions.

Refer to the [compass example](/feature-compass) for
an example of how to implement this screen.

## Magnetic North and True North

Depending on the user's location on Earth, the measured heading towards magnetic
north and true north can significantly differ. This is due to magnetic
variation, also known as 'declination'.

Pebble does not automatically correct the magnetic heading to return a true
heading, but the API is designed so that this feature can be added in the future
and the app will be able to automatically take advantage of it.

For a more precise heading, use the `magnetic_heading` field of
``CompassHeadingData`` and use a webservice to retrieve the declination at the
user's current location. Otherwise, use the `true_heading` field. This field
will contain the `magnetic_heading` if declination is not available, or the true
heading if declination is available. The field `is_declination_valid` will be
true when declination is available. Use this information to tell the user
whether the app is showing magnetic north or true north.

![Declination illustrated](/images/guides/pebble-apps/sensors/declination.gif)

> To see the true extent of declination, see how declination has
> [changed over time](http://maps.ngdc.noaa.gov/viewers/historical_declination/).

## Battery Considerations

Using the compass will turn on both Pebble's magnetometer and accelerometer.
Those two devices will have a slight impact on battery life. A much more
significant battery impact will be caused by redrawing the screen too often or
performing CPU-intensive work every time the compass heading is updated.

Use ``compass_service_subscribe()`` if the app only needs to update its UI when
new compass data is available, or else use ``compass_service_peek()`` if this
happens much less frequently.

## Defining "Up" on Pebble

Compass readings are always relative to the current orientation of Pebble. Using
the accelerometer, the compass service figures out which direction the user is
facing.

![Compass Orientation](/images/guides/pebble-apps/sensors/compass-orientation.png)

The best orientation to encourage users to adopt while using a compass-enabled
watchapp is with the top of the watch parallel to the ground. If the watch is
raised so that the screen is facing the user, the plane will now be
perpedicular to the screen, but still parallel to the ground.

## Angles and Degrees 

The magnetic heading value is presented as a number between 0 and 
TRIG_MAX_ANGLE (65536). This range is used to give a higher level of 
precision for drawing commands, which is preferable to using only 360 degrees. 

If you imagine an analogue clock face on your Pebble, the angle 0 is always at 
the 12 o'clock position, and the magnetic heading angle is calculated in a 
counter clockwise direction from 0.

This can be confusing to grasp at first, as it’s opposite of how direction is 
measured on a compass, but it's simple to convert the values into a clockwise 
direction:

```c
int clockwise_angle = TRIG_MAX_ANGLE - heading_data.magnetic_heading;
```

Once you have an angle relative to North, you can convert that to degrees using 
the helper function `TRIGANGLE_TO_DEG()`:

```c
int degrees = TRIGANGLE_TO_DEG(TRIG_MAX_ANGLE - heading_data.magnetic_heading);
```

## Subscribing to Compass Data

Compass heading events can be received in a watchapp by subscribing to the
``CompassService``:

```c
// Subscribe to compass heading updates
compass_service_subscribe(compass_heading_handler);
```

The provided ``CompassHeadingHandler`` function (called
`compass_heading_handler` above) can be used to read the state of the compass,
and the current heading if it is available. This value is given in the range of
`0` to ``TRIG_MAX_ANGLE`` to preserve precision, and so it can be converted
using the ``TRIGANGLE_TO_DEG()`` macro:

```c
static void compass_heading_handler(CompassHeadingData heading_data) {
  // Is the compass calibrated?
  switch(heading_data.compass_status) {
    case CompassStatusDataInvalid:
      APP_LOG(APP_LOG_LEVEL_INFO, "Not yet calibrated.");
      break;
    case CompassStatusCalibrating:
      APP_LOG(APP_LOG_LEVEL_INFO, "Calibration in progress. Heading is %ld",
                TRIGANGLE_TO_DEG(TRIG_MAX_ANGLE - heading_data.magnetic_heading));
      break;
    case CompassStatusCalibrated:
      APP_LOG(APP_LOG_LEVEL_INFO, "Calibrated! Heading is %ld",
                TRIGANGLE_TO_DEG(TRIG_MAX_ANGLE - heading_data.magnetic_heading));
      break;
  }
}
```

By default, the callback will be triggered whenever the heading changes by one
degree. To reduce the frequency of updates, change the threshold for heading
changes by setting a heading filter:

```c
// Only notify me when the heading has changed by more than 5 degrees.
compass_service_set_heading_filter(DEG_TO_TRIGANGLE(5));
```

## Unsubscribing From Compass Data

When the app is done using the compass, stop receiving callbacks by
unsubscribing:

```c
compass_service_unsubscribe();
```

## Peeking at Compass Data

To fetch a compass heading without subscribing, simply peek to get a single
sample:

```c
// Peek to get data
CompassHeadingData data;
compass_service_peek(&data);
```

> Similar to the subscription-provided data, the app should examine the peeked
> `CompassHeadingData` to determine if it is valid (i.e. the compass is
> calibrated).

## Dictation

On hardware [platforms](/faqs/#pebble-sdk) supporting a microphone, the 
``Dictation`` API can be used to gather arbitrary text input from a user. 
This approach is much faster than any previous button-based text input system 
(such as [tertiary text](https://github.com/vgmoose/tertiary_text)), and 
includes the ability to allow users to re-attempt dictation if there are any 
errors in the returned transcription.

> Note: Apps running on multiple hardware platforms that may or may not include
> a microphone should use the `PBL_MICROPHONE` compile-time define (as well as
> checking API return values) to gracefully handle when it is not available.

## How the Dictation API Works

The ``Dictation`` API invokes the same UI that is shown to the user when
responding to notifications via the system menu, with events occuring in the
following order:

* The user initiates transcription and the dictation UI is displayed.

* The user dictates the phrase they would like converted into text.

* The audio is transmitted via the Pebble phone application to a 3rd party
  service and translated into text.

* When the text is returned, the user is given the opportunity to review the
  result of the transcription. At this time they may elect to re-attempt the
  dictation by pressing the Back button and speaking clearer.

* When the user is happy with the transcription, the text is provided to the
  app by pressing the Select button.

* If an error occurs in the transcription attempt, the user is automatically
  allowed to re-attempt the dictation.

* The user can retry their dictation by rejecting a successful transcription,
  but only if confirmation dialogs are enabled.

## Beginning a Dictation Session

To get voice input from a user, an app must first create a ``DictationSession``
that contains data relating to the status of the dictation service, as well as
an allocated buffer to store the result of any transcriptions. This should be
declared in the file-global scope (as `static`), so it can be used at any time
(in button click handlers, for example).

```c
static DictationSession *s_dictation_session;
```

A callback of type ``DictationSessionStatusCallback`` is also required to notify
the developer to the status of any dictation requests and transcription results.
This is called at any time the dictation UI exits, which can be for any of the
following reasons:

* The user accepts a transcription result.

* A transcription is successful but the confirmation dialog is disabled.

* The user exits the dictation UI with the Back button.

* When any error occurs and the error dialogs are disabled.

* Too many transcription errors occur.

```c
static void dictation_session_callback(DictationSession *session, DictationSessionStatus status,
                                       char *transcription, void *context) {
  // Print the results of a transcription attempt
  APP_LOG(APP_LOG_LEVEL_INFO, "Dictation status: %d", (int)status);
}
```

At the end of this callback the `transcription` pointer becomes invalid - if the
text is required later it should be copied into a separate buffer provided by
the app. The size of this dictation buffer is chosen by the developer, and
should be large enough to accept all expected input. Any transcribed text longer
than the length of the buffer will be truncated.

```c
// Declare a buffer for the DictationSession
static char s_last_text[512];
```

Finally, create the ``DictationSession`` and supply the size of the buffer and
the ``DictationSessionStatusCallback``. This session may be used as many times
as requires for multiple transcriptions. A context pointer may also optionally
be provided.

```c
// Create new dictation session
s_dictation_session = dictation_session_create(sizeof(s_last_text),
                                               dictation_session_callback, NULL);
```

## Obtaining Dictated Text

After creating a ``DictationSession``, the developer can begin a dictation
attempt at any time, providing that one is not already in progress.

```c
// Start dictation UI
dictation_session_start(s_dictation_session);
```

The dictation UI will be displayed and the user will speak their desired input.

![listening >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/pebble-apps/sensors/listening.png)

It is recommended to provide visual guidance on the format of the expected input
before the ``dictation_session_start()`` is called. For example, if the user is
expected to speak a location that should be a city name, they should be briefed
as such before being asked to provide input.

When the user exits the dictation UI, the developer's
``DictationSessionStatusCallback`` will be called. The `status` parameter
provided will inform the developer as to whether or not the transcription was
successful using a ``DictationSessionStatus`` value. It is useful to check this
value, as there are multiple reasons why a dictation request may not yield a
successful result. These values are described below under
[*DictationSessionStatus Values*](#dictationsessionstatus-values).

If the value of `status` is equal to ``DictationSessionStatusSuccess``, the
transcription was successful. The user's input can be read from the
`transcription` parameter for evaluation and storage for later use if required.
Note that once the callback returns, `transcription` will no longer be valid.

For example, a ``TextLayer`` in the app's UI with variable name `s_output_layer`
may be used to show the status of an attempted transcription:

```c
if(status == DictationSessionStatusSuccess) {
  // Display the dictated text
  snprintf(s_last_text, sizeof(s_last_text), "Transcription:\n\n%s", transcription);
  text_layer_set_text(s_output_layer, s_last_text);
} else {
  // Display the reason for any error
  static char s_failed_buff[128];
  snprintf(s_failed_buff, sizeof(s_failed_buff), "Transcription failed.\n\nReason:\n%d",
           (int)status);
  text_layer_set_text(s_output_layer, s_failed_buff);
}
```

The confirmation mechanism allowing review of the transcription result can be
disabled if it is not needed. An example of such a scenario may be to speed up a
'yes' or 'no' decision where the two expected inputs are distinct and different.

```c
// Disable the confirmation screen
dictation_session_enable_confirmation(s_dictation_session, false);
```

It is also possible to disable the error dialogs, if so desired. This will
disable the dialogs that appear when a transcription attempt fails, as well as
disabling the ability to retry the dictation if a failure occurs.

```
// Disable error dialogs
dictation_session_enable_error_dialogs(s_dictation_session, false);
```

### DictationSessionStatus Values

These are the possible values provided by a ``DictationSessionStatusCallback``,
and should be used to handle transcription success or failure for any of the
following reasons.

| Status | Value | Description |
|--------|-------|-------------|
| ``DictationSessionStatusSuccess`` | `0` | Transcription successful, with a valid result. |
| ``DictationSessionStatusFailureTranscriptionRejected`` | `1` | User rejected transcription and dismissed the dictation UI. |
| ``DictationSessionStatusFailureTranscriptionRejectedWithError`` | `2` | User exited the dictation UI after a transcription error. |
| ``DictationSessionStatusFailureSystemAborted`` | `3` | Too many errors occurred during transcription and the dictation UI exited. |
| ``DictationSessionStatusFailureNoSpeechDetected`` | `4` | No speech was detected and the dictation UI exited. |
| ``DictationSessionStatusFailureConnectivityError`` | `5` | No Bluetooth or Internet connection available. |
| ``DictationSessionStatusFailureDisabled`` | `6` | Voice transcription disabled for this user. This can occur if the user has disabled sending 'Usage logs' in the Pebble mobile app. |
| ``DictationSessionStatusFailureInternalError`` | `7` | Voice transcription failed due to an internal error. |
| ``DictationSessionStatusFailureRecognizerError`` | `8` | Cloud recognizer failed to transcribe speech (only possible if error dialogs are disabled). |

## Event Services

All Pebble apps are executed in three phases, which are summarized below:

* Initialization - all code from the beginning of `main()` is run to set up all
  the components of the app.

* Event Loop - the app waits for and responds to any event services it has
  subscribed to.

* Deinitialization - when the app is exiting (i.e.: the user has pressed Back
  from the last ``Window`` in the stack) ``app_event_loop()`` returns, and all
  deinitialization code is run before the app exits.

Once ``app_event_loop()`` is called, execution of `main()` pauses and all
further activities are performed when events from various ``Event Service``
types occur. This continues until the app is exiting, and is typically handled
in the following pattern:

```c
static void init() {
  // Initialization code here
}

static void deinit() {
  // Deinitialization code here
}

int main(void) {
  init();
  app_event_loop();
  deinit();
}
```

## Types of Events

There are multiple types of events an app can receive from various event
services. These are described in the table below, along with their handler
signature and a brief description of what they do:

| Event Service | Handler(s) | Description |
|---------------|------------|-------------|
| ``TickTimerService`` | ``TickHandler`` | Most useful for watchfaces. Allows apps to be notified when a second, minute, hour, day, month or year ticks by. |
| ``ConnectionService`` | ``ConnectionHandler`` | Allows apps to know when the Bluetooth connection with the phone connects and disconnects. |
| ``AccelerometerService`` | ``AccelDataHandler``<br/>``AccelTapHandler`` | Allows apps to receive raw data or tap events from the onboard accelerometer. |
| ``BatteryStateService`` | ``BatteryStateHandler`` | Allows apps to read the state of the battery, as well as whether the watch is plugged in and charging. |
| ``HealthService`` | ``HealthEventHandler`` | Allows apps to be notified to changes in various ``HealthMetric`` values as the user performs physical activities. |
| ``AppFocusService`` | ``AppFocusHandler`` | Allows apps to know when they are obscured by another window, such as when a notification modal appears. |
| ``CompassService`` | ``CompassHeadingHandler`` | Allows apps to read a compass heading, including calibration status of the sensor. |

In addition, many other APIs also operate through the use of various callbacks
including ``MenuLayer``, ``AppMessage``, ``Timer``, and ``Wakeup``, but these
are not considered to be 'event services' in the same sense.

## Using Event Services

The event services described in this guide are all used in the same manner - the
app subscribes an implementation of one or more handlers, and is notified by the
system when an event of that type occurs. In addition, most also include a
'peek' style API to read a single data item or status value on demand. This can
be useful to determine the initial service state when a watchapp starts. Apps
can subscribe to as many of these services as they require, and can also
unsubscribe at any time to stop receiving events.

Each event service is briefly discussed below with multiple snippets - handler
implementation example, subscribing to the service, and any 'peek' API.

### Tick Timer Service

The ``TickTimerService`` allows an app to be notified when different units of
time change. This is decided based upon the ``TimeUnits`` value specified when a
subscription is added.

The [`struct tm`](http://www.cplusplus.com/reference/ctime/tm/) pointer provided
in the handler is a standard C object that contains many data fields describing
the current time. This can be used with
[`strftime()`](http://www.cplusplus.com/reference/ctime/strftime/) to obtain a
human-readable string.

```c
static void tick_handler(struct tm *tick_time, TimeUnits changed) {
  static char s_buffer[8];

  // Read time into a string buffer
  strftime(s_buffer, sizeof(s_buffer), "%H:%M", tick_time);

  APP_LOG(APP_LOG_LEVEL_INFO, "Time is now %s", s_buffer);
}
```

```c
// Get updates when the current minute changes
tick_timer_service_subscribe(MINUTE_UNIT, tick_handler);
```

> The ``TickTimerService`` has no 'peek' API, but a similar effect can be
> achieved using the ``time()`` and ``localtime()`` APIs.

### Connection Service

The ``ConnectionService`` uses a handler for each of two connection types:

* `pebble_app_connection_handler` - the connection to the Pebble app on the
  phone, analogous with the bluetooth connection state.

* `pebblekit_connection_handler` - the connection to an iOS companion app, if
  applicable. Will never occur on Android.

Either one is optional, but at least one must be specified for a valid
subscription.

```c
static void app_connection_handler(bool connected) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Pebble app %sconnected", connected ? "" : "dis");
}

static void kit_connection_handler(bool connected) {
  APP_LOG(APP_LOG_LEVEL_INFO, "PebbleKit %sconnected", connected ? "" : "dis"); 
}
```

```c
connection_service_subscribe((ConnectionHandlers) {
  .pebble_app_connection_handler = app_connection_handler,
  .pebblekit_connection_handler = kit_connection_handler
});
```

```c
// Peek at either the Pebble app or PebbleKit connections
bool app_connection = connection_service_peek_pebble_app_connection();
bool kit_connection = connection_service_peek_pebblekit_connection();
```

### Accelerometer Service

The ``AccelerometerService`` can be used in two modes - tap events and raw data
events. ``AccelTapHandler`` and ``AccelDataHandler`` are used for each of these
respective use cases. See the 
 guide for more
information.

**Data Events**

```c
static void accel_data_handler(AccelData *data, uint32_t num_samples) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Got %d new samples", (int)num_samples);
}
```

```c
const int num_samples = 10;

// Subscribe to data events
accel_data_service_subscribe(num_samples, accel_data_handler);
```

```c
// Peek at the last reading
AccelData data;
accel_service_peek(&data);
```

**Tap Events**

```c
static void accel_tap_handler(AccelAxisType axis, int32_t direction) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Tap event received");
}
```

```c
// Subscribe to tap events
accel_tap_service_subscribe(accel_tap_handler);
```

### Battery State Service

The ``BatteryStateService`` allows apps to examine the state of the battery, and
whether or not is is plugged in and charging.

```c
static void battery_state_handler(BatteryChargeState charge) {
  // Report the current charge percentage
  APP_LOG(APP_LOG_LEVEL_INFO, "Battery charge is %d%%", 
                                                    (int)charge.charge_percent);
}
```

```c
// Get battery state updates
battery_state_service_subscribe(battery_state_handler);
```

```c
// Peek at the current battery state
BatteryChargeState state = battery_state_service_peek();
```

### Health Service

The ``HealthService`` uses the ``HealthEventHandler`` to notify a subscribed app
when new data pertaining to a ``HealthMetric`` is available. See the 
 guide for more information.

```c
static void health_handler(HealthEventType event, void *context) {
  if(event == HealthEventMovementUpdate) {
    APP_LOG(APP_LOG_LEVEL_INFO, "New health movement event");
  }
}
```

```c
// Subscribe to health-related events
health_service_events_subscribe(health_handler, NULL);
```

### App Focus Service

The ``AppFocusService`` operates in two modes - basic and complete. 

**Basic Subscription**

A basic subscription involves only one handler which will be fired when the app
is moved in or out of focus, and any animated transition has completed.

```c
static void focus_handler(bool in_focus) {
  APP_LOG(APP_LOG_LEVEL_INFO, "App is %s in focus", in_focus ? "now" : "not");
}
```

```c
// Add a basic subscription
app_focus_service_subscribe(focus_handler);
```

**Complete Subscription**

A complete subscription will notify the app with more detail about changes in
focus using two handlers in an ``AppFocusHandlers`` object:

* `.will_focus` - represents a change in focus that is *about* to occur, such as
  the start of a transition animation to or from a modal window. `will_focus`
  will be `true` if the app will be in focus at the end of the transition.

* `.did_focus` - represents the end of a transition. `did_focus` will be `true`
  if the app is now completely in focus and the animation has finished.

```c
void will_focus_handler(bool will_focus) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Will %s focus", will_focus ? "gain" : "lose");
}

void did_focus_handler(bool did_focus) {
  APP_LOG(APP_LOG_LEVEL_INFO, "%s focus", did_focus ? "Gained" : "Lost");
}
```

```c
// Subscribe to both types of events
app_focus_service_subscribe_handlers((AppFocusHandlers) {
  .will_focus = will_focus_handler,
  .did_focus = did_focus_handler
});
```

### Compass Service

The ``CompassService`` provides access to regular updates about the watch's
magnetic compass heading, if it is calibrated. See the
 guide for more information.

```c
static void compass_heading_handler(CompassHeadingData heading_data) {
  // Is the compass calibrated?
  if(heading_data.compass_status == CompassStatusCalibrated) {
    APP_LOG(APP_LOG_LEVEL_INFO, "Calibrated! Heading is %ld",
                             TRIGANGLE_TO_DEG(heading_data.magnetic_heading));
  }
}
```

```c
// Subscribe to compass heading updates
compass_service_subscribe(compass_heading_handler);
```

```c
// Peek the compass heading data
CompassHeadingData data;
compass_service_peek(&data);
```

## Pebble Health

[Pebble Health](https://blog.getpebble.com/2015/12/15/health/) provides builtin
health data tracking to allow users to improve their activity and sleep habits.
With SDK 3.9, the ``HealthService`` API opens this data up to developers to
include and use within their apps. For example, a watchface could display a
brief summary of the user's activity for the day.

## API Availability

In order to use the ``HealthService`` (and indeed Pebble Health), the user must
enable the 'Pebble Health' app in the 'Apps/Timeline' view of the official
Pebble mobile app. If this is not enabled health data will not be available to
apps, and API calls will return values to reflect this.

In addition, any app using the ``HealthService`` API must declare the 'health'
capability in order to be accepted by the
[developer portal](). This can be done in `package.json`
in the SDK:

```js
"capabilities": [ "health" ]
```

Since Pebble Health is not available on the Aplite platform, developers should
check the API return values and hence the lack of ``HealthService`` on that
platform gracefully. In addition, the `PBL_HEALTH` define and
`PBL_IF_HEALTH_ELSE()` macro can be used to selectively omit affected code.

## Available Metrics

The ``HealthMetric`` `enum` lists the types of data (or 'metrics') that can be
read using the API. These are described below:

| Metric | Description |
|--------|-------------|
| `HealthMetricStepCount` | The user's step count. |
| `HealthMetricActiveSeconds` | Duration of time the user was considered 'active'. |
| `HealthMetricWalkedDistanceMeters` | Estimation of the distance travelled in meters. |
| `HealthMetricSleepSeconds` | Duration of time the user was considered asleep. |
| `HealthMetricSleepRestfulSeconds` | Duration of time the user was considered in deep restful sleep. |
| `HealthMetricRestingKCalories` | The number of kcal (thousand calories) burned due to resting metabolism. |
| `HealthMetricActiveKCalories` | The number of kcal (thousand calories) burned due to activity. |
| `HealthMetricHeartRateBPM` | The heart rate, in beats per minute. |

## Subscribing to HealthService Events

Like other Event Services, an app can subscribe a handler function to receive a
callback when new health data is available. This is useful for showing
near-realtime activity updates. The handler must be a suitable implementation of
``HealthEventHandler``. The `event` parameter describes the type of each update,
and is one of the following from the ``HealthEventType`` `enum`:

| Event Type | Value | Description |
|------------|-------|-------------|
| `HealthEventSignificantUpdate` | `0` | All data is considered as outdated, apps should re-read all health data. This can happen on a change of the day or in other cases that significantly change the underlying data. |
| `HealthEventMovementUpdate` | `1` | Recent values around `HealthMetricStepCount`, `HealthMetricActiveSeconds`, `HealthMetricWalkedDistanceMeters`, and `HealthActivityMask` changed. |
| `HealthEventSleepUpdate` | `2` | Recent values around `HealthMetricSleepSeconds`, `HealthMetricSleepRestfulSeconds`, `HealthActivitySleep`, and `HealthActivityRestfulSleep` changed. |
| `HealthEventHeartRateUpdate` | `4` | The value of `HealthMetricHeartRateBPM` has changed. |

A simple example handler is shown below, which outputs to app logs the type of
event that fired the callback:

```c
static void health_handler(HealthEventType event, void *context) {
  // Which type of event occurred?
  switch(event) {
    case HealthEventSignificantUpdate:
      APP_LOG(APP_LOG_LEVEL_INFO,
              "New HealthService HealthEventSignificantUpdate event");
      break;
    case HealthEventMovementUpdate:
      APP_LOG(APP_LOG_LEVEL_INFO,
              "New HealthService HealthEventMovementUpdate event");
      break;
    case HealthEventSleepUpdate:
      APP_LOG(APP_LOG_LEVEL_INFO,
              "New HealthService HealthEventSleepUpdate event");
      break;
    case HealthEventHeartRateUpdate:
      APP_LOG(APP_LOG_LEVEL_INFO,
              "New HealthService HealthEventHeartRateUpdate event");
      break;
  }
}
```

The subscription is then registered in the usual way, optionally providing a
`context` parameter that is relayed to each event callback. The return value
should be used to determine whether the subscription was successful:

```c
#if defined(PBL_HEALTH)
// Attempt to subscribe
if(!health_service_events_subscribe(health_handler, NULL)) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Health not available!");
}
#else
APP_LOG(APP_LOG_LEVEL_ERROR, "Health not available!");
#endif
```

## Reading Health Data

Health data is collected in the background as part of Pebble Health regardless
of the state of the app using the ``HealthService`` API, and is available to
apps through various ``HealthService`` API functions.

Before reading any health data, it is recommended to check that data is
available for the desired time range, if applicable. In addition to the
``HealthServiceAccessibilityMask`` value, health-related code can be
conditionally compiled using `PBL_HEALTH`. For example, to check whether
any data is available for a given time range:

```c
#if defined(PBL_HEALTH)
// Use the step count metric
HealthMetric metric = HealthMetricStepCount;

// Create timestamps for midnight (the start time) and now (the end time)
time_t start = time_start_of_today();
time_t end = time(NULL);

// Check step data is available
HealthServiceAccessibilityMask mask = health_service_metric_accessible(metric,
                                                                    start, end);
bool any_data_available = mask & HealthServiceAccessibilityMaskAvailable;
#else
// Health data is not available here
bool any_data_available = false;
#endif
```

Most applications will want to read the sum of a metric for the current day's
activity. This is the simplest method for accessing summaries of users' health
data, and is shown in the example below:

```c
HealthMetric metric = HealthMetricStepCount;
time_t start = time_start_of_today();
time_t end = time(NULL);

// Check the metric has data available for today
HealthServiceAccessibilityMask mask = health_service_metric_accessible(metric,
  start, end);

if(mask & HealthServiceAccessibilityMaskAvailable) {
  // Data is available!
  APP_LOG(APP_LOG_LEVEL_INFO, "Steps today: %d",
          (int)health_service_sum_today(metric));
} else {
  // No data recorded yet today
  APP_LOG(APP_LOG_LEVEL_ERROR, "Data unavailable!");
}
```

For more specific data queries, the API also allows developers to request data
records and sums of metrics from a specific time range. If data is available, it
can be read as a sum of all values recorded between that time range. You can use
the convenience constants from ``Time``, such as ``SECONDS_PER_HOUR`` to adjust
a timestamp relative to the current moment returned by ``time()``.

> Note: The value returned will be an average since midnight, weighted for the
> length of the specified time range. This may change in the future.

An example of this process is shown below:

```c
// Make a timestamp for now
time_t end = time(NULL);

// Make a timestamp for the last hour's worth of data
time_t start = end - SECONDS_PER_HOUR;

// Check data is available
HealthServiceAccessibilityMask result =
    health_service_metric_accessible(HealthMetricStepCount, start, end);
if(result & HealthServiceAccessibilityMaskAvailable) {
  // Data is available! Read it
  HealthValue steps = health_service_sum(HealthMetricStepCount, start, end);

  APP_LOG(APP_LOG_LEVEL_INFO, "Steps in the last hour: %d", (int)steps);
} else {
  APP_LOG(APP_LOG_LEVEL_ERROR, "No data available!");
}
```

## Representing Health Data

Depending on the locale of the user, the conventional measurement system used to
represent distances may vary between metric and imperial. For this reason it is
recommended to query the user's preferred ``MeasurementSystem`` before
formatting distance data from the ``HealthService``:

> Note: This API is currently only meaningful when querying the
> ``HealthMetricWalkedDistanceMeters`` metric. ``MeasurementSystemUnknown`` will
> be returned for all other queries.

```c
const HealthMetric metric = HealthMetricWalkedDistanceMeters;
const HealthValue distance = health_service_sum_today(metric);

// Get the preferred measurement system
MeasurementSystem system = health_service_get_measurement_system_for_display(
                                                                        metric);

// Format accordingly
static char s_buffer[32];
switch(system) {
  case MeasurementSystemMetric:
    snprintf(s_buffer, sizeof(s_buffer), "Walked %d meters", (int)distance);
    break;
  case MeasurementSystemImperial: {
    // Convert to imperial first
    int feet = (int)((float)distance * 3.28F);
    snprintf(s_buffer, sizeof(s_buffer), "Walked %d feet", (int)feet);
  } break;
  case MeasurementSystemUnknown:
  default:
    APP_LOG(APP_LOG_LEVEL_INFO, "MeasurementSystem unknown or does not apply");
}

// Display to user in correct units
text_layer_set_text(s_some_layer, s_buffer);
```

## Obtaining Averaged Data

The ``HealthService`` also allows developers to read average values of a
particular ``HealthMetric`` with varying degrees of scope. This is useful for
apps that wish to display an average value (e.g.: as a goal for the user)
alongside a summed value.

In this context, the `start` and `end` parameters specify the time period to be
used for the daily average calculation. For example, a start time of midnight
and an end time ten hours later will return the average value for the specified
metric measured until 10 AM on average across the days specified by the scope.

The ``HealthServiceTimeScope`` specified when querying for averaged data over a
given time range determines how the average is calculated, as detailed in the
table below:

| Scope Type | Description |
|------------|-------------|
| `HealthServiceTimeScopeOnce` | No average computed. The result is the same as calling ``health_service_sum()``. |
| `HealthServiceTimeScopeWeekly` | Compute average using the same day from each week (up to four weeks). For example, every Monday if the provided time range falls on a Monday. |
| `HealthServiceTimeScopeDailyWeekdayOrWeekend` | Compute average using either weekdays (Monday to Friday) or weekends (Saturday and Sunday), depending on which day the provided time range falls. |
| `HealthServiceTimeScopeDaily` | Compute average across all days of the week. |

> Note: If the difference between the start and end times is greater than one
> day, an average will be returned that takes both days into account. Similarly,
> if the time range crosses between scopes (such as including weekend days and
> weekdays with ``HealthServiceTimeScopeDailyWeekdayOrWeekend``), the start time
> will be used to determine which days are used.

Reading averaged data values works in a similar way to reading sums. The example
below shows how to read an average step count across all days of the week for a
given time range:

```c
// Define query parameters
const HealthMetric metric = HealthMetricStepCount;
const HealthServiceTimeScope scope = HealthServiceTimeScopeDaily;

// Use the average daily value from midnight to the current time
const time_t start = time_start_of_today();
const time_t end = time(NULL);

// Check that an averaged value is accessible
HealthServiceAccessibilityMask mask =
          health_service_metric_averaged_accessible(metric, start, end, scope);
if(mask & HealthServiceAccessibilityMaskAvailable) {
  // Average is available, read it
  HealthValue average = health_service_sum_averaged(metric, start, end, scope);

  APP_LOG(APP_LOG_LEVEL_INFO, "Average step count: %d steps", (int)average);
}
```

## Detecting Activities

It is possible to detect when the user is sleeping using a
``HealthActivityMask`` value. A useful application of this information could be
to disable a watchface's animations or tick at a reduced rate once the user is
asleep. This is done by checking certain bits of the returned value:

```c
// Get an activities mask
HealthActivityMask activities = health_service_peek_current_activities();

// Determine which bits are set, and hence which activity is active
if(activities & HealthActivitySleep) {
  APP_LOG(APP_LOG_LEVEL_INFO, "The user is sleeping.");
} else if(activities & HealthActivityRestfulSleep) {
  APP_LOG(APP_LOG_LEVEL_INFO, "The user is sleeping peacefully.");
} else {
  APP_LOG(APP_LOG_LEVEL_INFO, "The user is not currently sleeping.");
}
```

## Read Per-Minute History

The ``HealthMinuteData`` structure contains multiple types of activity-related
data that are recorded in a minute-by-minute fashion. This style of data access
is best suited to those applications requiring more granular detail (such as
creating a new fitness algorithm). Up to seven days worth of data is available
with this API.

> See [*Notes on Minute-level Data*](#notes-on-minute-level-data) below for more
> information on minute-level data.

The data items contained in the ``HealthMinuteData`` structure are summarized
below:

| Item | Type | Description |
|------|------|-------------|
| `steps` | `uint8_t`  | Number of steps taken in this minute. |
| `orientation` | `uint8_t` | Quantized average orientation, encoding the x-y plane (the "yaw") in the lower 4 bits (360 degrees linearly mapped to 1 of 16 values) and the z axis (the "pitch") in the upper 4 bits. |
| `vmc` | `uint16_t` | Vector Magnitude Counts (VMC). This is a measure of the total amount of movement seen by the watch. More vigorous movement yields higher VMC values. |
| `is_invalid` | `bool` | `true` if the item doesn't represent actual data, and should be ignored. |
| `heart_rate_bpm` | `uint8_t` | Heart rate in beats per minute (if available). |

These data items can be obtained in the following manner, similar to obtaining a
sum.

```c
// Create an array to store data
const uint32_t max_records = 60;
HealthMinuteData *minute_data = (HealthMinuteData*)
                              malloc(max_records * sizeof(HealthMinuteData));

// Make a timestamp for 15 minutes ago and an hour before that
time_t end = time(NULL) - (15 * SECONDS_PER_MINUTE);
time_t start = end - SECONDS_PER_HOUR;

// Obtain the minute-by-minute records
uint32_t num_records = health_service_get_minute_history(minute_data,
                                                  max_records, &start, &end);
APP_LOG(APP_LOG_LEVEL_INFO, "num_records: %d", (int)num_records);

// Print the number of steps for each minute
for(uint32_t i = 0; i < num_records; i++) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Item %d steps: %d", (int)i,
          (int)minute_data[i].steps);
}
```

Don't forget to free the array once the data is finished with:

```c
// Free the array
free(minute_data);
```

### Notes on Minute-level Data

Missing minute-level records can occur if the watch is reset, goes into low
power (watch-only) mode due to critically low battery, or Pebble Health is
disabled during the time period requested.

``health_service_get_minute_history()`` will return as many **consecutive**
minute-level records that are available after the provided `start` timestamp,
skipping any missing records until one is found. This API behavior enables one
to easily continue reading data after a previous query encountered a missing
minute. If there are some minutes with missing data, the API will return all
available records up to the last available minute, and no further. Conversely,
records returned will begin with the first available record after the provided
`start` timestamp, skipping any missing records until one is found. This can
be used to continue reading data after a previous query encountered a missing
minute.

The code snippet below shows an example function that packs a provided
``HealthMinuteData`` array with all available values in a time range, up to an
arbitrary maximum number. Any missing minutes are collapsed, so that as much
data can be returned as is possible for the allocated array size and time range
requested.

> This example shows querying up to 60 records. More can be obtained, but this
> increases the heap allocation required as well as the time taken to process
> the query.

```c
static uint32_t get_available_records(HealthMinuteData *array, time_t query_start,
                                      time_t query_end, uint32_t max_records) {
  time_t next_start = query_start;
  time_t next_end = query_end;
  uint32_t num_records_found = 0;

  // Find more records until no more are returned
  while (num_records_found < max_records) {
    int ask_num_records = max_records - num_records_found;
    uint32_t ret_val = health_service_get_minute_history(&array[num_records_found],
                                        ask_num_records, &next_start, &next_end);
    if (ret_val == 0) {
      // a 0 return value means no more data is available
      return num_records_found;
    }
    num_records_found += ret_val;
    next_start = next_end;
    next_end = query_end;
  }

  return num_records_found;
}

static void print_last_hours_steps() {
  // Query for the last hour, max 60 minute-level records
  // (except the last 15 minutes)
  const time_t query_end = time(NULL) - (15 * SECONDS_PER_MINUTE);
  const time_t query_start = query_end - SECONDS_PER_HOUR;
  const uint32_t max_records = (query_end - query_start) / SECONDS_PER_MINUTE;
  HealthMinuteData *data =
              (HealthMinuteData*)malloc(max_records * sizeof(HealthMinuteData));

  // Populate the array
  max_records = get_available_records(data, query_start, query_end, max_records);

  // Print the results
  for(uint32_t i = 0; i < max_records; i++) {
    if(!data[i].is_invalid) {
      APP_LOG(APP_LOG_LEVEL_INFO, "Record %d contains %d steps.", (int)i,
                                                            (int)data[i].steps);
    } else {
      APP_LOG(APP_LOG_LEVEL_INFO, "Record %d was not valid.", (int)i);
    }
  }

  free(data);
}
```

## Heart Rate Monitor

The Pebble Time 2 and Pebble 2 (excluding SE model)
 include a
heart rate monitor. This guide will demonstrate how to use the ``HealthService``
API to retrieve information about the user's current, and historical heart
rates.

If you aren't already familiar with the ``HealthService``, we recommended that
you read the 
before proceeding.

## Enable Health Data

Before your application is able to access the heart rate information, you will
need to add `heath` to the `capabilities` array in your applications
`package.json` file.

```js
{
  ...
  "pebble": {
    ...
    "capabilities": [ "health" ],
    ...
  }
}
```

## Data Quality

Heart rate sensors aren't perfect, and their readings can be affected by
improper positioning, environmental factors and excessive movement. The raw data
from the HRM sensor contains a metric to indicate the quality of the readings it
receives.

The HRM API provides a raw BPM reading (``HealthMetricHeartRateRawBPM``) and a
filtered reading (``HealthMetricHeartRateBPM``). This filtered value minimizes
the effect of hand movement and improper sensor placement, by removing the bad
quality readings. This filtered data makes it easy for developers to integrate
in their applications, without needing to filter the data themselves.

## Obtaining the Current Heart Rate

To obtain the current heart rate, you should first check whether the
``HealthMetricHeartRateBPM`` is available by using the
``health_service_metric_accessible`` method.

Then you can obtain the current heart rate using the
``health_service_peek_current_value`` method:

```c
HealthServiceAccessibilityMask hr = health_service_metric_accessible(HealthMetricHeartRateBPM, time(NULL), time(NULL));
if (hr & HealthServiceAccessibilityMaskAvailable) {
  HealthValue val = health_service_peek_current_value(HealthMetricHeartRateBPM);
  if(val > 0) {
    // Display HRM value
    static char s_hrm_buffer[8];
    snprintf(s_hrm_buffer, sizeof(s_hrm_buffer), "%lu BPM", (uint32_t)val);
    text_layer_set_text(s_hrm_layer, s_hrm_buffer);
  }
}
```
> **Note** this value is averaged from readings taken over the past minute, but
due to the [sampling rate](#heart-rate-sample-periods) and our data filters,
this value could be several minutes old. Use `HealthMetricHeartRateRawBPM` for
the raw, unfiltered value.

## Subscribing to Heart Rate Updates

The user's heart rate can also be monitored via an event subscription, in a
similar way to the other health metrics. If you wanted your watchface to update
the displayed heart rate every time the HRM takes a new reading, you could use
the ``health_service_events_subscribe`` method.

```c

static void prv_on_health_data(HealthEventType type, void *context) {
  // If the update was from the Heart Rate Monitor, query it
  if (type == HealthEventHeartRateUpdate) {
    HealthValue value = health_service_peek_current_value(HealthMetricHeartRateBPM);
    // Display the heart rate
  }
}

static void prv_init(void) {
  // Subscribe to health event handler
  health_service_events_subscribe(prv_on_health_data, NULL);
  // ...
}
```

> **Note** The frequency of these updates does not directly correlate to the
> sensor sampling rate.

## Heart Rate Sample Periods

The default sample period is 10 minutes, but the system automatically controls
the HRM sample rate based on the level of user activity. It increases the
sampling rate during intense activity and reduces it again during inactivity.
This aims to provide the optimal battery usage.

### Battery Considerations

Like all active sensors, accelerometer, backlight etc, the HRM sensor will have
a negative affect on battery life. It's important to consider this when using
the APIs within your application.

By default the system will automatically control the heart rate sampling period
for the optimal balance between update frequency and battery usage. In addition,
the APIs have been designed to allow developers to retrieve values for the most
common use cases with minimal impact on battery life.

### Altering the Sampling Period

Developers can request a specific sampling rate using the
``health_service_set_heart_rate_sample_period`` method. The system will use this
value as a suggestion, but does not guarantee that value will be used. The
actual sampling period may be greater or less due to other apps that require
input from the sensor, or data quality issues.

The shortest period you can currently specify is `1` second, and the longest
period you can specify is `600` seconds (10 minutes).

In this example, we will sample the heart rate monitor every second:

```c
// Set the heart rate monitor to sample every second
bool success = health_service_set_heart_rate_sample_period(1);
```
> **Note** This does not mean that you can peek the current value every second,
> only that the sensor will capture more samples.

### Resetting the Sampling Period

Developers **must** reset the heart rate sampling period when their application
exits. Failing to do so may result in the heart rate monitor continuing at the
increased rate for a period of time, even after your application closes. This
is fundamentally different to other Pebble sensors and was designed so that
applications which a reliant upon high sampling rates can be temporarily
interupted for notifications, or music, without affecting the sensor data.

```c
// Reset the heart rate sampling period to automatic
health_service_set_heart_rate_sample_period(0);
```

## Obtaining Historical Data

If your application is using heart rate information, it may also want to obtain
historical data to compare it against. In this section we'll look at how you can
use the `health_service_aggregate` functions to obtain relevant historic data.

Before requesting historic/aggregate data for a specific time period, you
should ensure that it is available using the
``health_service_metric_accessible`` method.

Then we'll use the ``health_service_aggregate_averaged`` method to
obtain the average daily heart rate over the last 7 days.

```c
// Obtain history for last 7 days
time_t end_time = time(NULL);
time_t start_time = end_time - (7 * SECONDS_PER_DAY);

HealthServiceAccessibilityMask hr = health_service_metric_accessible(HealthMetricHeartRateBPM, start_time, end_time);
if (hr & HealthServiceAccessibilityMaskAvailable) {
  uint32_t weekly_avg_hr = health_service_aggregate_averaged(HealthMetricHeartRateBPM,
                              start_time, end_time,
                              HealthAggregationAvg, HealthServiceTimeScopeDaily);
}
```

You can also query the average `min` and `max` heart rates, but only within the
past two hours (maximum). This limitation is due to very limited storage
capacity on the device, but the implementation may change in the future.

```c
// Obtain history for last 1 hour
time_t end_time = time(NULL);
time_t start_time = end_time - SECONDS_PER_HOUR;

HealthServiceAccessibilityMask hr = health_service_metric_accessible(HealthMetricHeartRateBPM, start_time, end_time);
if (hr & HealthServiceAccessibilityMaskAvailable) {
  uint32_t min_hr = health_service_aggregate_averaged(HealthMetricHeartRateBPM,
                                start_time, end_time,
                                HealthAggregationMin, HealthServiceTimeScopeOnce);
  uint32_t max_hr = health_service_aggregate_averaged(HealthMetricHeartRateBPM,
                                start_time, end_time,
                                HealthAggregationMax, HealthServiceTimeScopeOnce);
}
```

## Read Per-Minute History

The ``HealthMinuteData`` structure contains multiple types of activity-related
data that are recorded in a minute-by-minute fashion. Although this structure
now contains HRM readings, it does not contain information about the quality of
those readings.

> **Note** Please refer to the
> 
> for futher information.

## Next Steps

This guide covered the basics of how to interact with realtime and historic
heart information. We encourage you to further explore the ``HealthService``
documentation, and integrate it into your next project.

## Persistent Storage

Developers can use the ``Storage`` API to persist multiple types of data between
app launches, enabling apps to remember information previously entered by the
user. A common use-case of this API is to enable the app to remember
configuration data chosen in an app's configuration page, removing the
tedious need to enter the information on the phone every time the watchapp is
launched. Other use cases include to-to lists, stat trackers, game highscores
etc.

Read  for more information on
implementing an app configuration page.

## Persistent Storage Model

Every app is allocated 4 kB of persistent storage space and can write values to
storage using a key, similar to ``AppMessage`` dictionaries or the web
`localStorage` API. To recall values, the app simply queries the API using the
associated key . Keys are specified in the `uint32_t` type, and each value can
have a size up to ``PERSIST_DATA_MAX_LENGTH`` (currently 256 bytes).

When an app is updated the values saved using the ``Storage`` API will be
persisted, but if it is uninstalled they will be removed.

Apps that make large use of the ``Storage`` API may experience small pauses due
to underlying housekeeping operations. Therefore it is recommended to read and
write values when an app is launching or exiting, or during a time the user is
waiting for some other action to complete.

## Types of Data

Values can be stored as boolean, integer, string, or arbitrary data structure
types. Before retrieving a value, the app should check that it has been
previously persisted. If it has not, a default value should be chosen as
appropriate.

```c
uint32_t key = 0;
int num_items = 0;

if (persist_exists(key)) {
  // Read persisted value
  num_items = persist_read_int(key);
} else {
  // Choose a default value
  num_items = 10;

  // Remember the default value until the user chooses their own value
  persist_write_int(key, num_items);
}
```

The API provides a 'read' and 'write' function for each of these types,
with builtin data types retrieved through assignment, and complex ones into a
buffer provided by the app. Examples of each are shown below.

### Booleans

```c
uint32_t key = 0;
bool large_font_size = true;
```

```c
// Write a boolean value
persist_write_bool(key, large_font_size);
```

```c
// Read the boolean value
bool large_font_size = persist_read_bool(key);
```

### Integers

```c
uint32_t key = 1;
int highscore = 432;
```

```c
// Write an integer
persist_write_int(key, highscore);
```

```c
// Read the integer value
int highscore = persist_read_int(key);
```

### Strings

```c
uint32_t key = 2;
char *string = "Remember this!";
```

```c
// Write the string
persist_write_string(key, string);
```

```c
// Read the string
char buffer[32];
persist_read_string(key, buffer, sizeof(buffer));
```

### Data Structures

```c
typedef struct {
  int a;
  int b;
} Data;

uint32_t key = 3;
Data data = (Data) {
  .a = 32,
  .b = 45
};
```

```c
// Write the data structure
persist_write_data(key, &data, sizeof(Data));
```

```c
// Read the data structure
persist_read_data(key, &data, sizeof(Data));
```

> Note: If a persisted data structure's field layout changes between app
> versions, the data read may no longer be compatible (see below).

## Versioning Persisted Data

As already mentioned, automatic app updates will persist data between app
versions. However, if the format of persisted data changes in a new app version
(or keys change), developers should version their storage scheme and correctly
handle version changes appropriately.

One way to do this is to use an extra persisted integer as the storage scheme's
version number. If the scheme changes, simply update the version number and
migrate existing data as required. If old data cannot be migrated it should be
deleted and replaced with fresh data in the correct scheme from the user. An
example is shown below:

```c
const uint32_t storage_version_key = 786;
const int current_storage_version = 2;
```

```c
// Store the current storage scheme version number
persist_write_int(storage_version_key, current_storage_version);
```

In this example, data stored in a key of `12` is now stored in a key of `13` due
to a new key being inserted higher up the list of key values.

```c
// The scheme has changed, increment the version number
const int current_storage_version = 3;
```

```c
static void migrate_storage_data() {
  // Check the last storage scheme version the app used
  int last_storage_version = persist_read_int(storage_version_key);

  if (last_storage_version == current_storage_version) {
    // No migration necessary
    return;
  }

  // Migrate data
  switch(last_storage_version) {
    case 0:
      // ...
      break;
    case 1:
      // ...
      break;
    case 2: {
      uint32_t old_highscore_key = 12;
      uint32_t new_highscore_key = 13;

      // Migrate to scheme version 3
      int highscore = persist_read_int(old_highscore_key);
      persist_write_int(new_highscore_key, highscore);

      // Delete old data
      persist_delete(old_highscore_key);
      break;
  }

  // Migration is complete, store the current storage scheme version number
  persist_write_int(storage_version_key, current_storage_version);
}
```

## Alternative Method

In addition to the ``Storage`` API, data can also be persisted using the
`localStorage` API in PebbleKit JS, and communicated with the watch over
``AppMessage`` when the app is lanched. However, this method uses more power and
fails if the watch is not connected to the phone.

## Wakeups

The ``Wakeup`` API allows developers to schedule an app launch in the future,
even if the app itself is closed in the meantime. A wakeup event is scheduled in
a similar manner to a ``Timer`` with a future timestamp calculated beforehand.

## Calculating Timestamps

To schedule a wakeup event, first determine the timestamp of the desired wakeup
time as a `time_t` variable. Most uses of the ``Wakeup`` API will fall into
three distinct scenarios discussed below.

### A Future Time

Call ``time()`` and add the offset, measured in seconds. For example, for 30
minutes in the future:

```c
// 30 minutes from now
time_t timestamp = time(NULL) + (30 * SECONDS_PER_MINUTE);
```

### A Specific Time

Use ``clock_to_timestamp()`` to obtain a `time_t` timestamp by specifying a day
of the week and hours and minutes (in 24 hour format). For example, for the next
occuring Monday at 5 PM:

```c
// Next occuring monday at 17:00 
time_t timestamp = clock_to_timestamp(MONDAY, 17, 0);
```

### Using a Timestamp Provided by a Web Service

The timestamp will need to be translated using the 
[`getTimezoneOffset()`](http://www.w3schools.com/jsref/jsref_gettimezoneoffset.asp) 
method available in PebbleKit JS or with any timezone information given by the
web service.

## Scheduling a Wakeup

Once a `time_t` timestamp has been calculated, the wakeup event can be
scheduled:

```c
// Let the timestamp be 30 minutes from now
const time_t future_timestamp = time() + (30 * SECONDS_PER_MINUTE);

// Choose a 'cookie' value representing the reason for the wakeup
const int cookie = 0;

// If true, the user will be notified if they missed the wakeup 
// (i.e. their watch was off)
const bool notify_if_missed = true;

// Schedule wakeup event
WakeupId id = wakeup_schedule(future_timestamp, cookie, notify_if_missed);

// Check the scheduling was successful
if(id >= 0) {
  // Persist the ID so that a future launch can query it
  const wakeup_id_key = 43;
  persist_write_int(wakeup_id_key, id);
}
```

After scheduling a wakeup event it is possible to perform some interaction with
it. For example, reading the timestamp for when the event will occur using the
``WakeupId`` with ``wakeup_query()``, and then perform simple arithmetic to get
the time remaining:

```c
// This will be set by wakeup_query()
time_t wakeup_timestamp = 0;

// Is the wakeup still scheduled?
if(wakeup_query(id, &wakeup_timestamp)) {
  // Get the time remaining
  int seconds_remaining = wakeup_timestamp - time(NULL);
  APP_LOG(APP_LOG_LEVEL_INFO, "%d seconds until wakeup", seconds_remaining);
}
```

To cancel a scheduled event, use the ``WakeupId`` obtained when it was
scheduled:

```c
// Cancel a wakeup
wakeup_cancel(id);
```

To cancel all scheduled wakeup events:

```c
// Cancel all wakeups
wakeup_cancel_all();
```

## Limitations

There are three limitations that should be taken into account when using 
the Wakeup API:

* There can be no more than 8 scheduled wakeup events per app at any one time.

* Wakeup events cannot be scheduled within 30 seconds of the current time.

* Wakeup events are given a one minute window either side of the wakeup time. In
  this time no app may schedule an event. The return ``StatusCode`` of
  ``wakeup_schedule()`` should be checked to determine whether the scheduling of
  the new event should be reattempted. A negative value indicates that the
  wakeup could not be scheduled successfully.

The possible ``StatusCode`` values are detailed below:

|StatusCode|Value|Description|
|----------|-----|-----------|
| `E_RANGE` | `-8` | The wakeup event cannot be scheduled due to another event in that period. |
| `E_INVALID_ARGUMENT` | `-4` | The time requested is in the past. |
| `E_OUT_OF_RESOURCES` | `-7` | The application has already scheduled all 8 wakeup events. |
| `E_INTERNAL` | `-3` | A system error occurred during scheduling. |

## Handling Wakeup Events

A wakeup event can occur at two different times - when the app is closed, and
when it is already launched and in the foreground.

If the app is launched due to a previously scheduled wakeup event, check the
``AppLaunchReason`` and load the app accordingly:

```c
static void init() {
  if(launch_reason() == APP_LAUNCH_WAKEUP) {
    // The app was started by a wakeup event.
    WakeupId id = 0;
    int32_t reason = 0;

    // Get details and handle the event appropriately
    wakeup_get_launch_event(&id, &reason);
  }

  /* other init code */

}
```

If the app is expecting a wakeup to occur while it is open, use a subscription
to the wakeup service to be notified of such events:

```c
static void wakeup_handler(WakeupId id, int32_t reason) {
  // A wakeup event has occurred while the app was already open
}
```

```c
// Subscribe to wakeup service
wakeup_service_subscribe(wakeup_handler);
```

The two approaches can also be combined for a unified response to being woken
up, not depenent on the state of the app:

```c
// Get details of the wakeup
wakeup_get_launch_event(&id, &reason);

// Manually handle using the handler
wakeup_handler(id, reason);
```

## Events and Services

All Pebble watches contain a collection of sensors than can be used as input
devices for apps. Available sensors include four buttons, an accelerometer, and
a magnetometer (accessible via the ``CompassService`` API). In addition, the
Basalt and Chalk platforms also include a microphone (accessible via the
``Dictation`` API) and access to Pebble Health data sets. Read 
 for more information
on sensor availability per platform.

While providing more interactivity, excessive regular use of these sensors will
stop the watch's CPU from sleeping and result in faster battery drain, so use
them sparingly. An alternative to constantly reading accelerometer data is to
obtain data in batches, allowing sleeping periods in between. Read 
 for more information.

## Contents

