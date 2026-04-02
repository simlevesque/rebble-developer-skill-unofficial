# Design And Interaction

> How to design apps to maximise engagement, satisfaction, efficiency and overall user experience.

## Benefits of Design Guidelines

## What are Design Guidelines?

Design guidelines are a set of concepts and rules used to create an app's user
interface. These define how the layout on-screen at any one time should be used
to maximize the efficiency of presenting data to the user, as well as quickly
informing them how to choose their next action. An app creator may look to other
popular apps to determine how they have helped their users understand their
app's purpose, either through the use of iconography or text highlighting. They
may then want to use that inspiration to enable users of the inspiring app to
easily use their own app. If many apps use the same visual cues, then future
users will already be trained in their use when they discover them.

## What are Interaction Patterns?

Similar to design guidelines, interaction patterns define how to implement app
interactivity to maximize its efficiency. If a user can predict how the app will
behave when they take a certain action, or be able to determine which action
fits that which they want to achieve without experimentation, then an intuitive
and rewarding experience will result.

In addition to purely physical actions such as button presses and accelerometer
gestures, the virtual navigation flow should also be considered at the design
stage. It should be intuitive for the user to move around the app screens to
access the information or execute the commands as they would expect on a first
guess. An easy way to achieve this is to use a menu with the items clearly
labelling their associated actions. An alternative is to use explicit icons to
inform the user implicitly of their purpose without needing to label them all.

## Why are They Needed?

Design guidelines and interaction patterns exist to help the developer help the
user by ensuring user interface consistency across applications on the platform.
It is often the case that the developer will have no problem operating their own
watchapp because they have been intimately familiar with how it is supposed to
work since its inception. When such an app is given to users, they may receive
large amounts of feedback from confused users who feel they do not know if an
app supports the functionality they though it did, or even how to find it. By
considering a novice user from the beginning of the UI design and
implementation, this problem can be avoided.

A Pebble watchapp experience is at its best when it can be launched, used for
its purpose in the smallest amount of time, and then closed back to the
watchface. If the user must spend a long time navigating the app's UI to get to
the information they want, or the information takes a while to arrive on every
launch, the app efficiency suffers. To avoid this problem, techniques such as
implementing a list of the most commonly used options in an app (according to
the user or the whole user base) to aid fast navigation, or caching remotely
fetched data which may still be relevant from the last update will improve the
user experience.

From an interaction pattern point of view, a complex layout filled with abstract
icons may confuse a first-time user as to what each of them represents. Apps can
mitigate this problem by using icons that have pre-established meanings across
languages, such as the 'Play/Pause' icon or the 'Power' icon, seen on many forms
of devices.

## What Are the Benefits?

The main benefits of creating and following design guidelines and common
interaction patterns are summarized as follows:

* User interface consistency, which breeds familiarity and predictability.

* Clarity towards which data is most important and hence visible and usable.

* Reduced user confusion and frustration, leading to improved perception of
  apps.

* No need to include explicit usage instructions in every app to explain how it
  must be used.

* Apps that derive design from the system apps can benefit from any learned
  behavior all Pebble users may develop in using their watches out the box.

* Clearer, more efficient and better looking apps!

## Using Existing Affordances

Developers can use concepts and interaction patterns already employed in system
apps and popular 3rd party apps to lend those affordances to your own apps. An
example of this in mobile apps is the common 'swipe down to refresh' action. By
using this action in their app, many mobile app makers can benefit from users
who have already been trained to perform this action, and can free up their
app's UI for a cleaner look, or use the space that would have been used by a
'refresh' button to add an additional feature.

In a similar vein, knowing that the Back button always exits the current
``Window`` in a Pebble app, a user does not have to worry about knowing how to
navigate out of it. Similarly, developers do not have to repeatedly implement
exiting an app, as this action is a single, commonly understood pattern - just
press the Back button! On the other hand, if a developer overrides this action a
user may be confused or frustrated when the app fails to exit as they would
expect, and this could mean a negative opinion that could have been avoided.

## What's Next?

Read  to learn how design
guidelines helped shape the core Pebble system experience.

## Core Experience Design

The core Pebble experience includes several built-in system apps that use
repeatable design and interaction concepts in their implementation. These
are:

* Apps are designed with a single purpose in mind, and they do it well.

* Fast animations are used to draw attention to changing or updating
  information.

* Larger, bolder fonts to highlight important data.

* A preference for displaying multiple data items in a paginated format rather
  than many 'menus within menus'. This is called the 'card' pattern and is
  detail in
  .

* Colors are used to enhance the app's look and feel, and are small in number.
  Colors are also sometimes used to indicate state, such as the temperature in a
  weather app, or to differentiate between different areas of a layout.

## System Experience Design

The core system design and navigation model is a simple metaphor for time on the
user's wrist - a linear representation of the past, present, and future. The
first two are presented using the timeline design, with a press of the Up button
displaying past events (also known as pins), and a press of the Down button
displaying future events. As was the case for previous versions of the system
experience, pressing the Select button opens the app menu. This contains the
system apps, such as Music and Notifications, as well as all the 3rd party apps
the user has installed in their locker.

![system-navigation](/images/guides/design-and-interaction/system-navigation.png)

Evidence of the concepts outlined above in action can be seen within the core
system apps in firmware 3.x. These are described in detail in the sections
below.

### Music

![music](/images/guides/design-and-interaction/music.png)

The Music app is designed with a singular purpose in mind - display the current
song and allow control over playback. To achieve this, the majority of the
screen space is devoted to the most important data such as the song title and
artist. The remainder of the space is largely used to display the most immediate
controls for ease of interaction in an action bar UI element.

The 'previous track' and 'next track' icons on the action bar are ones with
pre-existing affordances which do not require specific instruction for new users
thanks to their universal usaging other media applications. The use of the '...'
icon is used as an additional commonly understood action to indicate more
functionality is available. By single-pressing this action, the available
actions change from preview/next to volume up/volume down, reverting on a
timeout. This is preferable to a long-press, which is typically harder to
discover without an additional prompt included in the UI.

A press of the Back button returns the user to the appface menu, where the Music
appface displays the name and artist of the currently playing track, in a
scrolling 'marquee' manner. If no music is playing, no information is shown
here.

### Notifications

![notifications](/images/guides/design-and-interaction/notifications.png)

The system Notifications app allows a user to access all their past received
notifications in one place. Due to the fact that the number of notifications
received can be either small or large, the main view of the app is implemented
as a menu, with each item showing each notification's icon, title and the first
line of the body content. In this way it is easy for a user to quickly scroll
down the list and identify the notification they are looking for based on these
first hints.

The first item in the menu is a 'Clear All' option, which when selected prompts
the user to confirm this action using a dialog. This dialog uses the action bar
component to give the user the opportunity to confirm this action with the
Select button, or to cancel it with the Back button.

Once the desired item has been found, a press of the Select button opens a more
detailed view, where the complete notification content can be read, scrolling
down if needed. The fact that there is more content available to view is hinted
at using the arrow marker and overlapping region at the bottom of the layout.

### Alarms

![alarms](/images/guides/design-and-interaction/alarms.png)

The Alarms app is the most complex of the system apps, with multiple screens
dedicated to input collection from the user. Like the Watchfaces and Music apps,
the appface in the system menu shows the time of the next upcoming scheduled
alarm, if any. Also in keeping with other system apps, the main screen is
presented using a menu, with each item representing a scheduled alarm. Each
alarm is treated as a separate item, containing different settings and values.

A press of the Select button on an existing item will open the action menu
containing a list of possible actions, such as 'Delete' or 'Disable'. Pressing
Select on the top item ('+') will add a new item to the list, using multiple
subsequent screens to collect data about the alarm the user wishes to schedule.
Using multiple screens avoids the need for one screen to contain a lot of input
components and clutter up the display. In the time selection screen, the current
selection is marked using a green highlight. The Up and Down buttons are used to
increase and decrease the currently selected field respectively.

Once a time and recurring frequency has been chosen by the user, the new alarm
is added to the main menu list. The default state is enabled, marked by the word
'ON' to the right hand side, but can be disabled in which case 'OFF' is
displayed instead.

### Watchfaces

![watchfaces](/images/guides/design-and-interaction/watchfaces.png)

The Watchfaces system app is similar to the Notifications app, in that it uses a
menu as its primary means of navigation. Each watchface available in the user's
locker is shown as a menu item, with a menu icon if one has been included by the
watchface developer. The currently active watchface is indicated by the presence
of 'Active' as that item's subtitle.

Once the user has selected a new watchface, they are shown a confirmation dialog
to let them know their choice was successful. If the watchface is not currently
loaded on the watch, a progress bar is shown briefly while the data is loaded.
Once this is done the newly chosen watchface is displayed.

### Settings

![settings](/images/guides/design-and-interaction/settings.png)

The Settings app uses the system appface to display the date, the battery charge
level, and the Bluetooth connection without the need to open the app proper. If
the user does open the app, they are greeted with a menu allowing a choice of
settings category. This approach saves the need for a single long list of
settings that would require a lot of scrolling.

Once a category has been chosen, the app displays another menu filled with
interactive menu rows that change various settings. Each item shows the name of
the setting in bold as the item title, with the current state of the setting
shown as the subtitle.

When the user presses Select, the state of the currently selected setting is
changed, usually in a binary rotation of On -> Off states. If the setting does
not operate with a binary state (two states), or has more than two options, an
action menu window is displayed with the available actions, allowing the user to
select one with the Select button.

A press of the Back button from a category screen returns the user to the
category list, where they can make another selection, or press Back again to
return to the app menu.

### Sports API

{
  "image": "/images/guides/design-and-interaction/sports.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

The Sports API app is designed around displaying the most immediate relevant
data of a particular sporting activity, such as running or cycling. A suitable
Android or iOS companion app pushes data to this app using the

at regular intervals. This API enables third-party sports app developers to
easily add support for Pebble without needing to create and maintain their own
watchapp.

The high contrast choice of colors makes the information easy to read at a
glance in a wide variety of lighting conditions, ideal for use in outdoor
activities. The action bar is also used to present the main action available to
the user - the easily recognizable 'pause' action to suspend the current
activity for a break. This is replaced by the equally recognizable 'play' icon,
the action now used to resume the activity.

This API also contains a separate Golf app for PebbleKit-compatible apps to
utilize in tracking the user's golf game.

{
  "image": "/images/guides/design-and-interaction/golf.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

The Golf app uses a similar design style with larger fonts for important numbers
in the center of the layout, with the action bar reserved for additional input,
such as moving between holes. Being an app that is intended to be in use for
long periods of time, the status bar is used to display the current time for
quick reference without needing to exit back to the watchface.

## Timeline Experience Design

Evidence of guided design can also be found in other aspects of the system, most
noticeably the timeline view. With pins containing possibly a large variety of
types of information, it is important to display a view which caters for as many
types as possible. As detailed in
,
pins can be shown in two different ways; the event time, icon and title on two
lines or a single line, depending on how the user is currently navigating the
timeline. When a pin is highlighted, as much information is shown to the user as
possible.

![timeline](/images/guides/design-and-interaction/timeline.png)

Users access the timeline view using Up and Down buttons from the watchface to
go into the past and future respectively. The navigation of the timeline also
uses animations for moving elements that gives life to the user interface, and
elements such as moving the pin icon between windows add cohesion between the
different screens. A press of the Select button opens the pin to display all the
information it contains, and is only one click away.

A further press of the Select button opens the pin's action menu, containing a
list of all the actions a user may take. These actions are directly related to
the pin, and can be specified when it is created. The system provides two
default actions: 'Remove' to remove the pin from the user's timeline, and 'Mute
[Name]' to mute all future pins from that source. This gives the user control
over which pins they see in their personal timeline. Mute actions can be
reversed later in the mobile app's 'Apps/Timeline' screen.

## What's Next?

Read  for tips on creating an
intuitive app experience.

## Example Implementations

This guide contains resources and links to code examples that may help
developers implement UI designs and interaction patterns recommended in the
other guides in this section.

## UI Components and Patterns

Developers can make use of the many UI components available in SDK 3.x in
combination with the
 
to ensure the user experience is consistent and intuitive. The following
components and patterns are used in the Pebble experience, and listed in the
table below. Some are components available for developers to use in the SDK, or
are example implementations designed for adaptation and re-use.

| Pattern | Screenshot | Description |
|---------|------------|-------------|
| [`Menu Layer`](``MenuLayer``) | ![](/images/guides/design-and-interaction/menulayer.png) | Show many items in a list, allow scrolling between them, and choose an option. |
| [`Status Bar`](``StatusBarLayer``) | ![](/images/guides/design-and-interaction/alarm-list~basalt.png) | Display the time at the top of the Window, optionally extended with additional data. |
| [`Radio Button List`](/ui-patterns/blob/master/src/windows/radio_button_window.c) | ![](/images/guides/design-and-interaction/radio-button.png) | Allow the user to specify one choice out of a list. |
| [`Checkbox List`](/ui-patterns/blob/master/src/windows/checkbox_window.c) | ![](/images/guides/design-and-interaction/checkbox-list.png) | Allow the user to choose multiple different options from a list. |
| [`List Message`](/ui-patterns/blob/master/src/windows/list_message_window.c) | ![](/images/guides/design-and-interaction/list-message.png) | Provide a hint to help the user choose from a list of options. |
| [`Message Dialog`](/ui-patterns/blob/master/src/windows/dialog_message_window.c) | ![](/images/guides/design-and-interaction/dialog-message.gif) | Show an important message using a bold fullscreen alert. |
| [`Choice Dialog`](/ui-patterns/blob/master/src/windows/dialog_choice_window.c) | ![](/images/guides/design-and-interaction/dialog-choice-patterns.png) | Present the user with an important choice, using the action bar and icons to speed up decision making. |
| [`PIN Entry`](/ui-patterns/blob/master/src/windows/pin_window.c) | ![](/images/guides/design-and-interaction/pin.png) | Enable the user to input integer data. |
| [`Text Animation`](/ui-patterns/blob/master/src/windows/text_animation_window.c) | ![](/images/guides/design-and-interaction/text-change-anim.gif) | Example animation to highlight a change in a text field. |
| [`Progress Bar`](/ui-patterns/blob/master/src/windows/progress_bar_window.c) | ![](/images/guides/design-and-interaction/progress-bar.gif) | Example progress bar implementation on top of a ``StatusBarLayer``. |
| [`Progress Layer`](/ui-patterns/blob/master/src/windows/progress_layer_window.c) | ![](/images/guides/design-and-interaction/progresslayer.gif) | Example implementation of the system progress bar layer. |

## Example Apps

Developers can look at existing apps to begin to design (or improve) their user
interface and interaction design. Many of these apps can be found on the
appstore with links to their source code, and can be used as inspiration.

### Cards Example (Weather)

The weather [`cards-example`](/cards-example)
embodies the 'card' design pattern. Consisting of a single layout, it displays
all the crucial weather-related data in summary without the need for further
layers of navigation. Instead, the buttons are reserved for scrolling between
whole sets of data pertaining to different cities. The number of 'cards' is
shown in the top-right hand corner to let the user know that there is more data
present to be scrolled through, using the pre-existing Up and Down button action
affordances the user has already learned. This helps avoid implementing a novel
navigation pattern, which saves time for both the user and the developer.

![weather >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/weather.gif)

When the user presses the appropriate buttons to scroll through sets of data,
the changing information is animated with fast, snappy, and highly visible
animations to reinforce the idea of old data moving out of the layout and being
physically replaced by new data.

## Round App Design

> This guide is about designing round apps. For advice on implementing a round
> design in code, read .

With the release of the Chalk [platform](/faqs#pebble-sdk), developers must take
new features and limitations into account when designing their apps. New and
existing apps that successfully adapt their layout and colors for both Aplite
and Basalt should also endeavor to do so for the Chalk platform.

## Minor Margins

The Pebble Time Round display requires a small two pixel border on each edge, to
compensate for the bezel design. To this end, it is highly encouraged to allow
for this in an app's design. This may involve stretching a background color to
all outer edges, or making sure that readable information cannot be displayed in
this margin, or else it may not be visible.

Avoid thin rings around the edge of the display, even after accounting for the
two pixel margin as manufacturing variations may cause them to be visibly 
off-center. Instead use thick rings, or inset them significantly from the edge
of the screen.

## Center of Attention

With the round Chalk display, apps no longer have the traditional constant
amount of horizontal space available. This particularly affects the use of the
``MenuLayer``. To compensate for this, menus are now always centered on the
highlighted item. Use this to display additional information in the cell with
the most space available, while showing reduced content previews in the
unhighlighted cells.

![centered >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/design-and-interaction/center-layout~chalk.png)

Menus built using the standard cell drawing functions will automatically adopt
this behavior. If performing custom cell drawing, new APIs are available to
help implement this behavior. For more information, look at the ``Graphics``
documentation, as well as the ``menu_layer_set_center_focused()`` and
``menu_layer_is_index_selected()`` to help with conditional drawing.

## Pagination

Another key concept to bear in mind when designing for a round display is text
flow. In traditional Pebble apps, text in ``ScrollLayer`` or ``TextLayer``
elements could be freely moved and scrolled with per-pixel increments without
issue. However, with a round display each row of text can have a different
width, depending on its vertical position. If such text was reflowed while
moving smoothly down the window, the layout would reflow so often the text would
be very difficult to read.

![center-layout >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/design-and-interaction/scrolling-with-text-flow.gif)

The solution to this problem is to scroll through text in pages, a technique
known as pagination. By moving through the text in discrete sections, the text
is only reflowed once per 'page', and remains easily readable as the user is
navigating through it. The ``ScrollLayer`` has been updated to implement this
on Chalk.

To inform the user that more content is available, the Chalk platform allows use
of the ``ContentIndicator`` UI component. This facilitates the display of two
arrows at the top and bottom of the display, similar to those seen in the
system UI.

![content-indicator >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/design-and-interaction/content-indicator.png)

A ``ContentIndicator`` can be created from scratch and manually managed to
determine when the arrows should be shown, or a built-in instance can be
obtained from a ``ScrollLayer``.

## Platform-Specific Designs

Sometimes a design that made sense on a rectangular display does not make sense
on a circular one, or could be improved. Be open to creating a new UI for the
Chalk platform, and selecting which to use based on the display shape.

For example, in the screenshot below the linear track display was incompatible
with the round display and center-focused menus, leading to a completely
different design on Chalk that shows the same information.

{
  "image": "/images/guides/design-and-interaction/caltrain-stops.png",
  "platforms": [
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

## What's Next?

Read  to learn how to use
and implement the UI components and patterns encouraged in SDK 3.x apps.

## One Click Actions

One click actions are set to revolutionize the way users interact with their
Pebble by providing instant access to their favorite one click watchapps,
directly from the new system launcher. Want to unlock your front door?
Call an Uber? Or perhaps take an instant voice note? With one click actions,
the user is able to instantly perform a single action by launching an app, and
taking no further action.

![Lockitron >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/design-and-interaction/lockitron.png)

### The One Click Flow

It’s important to develop your one click application with a simple and elegant
flow. You need to simplify the process of your application by essentially
creating an application which serves a single purpose.

The typical flow for a one click application would be as follows:

1. Application is launched
2. Application performs action
3. Application displays status to user
4. Application automatically exits to watchface if the action was successful,
or displays status message and does not exit if the action failed

If we were creating an instant voice note watchapp, the flow could be as
follows:

1. Application launched
2. Application performs action (take a voice note)
  1. Start listening for dictation
  2. Accept dictation response
3. Application displays a success message
4. Exit to watchface

In the case of a one click application for something like Uber, we would need to
track the state of any existing booking to prevent ordering a second car. We
would also want to update the ``App Glance``
as the status of the booking changes.

1. Application launched
2. If a booking exists:
  1. Refresh booking status
  2. Update ``App Glance`` with new status
  3. Exit to watchface
3. Application performs action (create a booking)
  1. Update AppGlance: “Your Uber is on it’s way”
  2. Application displays a success message
  3. Exit to watchface

### Building a One Click Application

For this example, we’re going to build a one click watchapp which will lock or
unlock the front door of our virtual house. We’re going to use a virtual
[Lockitron](https://lockitron.com/), or a real one if you’re lucky enough to
have one.

Our flow will be incredibly simple:

1. Launch the application
2. Take an action (toggle the state of the lock)
3. Update the ``App Glance`` to indicate the new lock state
4. Display a success message
5. Exit to watchface

For the sake of simplicity in our example, we will not know if someone else has
locked or unlocked the door using a different application. You can investigate
the [Lockitron API](http://api.lockitron.com) if you want to develop this idea
further.

In order to control our Lockitron, we need the UUID of the lock and an access
key. You can generate your own virtual lockitron UUID and access code on the
[Lockitron website](https://api.lockitron.com/v1/getting_started/virtual_locks).

```c
#define LOCKITRON_LOCK_UUID "95c22a11-4c9e-4420-adf0-11f1b36575f2"
#define LOCKITRON_ACCESS_TOKEN "99e75a775fe737bb716caf88f161460bb623d283c3561c833480f0834335668b"
```

> Never publish your actual Lockitron access token in the appstore, unless you
want strangers unlocking your door! Ideally you would make these fields
configurable using [Clay for Pebble](https://github.com/pebble-dev/clay).

We’re going to need a simple enum for the state of our lock, where 0 is
unlocked, 1 is locked and anything else is unknown.

```c
typedef enum {
  LOCKITRON_UNLOCKED,
  LOCKITRON_LOCKED,
  LOCKITRON_UNKNOWN
} LockitronLockState;
```

We’re also going to use a static variable to keep track of the state of our
lock.

```c
static LockitronLockState s_lockitron_state;
```

When our application launches, we’re going to initialize ``AppMessage`` and
then wait for PebbleKit JS to tell us it’s ready.

```c
static void prv_init(void) {
  app_message_register_inbox_received(prv_inbox_received_handler);
  app_message_open(256, 256);
  s_window = window_create();
  window_stack_push(s_window, false);
}

static void prv_inbox_received_handler(DictionaryIterator *iter, void *context) {
  Tuple *ready_tuple = dict_find(iter, MESSAGE_KEY_APP_READY);
  if (ready_tuple) {
    // PebbleKit JS is ready, toggle the Lockitron!
    prv_lockitron_toggle_state();
    return;
  }
  // ...
}
```

In order to toggle the state of the Lockitron, we’re going to send an
``AppMessage`` to PebbleKit JS, containing our UUID and our access key.

```c
static void prv_lockitron_toggle_state() {
  DictionaryIterator *out;
  AppMessageResult result = app_message_outbox_begin(&out);
  dict_write_cstring(out, MESSAGE_KEY_LOCK_UUID, LOCKITRON_LOCK_UUID);
  dict_write_cstring(out, MESSAGE_KEY_ACCESS_TOKEN, LOCKITRON_ACCESS_TOKEN);
  result = app_message_outbox_send();
}
```

PebbleKit JS will handle this request and make the relevant ajax request to the
Lockitron API. It will then return the current state of the lock and tell our
application to exit back to the default watchface using
``AppExitReason``. See the
[full example](https://github.com/pebble-examples/one-click-action-example) for
the actual Javascript implementation.

```c
static void prv_inbox_received_handler(DictionaryIterator *iter, void *context) {
  // ...
  Tuple *lock_state_tuple = dict_find(iter, MESSAGE_KEY_LOCK_STATE);
  if (lock_state_tuple) {
    // Lockitron state has changed
    s_lockitron_state = (LockitronLockState)lock_state_tuple->value->int32;
    // App will exit to default watchface
    app_exit_reason_set(APP_EXIT_ACTION_PERFORMED_SUCCESSFULLY);
    // Exit the application by unloading the only window
    window_stack_remove(s_window, false);
  }
}
```

Before our application terminates, we need to update the
``App Glance`` with the current state
of our lock. We do this by passing our current lock state into the
``app_glance_reload`` method.

```c
static void prv_deinit(void) {
  window_destroy(s_window);
  // Before the application terminates, setup the AppGlance
  app_glance_reload(prv_update_app_glance, &s_lockitron_state);
}
```

We only need a single ``AppGlanceSlice`` for our ``App Glance``, but it’s worth
noting you can have multiple slices with varying expiration times.

```c
static void prv_update_app_glance(AppGlanceReloadSession *session, size_t limit, void *context) {
  // Check we haven't exceeded system limit of AppGlances
  if (limit < 1) return;

  // Retrieve the current Lockitron state from context
  LockitronLockState *lockitron_state = context;

  // Generate a friendly message for the current Lockitron state
  char *str = prv_lockitron_status_message(lockitron_state);
  APP_LOG(APP_LOG_LEVEL_INFO, "STATE: %s", str);

  // Create the AppGlanceSlice (no icon, no expiry)
  const AppGlanceSlice entry = (AppGlanceSlice) {
    .layout = {
      .template_string = str
    },
    .expiration_time = time(NULL)+3600
  };

  // Add the slice, and check the result
  const AppGlanceResult result = app_glance_add_slice(session, entry);
  if (result != APP_GLANCE_RESULT_SUCCESS) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "AppGlance Error: %d", result);
  }
}
```

### Handling Launch Reasons

In the example above, we successfully created an application that will
automatically execute our One Click Action when the application is launched.
But we also need to be aware of some additional launch reasons where it would
not be appropriate to perform the action.

By using the ``launch_reason()`` method, we can detect why our application was
started and prevent the One Click Action from firing unnecessarily.

A common example, would be to detect if the application was actually started by
the user, from either the launcher, or quick launch.

```c
  if(launch_reason() == APP_LAUNCH_USER || launch_reason() == APP_LAUNCH_QUICK_LAUNCH) {
    // Perform One Click
  } else {
    // Display a message
  }
```

### Conclusion

As you can see, it’s a relatively small amount of code to create one click
watchapps and we hope this inspires you to build your own!

We recommend that you check out the complete
[Lockitron sample](https://github.com/pebble-examples/one-click-action-example)
application and also the ``App Glance`` and ``AppExitReason`` guides for further
information.

## Recommended Guidelines and Patterns

This page contains recommendations for things to consider when designing an
app's visual styles and interaction patterns. The aim here is to encourage
efficiency through optional conformity to common ideas and concepts, and to
breed a consistent experience for users across apps. Developers can also find
suggested interface styles to use when building the navigation of apps to best
display the information contained within.

## Tips for UI Design

To achieve an effective, clear, and intuitive design developers should:

* Keep layouts **simple**, with only as much information displayed as is
  **immediately required**. This encourages quick usage of the app, distracting
  the user for the minimal amount of time necessary for the app to achieve its
  goals.

* Give priority to the **most commonly used/main purpose** functionality of the
  app in the UI. Make it easy to use the biggest features, but still easy to
  find additional functionality that would otherwise be hidden.

* Use **larger fonts** to highlight the **most important data** to be read at a
  glance. Consider font size 28 for larger items, and a minimum of 18 for
  smaller ones.

* Take advantage of colors to convey additional **information without any text**
  if they are already associated as such, such as green for a task complete.

* Try to avoid any colors used in places they may have a **pre-conceived
  meaning** which does not apply, such as red text when there are no errors.

* Use animations to embody the layout with **character** and flourish, as well
  as to **draw the eye** to updated or changing information.

* Ensure the UI gives **direct feedback** to the user's input, or else they may
  think their button presses are having no effect.

## Tips for UI Interaction

* Avoid using the Pebble buttons for actions **not** already associated with
  them, unless clearly marked in the UI using an ``ActionBarLayer`` or similar
  method. When using the Up and Down buttons for 'previous item' and 'next item'
  respectively, there may be no need for a visual cue.

* Use iconography with **pre-existing visual associations** (such as a 'stop'
  icon) to take advantage of the inherent behavior the user will have when
  seeing it. This can avoid the need for explicit instructions to train the user
  for an app's special case.

* Ensure the navigation between app ``Window``s is **logical** with the input
  given and the information displayed. For example, an app showing bus
  timetables should use higher level screens for quickly navigating to a
  particular area/station, with lower level views reserved for scrolling through
  the actual timetable data.

* If possible, **preserve the state of the app** and/or previous navigation if
  the app is commonly used for a repetitive task. In the bus timetable example,
  the user may only look up two stations for a to-from work journey. Learn this
  behavior and store it with the [Persistent Storage API](``Storage``) to
  intelligently adapt the UI on subsequent launches to show the relevant
  information. This helps the user avoid navigating through multiple menus every
  time they launch the app.

## Common Design Styles

The following are common design styles that have been successfully used in
system and 3rd party apps, and are recommended for use in the correct manner.

### Display Data Sets Using Cards

![card >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/card.gif)

The 'card' style aims to reduce the number of menu levels needed to access as
much relevant information as possible. Instead of a menu to select a data set
leading to a menu to explore each item in that set, a single ``Window`` is
designed that displays an entire data set. This view then uses the Pebble Up and
Down buttons to scroll through complete data sets in an array of many sets.

An example of this is the
 
example app, which displays all weather data in a single view and pages through
sets of data for separate locations with the Up and Down buttons. This style of
UI design allows access to lots of information without navigating through
several menus to view it.

### List Options with a Menu

{
  "image": "/images/guides/design-and-interaction/list.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

The style is one of the most basic, tried and true styles. Using the
``MenuLayer`` UI component, the user may choose between multiple app functions
by scrolling with the Up and Down buttons, an interaction pattern afforded to
the developer by the core system experience. Using a menu, a user can navigate
straight to the part of the app or specific action they want.

### Execute Actions with an ActionBarLayer

{
  "image": "/images/guides/design-and-interaction/actionbar.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

The ``ActionBarLayer`` allows easy association of app functionality with the
Pebble buttons. By setting icons to each of the three positions, a user can see
which actions they can perform at a glance and execture them with a single
button press. When pressed, the icon is animated to provide immediate visual
feedback.

An example of this is the system Music app, that uses the ``ActionBarLayer`` to
inform the user that the Up and Down buttons skip tracks. In this case, the
Select button is displayed with elipses, indicating further actions are
available. A press of this button changes the set of actions on the Up and Down
buttons, enabling them to modify the playback volume instead.

A collection of icons for common actions is available for use by developers, and
can be found in the  guide.

### Allow Extended Options with an Action Menu

![actionmenu](/images/guides/design-and-interaction/actionmenu.png)

If an app screen demands a larger range of available actions than the
``ActionBarLayer`` will allow, present these as a list that slides into
view with a press of the Select button using an action menu. This menu contains
all the available options, and can contain multiple sub-menus, providing levels.
The user can keep track of which level they are currently looking at using the
breadcrumb dots on the left-hand side of the screen when the action menu is
displayed.

Once an action has been chosen, the user should be informed of the success or
failure of their choice using a new alert dialog window. In the system action
menus, these screens use an eye-catching animation and bold label to convey the
result of the action. This feedback is important to prevent the user from
getting frustrated if they perceive their input has no result, as well as to
reassure them that their action has succeeded without a problem.

### Get User Input with a Form

![list](/images/guides/design-and-interaction/alarm-list-config.png)

Apps such as the system Alarm app make use of a list of configurable items, with
each active alarm treated as a menu item with properties. The status of each
item is displayed in a menu, with the Select button initiating configuration of
that item.

When an item is being configured, the data requried to create the item should be
obtained from the user through the use of a form, with manipulable elements. In
the Alarms example, each integer required to schedule an alarm is obtained with
a number field that can have its value incrememted or decremented using the
intuitive Up and Down buttons. The current form element is highlighted with
color, and advancing to the next element is done with the Select button,
doubling as a 'Confirm' action when the end of the form is reached.

### Prompting User Action on the Phone

In some applications, user input is required in the app's configuration page (as
detailed in ) before the app
can perform its task. An example of this is a feed reader app, that will need
the user to input the URL of their preferred news feed before it can fetch the
feed content. In this case, the watchapp should display a prominent (full-
screen if possible) dialog telling the user that input to the phone app for
configuration is required.

![action-required >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/action-required.png)

Once the user has performed the required action on the phone, the
[`webviewclosed`](/guides/communication/using-pebblekit-js/)
event should signify that the app can proceed, and that the required data is now
available.

It should not be the case that this action is required every time the app is
started. In most cases, the input data from the user can be stored with
[Peristent Storage](``Storage``) on the watch, or
[`localStorage`](/guides/communication/using-pebblekit-js/)
on the phone. If the app must get input on every launch (such as a mode
selection), this should be done through a form or menu on the watch, so as to
avoid needing to use the phone.

### Show Time and Other Data with the Status Bar

{
  "image": "/images/guides/design-and-interaction/alarm-list.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

Under SDK 2.x, the status bar was displayed to users in all menus and watchapps
except watchfaces, or where the developer had explicitly disabled it. This was
useful for showing the time and battery level, but arguably not essential all
the time.

In SDK 3.x, only apps that are designed to be running for extended periods of
time (such as Music and the Sports API app) show the time, using the
``StatusBarLayer`` UI component. The battery level can easily be seen from the
Settings appface, and so it not necessary to be always visible. Another instance
where the status bar is neccessary is in the Alarms app (shown above), where the
user may need to compare with the current time when setting an alarm.

If a constant, minimalistic display of app data is required, the
``StatusBarLayer`` can be used to perform this task. It provides a choice of
separator mode and foreground/background colors, and can also be made
transparent. Since is it just another ``Layer``, it can be easily extended with
additional text, icons, or other data.

For example, the
[`cards-example`](/cards-example) app uses an
extention of the status bar to display the currently selected 'card' (a set of
displayed data). Another example is the progress bar component example from the
[`ui-patterns`](/ui-patterns) app, which
builds upon the dotted separator mode to become a thin progress bar.

When used in conjunction with the ``ActionBarLayer`` (for example, in the Music
system app), the width of the underlying layer should be adjusted such that the
time displayed is shown in the new center of the app area (excluding that taken
up by the action bar itself).

### Show Alerts and Get Decisions with Modal Windows

![dialog-message >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/dialog-message.gif)

When a significant event occurs while using an app, it should be made visible to
the user through the use of a full-screen model dialog. In a similar way that
notifications and reminders alert the user to events, these layouts consist of
only the important information and an associated icon telling the user the
source of the alert, or the reason for its occurrence. This pattern should also
be used to quickly and efficently tell the user that an app-related error has
occured, including steps on how to fix any potential problems.

These alerts can also take the form of requests for important decisions to be
made by the user, such as to remember a choice as the default preference:

{
  "image": "/images/guides/design-and-interaction/dialog-choice-window.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

In this way the decision can be passed to the user with an immediately obvious
and actionable set of choices. One the choice has been made, the modal window is
dismissed, and a confirmation of the choice displayed. The user should then be
returned to the previous window to resume their use of the app where they left
off.

### Using Vibrations and Haptic Feedback

The Pebble SDK allows the use of the vibration motor to deliver haptic feedback
to the user. This can take the form of short, long, double pulses or more
detailed vibration sequences, allowing a lot of customization as well as
variation between apps.

To encourage a consistent experience for users, the ``Vibes`` API should be used
with the following points in mind:

* A short pulse should be used to alert the user to the end of a long-running
  in-app event, such as a download completing, preferably when they are not
  looking at the watch.

* A long pulse should be used to alert the user to a failure or error that
  requires attention and some interaction.

* Custom vibration patterns should be used to allow the user to customize haptic
  feedback for different events inside the app.

When the app is open and being actively interacted with no vibration or haptic
feedback should be neccessary on top of the existing visual feedback. However,
some exceptions may occur, such as for visually-impaired users. In these cases
haptic feedback may be very useful in boosting app accessibility.

### Handling Connection Problems

When a watchapp is running, there is no guarantee that the phone connection will
be available at any one time. Most apps will function without this connection,
but if PebbleKit JS, Android, or iOS is required, the user must be informed of
the reason for failure so that they can correct the problem. This check can be
performed at any time using ``connection_service_peek_pebble_app_connection()``.

An example alert layout is shown below.

{
  "image": "/images/guides/design-and-interaction/no-bt-connection.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

A similar situation arises if an app that requires information or responses from
a remote web service attempts to do so, but the phone has no Internet
connection. This may be because the user has opted to disable their data
connections, or they may be out of range.

Another example alert layout is shown below for this situation.

{
  "image": "/images/guides/design-and-interaction/no-inet-connection.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

If these kinds of situations can cause problems for the operation of the app,
consider using the [`Persistent Storage`](``Storage``) API to cache the most
recently loaded data (such as weather, sports scores or news items) from the
last successful launch, and display this to the user (while making them aware of
the data's age) until new data can be obtained.

### Hiding Timeline-only Apps

Watchapps that consist only of a  
experience will only need to be launched when configured by the user to select
topic subscriptions. In these cases, developers should hide their app from the
launcher menu to prevent the user needlessly launching it.

To find out how to do this using the `hiddenApp` property, see 
.

## Consistent App Configuration

Watchapps and watchfaces that include user configuration normally include a web
page hosted by the app developer, allowing the user to choose from a set of
options and apply them to the app. Such options include aesthetic options such
as color schemes, larger font sizes, replacement images, data source choices,
and others. Traditionally the design of these pages has been left entirely to
the developer on a per-app basis, and this is reflected in the resulting design
consistency.

Read  to learn more about
configuration page design and implementation.

## What's Next?

Read  to read tips and
guidance on designing apps that work well on a round display.

## Design and Interaction

Interaction guides are intended to help developers design their
apps to maximize user experience through effective, consistent visual design and 
user interactions on the Pebble platform. Readers can be non-programmers and
programmers alike: All material is explained conceptually and no code must be 
understood. For code examples, see 
.

By designing apps using a commonly understood and easy to understand visual
language users can get the best experience with the minimum amount of effort
expended - learning how they work, how to operate them or what other behavior
is required. This can help boost how efficiently any given app is used as well
as help reinforce the underlying patterns for similar apps. For example, the
layout design should make it immediately obvious which part of the UI contains
the vital information the user should glance at first.

In addition to consistent visual design, implementing a common interaction
pattern helps an app respond to users as they would expect. This allows them to
correctly predict how an app will respond to their input without having to
experiment to find out.

To get a feel for how to approach good UI design for smaller devices, read other
examples of developer design guidelines such as Google's
[Material Design](http://www.google.com/design/spec/material-design/introduction.html)
page or Apple's 
[iOS Human Interface Guidelines](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/).

## Contents

