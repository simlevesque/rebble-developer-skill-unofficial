<!-- Generated from pebble-dev/developer.rebble.io (Apache 2.0) with modifications -->

# Pebble Timeline

> How to use Pebble timeline to bring timely information to app users outside the app itself via web services.

## Creating Pins

A timeline pin contains all the information required to be displayed on the
watch, and is written in the JSON object format. It can contain basic
information such as title and times, or more advanced data such as
notifications, reminders, or actions that can be used out from the pin view.

## Pin Overview

The table below details the pin object fields and their function within the
object. Those marked in **bold** are required.

| Field | Type | Function |
|-------|------|----------|
| **`id`** | String (max. 64 chars) | Developer-implemented identifier for this pin event, which cannot be re-used. This means that any pin that was previously deleted cannot then be re-created with the same `id`. |
| **`time`** | String ([ISO date-time](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString)) | The start time of the event the pin represents, such as the beginning of a meeting. See  for information on the acceptable time range. |
| `duration` | Integer number | The duration of the event the pin represents, in minutes. |
| `createNotification` | [Notification object](#notification-object) | The notification shown when the event is first created. |
| `updateNotification` | [Notification object](#notification-object) | The notification shown when the event is updated but already exists. |
| **`layout`** | [Layout object](#layout-object) | Description of the values to populate the layout when the user views the pin. |
| `reminders` | [Reminder object](#reminder-object) array (Max. 3) | Collection of event reminders to display before an event starts. |
| `actions` | [Action object](#action-object) array | Collection of event actions that can be executed by the user. |

### Notification Object

The notification objects used for `createNotification` and `updateNotification`
contain only one common field: a Layout object describing the visual properties
of the notification.

The other field (`time`) is used only in an `updateNotification` object. The
`createNotification` type does **not** require a `time` attribute.

| Field | Type | Function |
|-------|------|----------|
| `layout` | [Layout object](#layout-object) | The layout that will be used to display this notification. |
| `time` | String (ISO date-time) | The new time of the pin update. |

The `createNotification` is shown when the pin is first delivered to the watch.

The `updateNotification` is shown when the pin already existed and is being
updated on the watch. It will only be shown if the `updateNotification.time` is
newer than the last `updateNotification.time` received by the watch.

Using these fields, developers can build a great experience for their users when
live updating pins. For example, when sending updates about a sports game the
app could use the `createNotification` to tell the user that "The game has just
been added to your timeline" and the `updateNotification` to tell them that "The
game starting time has just been updated in your timeline.".

### Layout Object

The Layout object is used to describe any message shown in a customizable
layout. This includes a pin in the timeline, a notification, and also reminders.
Developers can choose between different layout types and customize them with
attributes.

Required fields are shown in **bold**. Some layout types have additional
required fields not shown below, but listed in their dedicated sections. Values
for icon URIs can be found below under [Pin Icons](#pin-icons), although not all
icons are available at all sizes.

| Field | Type | Function |
|-------|------|----------|
| **`type`** | String | The type of layout the pin will use. See [*Pin Layouts*](#pin-layouts) for a list of available types. |
| `title` | String | The title of the pin when viewed. |
| `subtitle` | String | Shorter subtitle for details. |
| `body` | String | The body text of the pin. Maximum of 512 characters. |
| `tinyIcon` | String | URI of the pin's tiny icon. |
| `smallIcon` | String | URI of the pin's small icon. |
| `largeIcon` | String | URI of the pin's large icon. |

The following attributes are also available for all pin layout types
**(excluding notifications and reminders)**.

| Field | Type | Function |
|-------|------|----------|
| `primaryColor` | String | Six-digit color hexadecimal string or case-insensitive SDK constant (e.g.: "665566" or "mintgreen"), describing the primary text color. |
| `secondaryColor` | String | Similar to `primaryColor`, except applies to the layout's secondary-colored elements. |
| `backgroundColor` | String | Similar to `primaryColor`, except applies to the layout's background color. |
| `headings` | Array of Strings | List of section headings in this layout. The list must be less than 128 characters in length, including the underlying delimiters (one byte) between each item. Longer items will be truncated with an ellipsis ('...'). |
| `paragraphs` | Array of Strings | List of paragraphs in this layout. **Must equal the number of `headings`**. The list must be less than 1024 characters in length, including the underlying delimiters (one byte) between each item. Longer items will be truncated with an ellipsis ('...'). |
| `lastUpdated` | ISO date-time | Timestamp of when the pin’s data (e.g: weather forecast or sports score) was last updated. |

### Reminder Object

Reminders are synchronized to the watch and will be shown at the precise time
set in the reminder. They work even when Pebble is disconnected from the
user's mobile phone.

| Field | Type | Function |
|-------|------|----------|
| `time` | String (ISO date-time) | The time the reminder is scheduled to be shown. |
| `layout` | [Layout object](#layout-object) | The layout of the reminder. |

### Action Object

| Field | Type | Function |
|-------|------|----------|
| `title` | String | The name of the action that appears on the watch. |
| `type` | String | The type of action this will execute. See [*Pin Actions*](#pin-actions) for a list of available actions. |

## Minimal Pin Example

The example pin object shown below includes only the required fields for a
generic pin.

```json
{
  "id": "example-pin-generic-1",
  "time": "2015-03-19T18:00:00Z",
  "layout": {
    "type": "genericPin",
    "title": "News at 6 o'clock",
    "tinyIcon": "system://images/NOTIFICATION_FLAG"
  }
}
```

## Complete Pin Example

Below is a more advanced example pin object:

```json
{
  "id": "meeting-453923",
  "time": "2015-03-19T15:00:00Z",
  "duration": 60,
  "createNotification": {
    "layout": {
      "type": "genericNotification",
      "title": "New Item",
      "tinyIcon": "system://images/NOTIFICATION_FLAG",
      "body": "A new appointment has been added to your calendar at 4pm."
    }
  },
  "updateNotification": {
    "time": "2015-03-19T16:00:00Z",
    "layout": {
      "type": "genericNotification",
      "tinyIcon": "system://images/NOTIFICATION_FLAG",
      "title": "Reminder",
      "body": "The meeting has been rescheduled to 4pm."
    }
  },
  "layout": {
    "title": "Client Meeting",
    "type": "genericPin",
    "tinyIcon": "system://images/TIMELINE_CALENDAR",
    "body": "Meeting in Kepler at 4:00pm. Topic: discuss pizza toppings for party."
  },
  "reminders": [
    {
      "time": "2015-03-19T14:45:00Z",
      "layout": {
        "type": "genericReminder",
        "tinyIcon": "system://images/TIMELINE_CALENDAR",
        "title": "Meeting in 15 minutes"
      }
    },
    {
      "time": "2015-03-19T14:55:00Z",
      "layout": {
        "type": "genericReminder",
        "tinyIcon": "system://images/TIMELINE_CALENDAR",
        "title": "Meeting in 5 minutes"
      }
    }
  ],
  "actions": [
    {
      "title": "View Schedule",
      "type": "openWatchApp",
      "launchCode": 15
    },
    {
      "title": "Show Directions",
      "type": "openWatchApp",
      "launchCode": 22
    }
  ]
}
```

## View Modes

When viewing pins in the timeline, they can be displayed in two different ways.

| State | Preview | Details |
|-------|---------|---------|
| Selected | ![](/images/guides/timeline/timeline-selected.png) | Three lines of text shown from the title, location and sender. |
| Not selected | ![](/images/guides/timeline/timeline-one-line.png) | Time, short title, and icon are shown. |

## Pin Icons

The tables below detail the available icons provided by the system. Each icon
can be used when pushing a pin in the following manner:

```
"layout": {
  "type": "genericNotification",
  "title": "Example Pin",
  "tinyIcon": "system://images/NOTIFICATION_FLAG"
}
```

> For general use in watchapps, PDC files are available for these icons in 
> .

### Notifications

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/NOTIFICATION_GENERIC.svg =25) | `NOTIFICATION_GENERIC` | Generic notification |
| ![](/images/guides/timeline/NOTIFICATION_REMINDER.svg =25) | `NOTIFICATION_REMINDER` | Reminder notification |
| ![](/images/guides/timeline/NOTIFICATION_FLAG.svg =25) | `NOTIFICATION_FLAG` | Generic notification flag |
| ![](/images/guides/timeline/NOTIFICATION_LIGHTHOUSE.svg =25) | `NOTIFICATION_LIGHTHOUSE` | Generic lighthouse |

### Generic

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/GENERIC_EMAIL.svg =25) | `GENERIC_EMAIL` | Generic email |
| ![](/images/guides/timeline/GENERIC_SMS.svg =25) | `GENERIC_SMS` | Generic SMS icon |
| ![](/images/guides/timeline/GENERIC_WARNING.svg =25) | `GENERIC_WARNING` | Generic warning icon |
| ![](/images/guides/timeline/GENERIC_CONFIRMATION.svg =25) | `GENERIC_CONFIRMATION` | Generic confirmation icon |
| ![](/images/guides/timeline/GENERIC_QUESTION.svg =25) | `GENERIC_QUESTION` | Generic question icon |

### Weather

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/PARTLY_CLOUDY.svg =25) | `PARTLY_CLOUDY` | Partly cloudy weather |
| ![](/images/guides/timeline/CLOUDY_DAY.svg =25) | `CLOUDY_DAY` | Cloudy weather |
| ![](/images/guides/timeline/LIGHT_SNOW.svg =25) | `LIGHT_SNOW` | Light snow weather |
| ![](/images/guides/timeline/LIGHT_RAIN.svg =25) | `LIGHT_RAIN` | Light rain weather |
| ![](/images/guides/timeline/HEAVY_RAIN.svg =25) | `HEAVY_RAIN` | Heavy rain weather icon |
| ![](/images/guides/timeline/HEAVY_SNOW.svg =25) | `HEAVY_SNOW` | Heavy snow weather icon |
| ![](/images/guides/timeline/TIMELINE_WEATHER.svg =25) | `TIMELINE_WEATHER` | Generic weather icon |
| ![](/images/guides/timeline/TIMELINE_SUN.svg =25) | `TIMELINE_SUN` | Sunny weather icon |
| ![](/images/guides/timeline/RAINING_AND_SNOWING.svg =25) | `RAINING_AND_SNOWING` | Raining and snowing weather icon |
| ![](/images/guides/timeline/SUNRISE.svg =25) | `SUNRISE` | Sunrise weather icon |
| ![](/images/guides/timeline/SUNSET.svg =25) | `SUNSET` | Sunset weather icon |

### Timeline

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/TIMELINE_MISSED_CALL.svg =25) | `TIMELINE_MISSED_CALL` | Generic missed call icon |
| ![](/images/guides/timeline/TIMELINE_CALENDAR.svg =25) | `TIMELINE_CALENDAR` | Generic calendar event icon |
| ![](/images/guides/timeline/TIMELINE_SPORTS.svg =25) | `TIMELINE_SPORTS` | Generic sports icon |

### Sports

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/TIMELINE_BASEBALL.svg =25) | `TIMELINE_BASEBALL` | Baseball sports icon |
| ![](/images/guides/timeline/AMERICAN_FOOTBALL.svg =25) | `AMERICAN_FOOTBALL` | American football sports icon |
| ![](/images/guides/timeline/BASKETBALL.svg =25) | `BASKETBALL` | Basketball sports icon |
| ![](/images/guides/timeline/CRICKET_GAME.svg =25) | `CRICKET_GAME` | Cricket sports icon |
| ![](/images/guides/timeline/SOCCER_GAME.svg =25) | `SOCCER_GAME` | Soccer sports icon |
| ![](/images/guides/timeline/HOCKEY_GAME.svg =25) | `HOCKEY_GAME` | Hockey sports icon |

### Action Results

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/RESULT_DISMISSED.svg =25) | `RESULT_DISMISSED` | Dismissed event |
| ![](/images/guides/timeline/RESULT_DELETED.svg =25) | `RESULT_DELETED` | Deleted event |
| ![](/images/guides/timeline/RESULT_MUTE.svg =25) | `RESULT_MUTE` | Mute event |
| ![](/images/guides/timeline/RESULT_SENT.svg =25) | `RESULT_SENT` | Generic message sent event |
| ![](/images/guides/timeline/RESULT_FAILED.svg =25) | `RESULT_FAILED` | Generic failure event |

### Events

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/STOCKS_EVENT.svg =25) | `STOCKS_EVENT` | Stocks icon |
| ![](/images/guides/timeline/MUSIC_EVENT.svg =25) | `MUSIC_EVENT` | Music event |
| ![](/images/guides/timeline/BIRTHDAY_EVENT.svg =25) | `BIRTHDAY_EVENT` | Birthday event |
| ![](/images/guides/timeline/NEWS_EVENT.svg =25) | `NEWS_EVENT` | Generic news story event |
| ![](/images/guides/timeline/SCHEDULED_EVENT.svg =25) | `SCHEDULED_EVENT` | Generic scheduled event |
| ![](/images/guides/timeline/MOVIE_EVENT.svg =25) | `MOVIE_EVENT` | Generic movie icon |
| ![](/images/guides/timeline/NO_EVENTS.svg =25) | `NO_EVENTS` | No events icon |

### Miscellaneous

| Preview | Name | Description |
|---------|------|-------------|
| ![](/images/guides/timeline/PAY_BILL.svg =25) | `PAY_BILL` | Pay bill event |
| ![](/images/guides/timeline/HOTEL_RESERVATION.svg =25) | `HOTEL_RESERVATION` | Hotel event |
| ![](/images/guides/timeline/TIDE_IS_HIGH.svg =25) | `TIDE_IS_HIGH` | High tide event |
| ![](/images/guides/timeline/INCOMING_PHONE_CALL.svg =25) | `INCOMING_PHONE_CALL` | Incoming phone call event |
| ![](/images/guides/timeline/DURING_PHONE_CALL.svg =25) | `DURING_PHONE_CALL` | Phone call event |
| ![](/images/guides/timeline/DURING_PHONE_CALL_CENTERED.svg =25) | `DURING_PHONE_CALL_CENTERED` | Phone call event centered |
| ![](/images/guides/timeline/DISMISSED_PHONE_CALL.svg =25) | `DISMISSED_PHONE_CALL` | Phone call dismissed event |
| ![](/images/guides/timeline/CHECK_INTERNET_CONNECTION.svg =25) | `CHECK_INTERNET_CONNECTION` | Check Internet connection event |
| ![](/images/guides/timeline/GLUCOSE_MONITOR.svg =25) | `GLUCOSE_MONITOR` | Sensor monitor event |
| ![](/images/guides/timeline/ALARM_CLOCK.svg =25) | `ALARM_CLOCK` | Alarm clock event |
| ![](/images/guides/timeline/CAR_RENTAL.svg =25) | `CAR_RENTAL` | Generic car rental event |
| ![](/images/guides/timeline/DINNER_RESERVATION.svg =25) | `DINNER_RESERVATION` | Dinner reservation event |
| ![](/images/guides/timeline/RADIO_SHOW.svg =25) | `RADIO_SHOW` | Radio show event |
| ![](/images/guides/timeline/AUDIO_CASSETTE.svg =25) | `AUDIO_CASSETTE` | Audio cassette icon |
| ![](/images/guides/timeline/SCHEDULED_FLIGHT.svg =25) | `SCHEDULED_FLIGHT` | Scheduled flight event |
| ![](/images/guides/timeline/REACHED_FITNESS_GOAL.svg =25) | `REACHED_FITNESS_GOAL` | Reached fitness goal event |
| ![](/images/guides/timeline/DAY_SEPARATOR.svg =25) | `DAY_SEPARATOR` | Day separator icon |
| ![](/images/guides/timeline/WATCH_DISCONNECTED.svg =25) | `WATCH_DISCONNECTED` | Watch disconnected event |
| ![](/images/guides/timeline/TV_SHOW.svg =25) | `TV_SHOW` | Generic TV show icon |
| ![](/images/guides/timeline/LOCATION.svg =25) | `LOCATION` | Generic location icon |
| ![](/images/guides/timeline/SETTINGS.svg =25) | `SETTINGS` | Generic settings icon |

### Custom Icons

Custom icons were introduced in SDK 4.0. They allow you to use custom images for
timeline pins, by utilizing the

`name`. E.g. `app://images/*name*`

## Pin Layouts

Developers can customize how pins, reminders and notifications are shown to the
user using different layouts. The Pebble SDK includes layouts appropriate for a
broad set of apps. Each layout has different customization options, called the
layout attributes. Most layouts also offer the option of showing an icon, which
must be one of the standard system provided icons, listed under
[*Pin Icons*](#pin-icons) above.

The sub-sections below detail the available layouts and the fields they will
display. Required attributes are shown in **bold**.

### Generic Layout

Generic layout for generic pins of no particular type.

**Timeline view**

{
  "image": "/images/guides/timeline/generic-pin.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Detail view**

{
  "image": "/images/guides/timeline/generic-layout.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Standard Attributes**

**`title`**, **`tinyIcon`**, `subtitle`, `body`.

**Color Elements**

| Layout Property | Applies To |
|-----------------|------------|
| `primaryColor` | Time, body |
| `secondaryColor` | Title |
| `backgroundColor` | Background |

**Example JSON**

```json
{
  "id": "pin-generic-1",
  "time": "2015-09-22T16:30:00Z",
  "layout": {
    "type": "genericPin",
    "title": "This is a genericPin!",
    "tinyIcon": "system://images/NOTIFICATION_FLAG",
    "primaryColor": "#FFFFFF",
    "secondaryColor": "#666666",
    "backgroundColor": "#5556FF"
  }
}
```

### Calendar Layout

Standard layout for pins displaying calendar events.

**Timeline view**

{
  "image": "/images/guides/timeline/calendar-pin.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Detail view**

{
  "image": "/images/guides/timeline/calendar-layout.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Standard Attributes**

**`title`**, `body`.

**Special Attributes**

| Field | Type | Function |
|-------|------|----------|
| `locationName` | String | Name of the location of this pin event. Used if `shortSubtitle` is not present on the list view, and always in the detail view. |

**Color Elements**

| Layout Property | Applies To |
|-----------------|------------|
| `primaryColor` | Times, body |
| `secondaryColor` | Title |
| `backgroundColor` | Background |

**Example JSON**

```json
{
  "id": "pin-calendar-1",
  "time": "2015-03-18T15:45:00Z",
  "duration": 60,
  "layout": {
    "type": "calendarPin",
    "title": "Pin Layout Meeting",
    "locationName": "Conf Room 1",
    "body": "Discuss layout types with Design Team."
  }
}
```

### Sports Layout

Generic layout for displaying sports game pins including team ranks, scores
and records.

**Timeline view**

{
  "image": "/images/guides/timeline/sport-pin.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Detail view**

{
  "image": "/images/guides/timeline/sport-layout.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Standard Attributes**

**`title`** (name of the game), `subtitle` (friendly name of the period), `body`
(game description), **`tinyIcon`**, `largeIcon`, `lastUpdated`.

**Special Attributes**

> Note: The `rankAway` and `rankHome` fields will be shown before the event
> begins, otherwise `scoreAway` and `scoreHome` will be shown.

| Field | Type | Function |
|-------|------|----------|
| `rankAway` | String (~2 characters) | The rank of the away team. |
| `rankHome` | String (~2 characters) | The rank of the home team. |
| `nameAway` | String (Max 4 characters) | Short name of the away team. |
| `nameHome` | String (Max 4 characters) | Short name of the home team. |
| `recordAway` | String (~5 characters) | Record of the away team (wins-losses). |
| `recordHome` | String (~5 characters) | Record of the home team (wins-losses). |
| `scoreAway` | String (~2  characters) | Score of the away team. |
| `scoreHome` | String (~2 characters) | Score of the home team. |
| `sportsGameState` | String | `in-game` for in game or post game, `pre-game` for pre game. |

**Color Elements**

| Layout Property | Applies To |
|-----------------|------------|
| `primaryColor` | Text body |
| `secondaryColor` | Team names and scores |
| `backgroundColor` | Background |

**Example JSON**

```json
{
  "id": "pin-sports-1",
  "time": "2015-03-18T19:00:00Z",
  "layout": {
    "type": "sportsPin",
    "title": "Bulls at Bears",
    "subtitle": "Halftime",
    "body": "Game of the Century",
    "tinyIcon": "system://images/AMERICAN_FOOTBALL",
    "largeIcon": "system://images/AMERICAN_FOOTBALL",
    "lastUpdated": "2015-03-18T18:45:00Z",
    "rankAway": "03",
    "rankHome": "08",
    "nameAway": "POR",
    "nameHome": "LAC",
    "recordAway": "39-19",
    "recordHome": "39-21",
    "scoreAway": "54",
    "scoreHome": "49",
    "sportsGameState": "in-game"
  }
}
```

### Weather Layout

Standard layout for pins displaying the weather.

**Timeline view**

{
  "image": "/images/guides/timeline/weather-pin.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Detail view**

{
  "image": "/images/guides/timeline/weather-layout.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Standard Attributes**

**`title`** (part of the day), **`tinyIcon`**, `largeIcon`, `body`
(shortcast), `lastUpdated`.

**Special Attributes**

| Field | Type | Function |
|-------|------|----------|
| `shortTitle` | String | Used instead of `title` in the main timeline view unless it is not specified. |
| `subtitle` | String | Show high/low temperatures. Note: currently only numbers and the degree symbol (°) are supported. |
| `shortSubtitle` | String | Used instead of `subtitle` in the main timeline view unless it is not specified. |
| **`locationName`** | String | Name of the location of this pin event. |
| `displayTime` | String | Use a value of 'pin' to display the pin's time in title of the detail view and description, or 'none' to not show the time. Defaults to 'pin' if not specified. |

**Color Elements**

| Layout Property | Applies To |
|-----------------|------------|
| `primaryColor` | All text |
| `backgroundColor` | Background |

**Example JSON**

```json
{
  "id": "pin-weather-1",
  "time": "2015-03-18T19:00:00Z",
  "layout": {
    "type": "weatherPin",
    "title": "Nice day",
    "subtitle": "40/65",
    "tinyIcon": "system://images/TIMELINE_SUN",
    "largeIcon": "system://images/TIMELINE_SUN",
    "locationName": "Palo Alto",
    "body": "Sunny with a chance of rain.",
    "lastUpdated": "2015-03-18T18:00:00Z"
  }
}
```

### Generic Reminder

Generic layout for pin reminders, which can be set at various times before an
event is due to occur to remind the user ahead of time.

{
  "image": "/images/guides/timeline/generic-reminder.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Standard Attributes**

**`title`**, **`tinyIcon`**.

**Special Attributes**

| Field | Type | Function |
|-------|------|----------|
| `locationName` | String | Name of the location of this pin event. |

**Example JSON**

```json
{
  "id": "pin-generic-reminder-1",
  "time": "2015-03-18T23:00:00Z",
  "layout": {
    "type": "genericPin",
    "title": "This is a genericPin!",
    "subtitle": "With a reminder!.",
    "tinyIcon": "system://images/NOTIFICATION_FLAG"
  },
  "reminders": [
    {
      "time": "2015-03-18T22:55:00Z",
      "layout": {
        "type": "genericReminder",
        "title": "Reminder!",
        "locationName": "Conf Rm 1",
        "tinyIcon": "system://images/ALARM_CLOCK"
      }
    }
  ]
}
```

### Generic Notification

Generic notification layout which can be used with `createNotification` and
`updateNotification` to alert the user to a new pin being created on their
timeline.

{
  "image": "/images/guides/timeline/generic-notification-layout.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

**Standard Attributes**

**`title`**, **`tinyIcon`**, `body`.

**Color Elements**

| Layout Property | Applies To |
|-----------------|------------|
| `primaryColor` | Title |
| `backgroundColor` | Banner background |

**Example JSON**

```json
{
  "id": "pin-generic-createmessage-1",
  "time": "2015-04-30T23:45:00Z",
  "layout": {
    "type": "genericPin",
    "title": "This is a genericPin!",
    "subtitle": "With a notification",
    "tinyIcon": "system://images/NOTIFICATION_FLAG"
  },
  "createNotification": {
    "layout": {
      "type": "genericNotification",
      "title": "Notification!",
      "tinyIcon": "system://images/NOTIFICATION_FLAG",
      "body": "A new genericPin has appeared!"
    }
  }
}

```

## Pin Actions

Pins can be further customized by adding actions to them. This allows bi-
directional interactivity for pin-based apps. These apps can have multiple
actions associated with them, allowing different launch behavior depending on
how the user interacts with the pin.

The table below shows the available actions that can be added to a pin. Required
attributes are shown in **bold**.

| Action `type` | Description | Attributes |
|---------------|-------------|------------|
| `openWatchApp` | Launch the watchapp associated with this pin. The `launchCode` field of this action object will be passed to the watchapp and can be obtained with ``launch_get_args()``. | **`title`**, **`launchCode`**. |
| `http` | Execute an HTTP request that invokes this action on the remote service. | See [*HTTP Actions*](#http-actions) for full attribute details. |

### Using a Launch Code

Launch codes can be used to pass a single integer value from a specific timeline
pin to the app associated with it when it is lauched from that pin. This
mechanism allows the context to be given to the app to allow it to change
behavior based on the action chosen.

For example, a pin could have two actions associated with an app for making
restaurant table reservations that allowed the user to cancel the reservation or
review the restaurant. To set up these actions, add them to the pin when it is
pushed to the timeline API.

```
"actions": [
  {
    "title": "Cancel Table",
    "type": "openWatchApp",
    "launchCode": 15
  },
  {
    "title": "Leave Rating",
    "type": "openWatchApp",
    "launchCode": 22
  }
]
```

### Reading the Launch Code

When the user sees the pin and opens the action menu, they can select one of
these actions which will launch the watchapp (as dictated by the `openWatchApp`
pin action `type`). When the app launches, use ``launch_get_args()`` to read the
value of the `launchCode` associated with the chosen action, and react
accordingly. An example is shown below;

```c
if(launch_reason() == APP_LAUNCH_TIMELINE_ACTION) {
  uint32_t arg = launch_get_args();

  switch(arg) {
  case LAUNCH_ARG_CANCEL:
    // Cancel table UI...

    break;
  case LAUNCH_ARG_REVIEW:
    // Leave a review UI...

    break;
  }
}
```

### HTTP Actions

With the `http` pin action `type`, pins can include actions that carry out an
arbitrary HTTP request. This makes it possible for a web service to be used
purely by pushed pins with actions that respond to those events.

The table below details the attributes of this type of pin action object. Items
shown in **bold** are required.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| **`title`** | String | *mandatory* | The title of the action. |
| **`url`** | String | *mandatory* | The URL of the remote service to send the request to. |
| `method` | String | `POST` | The request method, such as `GET`, `POST`, `PUT` or `DELETE`. |
| `headers` | Object | `{}` | Dictionary of key-value pairs of headers (`Content-Type` is implied by using `bodyJSON`) as required by the remote service. |
| `bodyText` | String | `''` | The data body of the request in String format. |
| `bodyJSON` | Object | *unspecified* | The data body of the request in JSON object format. |
| `successText` | String | "Done!" | The string to display if the action is successful. |
| `successIcon` | Pin Icon URL | `system://images/GENERIC_CONFIRMATION` | The icon to display if the action is successful. |
| `failureText` | String | "Failed!" | The string to display if the action is unsuccessful. |
| `failureIcon` | Pin Icon URL | `system://images/RESULT_FAILED` | The icon to display if the action is unsuccessful. |

> Note: `bodyText` and `bodyJSON` are mutually exclusive fields (they cannot be
> used together in the same request). You should choose that which is most
> convenient for your implementation.

> Note: Do not include a body with HTTP methods that do not support one. This
> means that `bodyText` and `bodyJSON` cannot be used with `GET` or `DELETE`
> requests.

The following is an example action, using the `http` action `type` to confirm
attendance at a meeting managed by a fictitious meeting scheduling service.

```js
"actions": [
  {
    "type": "http",
    "title": "Confirm Meeting",
    "url": "http://some-meeting-service.com/api/v1/meetings/46146717",
    "method": "PUT",
    "headers": {
      "X-Request-Source": "pebble-timeline",
      "Content-Type": "application/x-www-form-urlencoded"
    },
    "bodyText": "type=confirm&value=1",
    "successIcon": "system://images/GENERIC_CONFIRMATION",
    "successText": "Confirmed!"
  }
]
```

Alternatively, pins can use the `bodyJSON` field to encode a JSON object.
Include this data using the `bodyJSON` field.

```js
"actions": [
  {
    "type": "http",
    "title": "Confirm Meeting",
    "url": "http://some-meeting-service.com/api/v1/meetings/46146717",
    "method": "PUT",
    "headers": {
      "X-Request-Source": "pebble-timeline"
    },
    "bodyJSON": {
      "type": "confirm",
      "value": true
    },
    "successIcon": "system://images/GENERIC_CONFIRMATION",
    "successText": "Confirmed!"
  }
]
```

### Included Headers

When using the `http` action, the request will also include the following
additional headers. Developers can use these to personalize the timeline
experience to each individual user.

| Header Key | Value |
|------------|-------|
| `X-Pebble-Account-Token` | Same as [`Pebble.getAccountToken()`](/guides/communication/using-pebblekit-js) |
| `X-Pebble-Watch-Token` | Same as [`Pebble.getWatchToken()`](/guides/communication/using-pebblekit-js) |

## Testing Pins

It is also possible to push new timeline pins using the `pebble`
. Prepare your pin in a JSON
file, such as `example-pin.json` shown below:

```json
{
  "id": "pin-generic-1",
  "time": "2015-03-18T15:45:00Z",
  "layout": {
    "type": "genericPin",
    "title": "This is a genericPin!",
    "tinyIcon": "system://images/NOTIFICATION_FLAG"
  }
}
```

Push this pin to your emulator to preview how it will appear for users.

```nc|bash
$ pebble insert-pin example-pin.json
```

The pin will appear as shown below:

![pin-preview >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/timeline/generic-pin~basalt.png)

It is possible to delete the pin in a similar manner, making sure the `id` is
the same as the pin to be removed:

```nc|bash
$ pebble delete-pin --id pin-generic-1
```

## Service Architecture

Every item on the timeline is called a 'pin'. A pin can have information
attached to it which is used to show it to the user, such as layout, title,
start time and actions. When the user is viewing their timeline, they can use
the information provided about the immediate past and future to make decisions
about how they plan the rest of their day and how to respond to any missed
notifications or events.

While the system and mobile application populate the user's timeline
automatically with items such as calendar appointments and weather details, the
real value of the timeline is realized by third party apps. For example, a
sports app could show a pin representing an upcoming match and the user could
tell how much time remained until they needed to be home to watch it.

Developers can use a watchapp to subscribe their users to one of two types pin:

* Personal pins pushed to a user's timeline token. These pins are only delivered
  to the user the token belongs to, allows a high degree of personalization in
  the pin's contents.

* Channels called 'topics' (one more more, depending on their preferences),
  allow an app to push pins to a large number of users at once. Topics are
  created on a per-app basis, meaning a user receiving pins for a 'football'
  topic from one app will not receive pins from another app using the same topic
  name.

Developers can use the PebbleKit JS API to combine the user's preferences with
their location and data from other web-connected sources to make pin updates
more personal, or more intelligently delivered.

The public timeline web API is used to push data from a own backend server to
app users according to the topics they have subscribed to, or to individual
users. Methods for doing this are discussed below under 
[Three Ways to Use Pins](#three-ways-to-use-pins).

## Architecture Overview

![diagram](/images/guides/3.0/timeline-architecture.png)

The timeline architecture consists of multiple components that work together to
bring timely and relevant data, events, and notifications to the user without
their intervention. These components are discussed in more detail below.

### Public Web API

The Pebble timeline web API (detailed in 
) manages the currently
available topics, published pins, and timeline-enabled apps' data. All pins that
are delivered to users pass through this service. When a developer pushes a pin
it is sent to this service for distribution to the applicable users.

### Pebble Mobile App

The Pebble mobile app is responsible for synchronizing the pins visible on the
watch with those that are currently available in the cloud. The PebbleKit JS
APIs allow a developer to use a configuration page (detailed in 
) or onboard menu to give
users the choice of which pins they receive via the topics they are subscribed
to. Developers can also send the user's token to their own server to maintain a
custom list of users, and provide a more personal service.

The Pebble mobile app is also responsible for inserting pins directly into the
user's timeline for their upcoming calendar events and missed calls. These pins
originate on the phone and are sent straight to the watch, not via the public
web API. Alarm pin are also inserted directly from the watch itself.

### Developer's App Server/Service

When a developer wants to push pins, they can do so from their own third-party
server. Such a server will generate pins using topics that the watchapp
subscribes to (either for all users or just those that elect to be subscribed)
or user tokens received from PebbleKit JS to target individual users. See
 for information on
how to do this.

## Three Ways to Use Pins

The timeline API is flexible enough to enable apps to use it to send data to
users in three distinct ways.

### Push to All Users

![all-users](/images/guides/timeline/all-users.png)

The most basic subscription method involves subscribing a user to a topic that
is global to the app. This means all users of the app will receive the pins
pushed to that topic. To do this, a developer can choose a single topic name
such as 'all-users' and subscribe all users to that topic when the app is first
installed, or the user opts in to receive pins.

Read  
to find out how to create topics.

### Let Users Choose Their Pins

![some-users](/images/guides/timeline/some-users.png)

Developers can also use a configuration page in their app to allow users to
subscribe to different topics, leeting them customize their experience and only
receive pins they want to see. In the image above, the pin broadcast with the
topic 'baseball' is received by users 1 and 3, but not User 2 who has only
subscribed to the 'golf' topic.

### Target Individual Users

![individual](/images/guides/timeline/individual.png)

Lastly, developers can use the timeline token to target individual users. This
adds another dimension to how personal an app can become, allowing apps to be
customized to the user in more ways than just their topic preferences. The image
above shows a pin pushed from an app's pin server to just the user with the
matching `X-User-Token`. For example, an app tracking the delivery of a user's
packages will only be applicable to that user.

See  
to learn how to send a pin to a single user.

## Managing Subscriptions

The following PebbleKit JS APIs allow developers to intereact with the timeline
API, such as adding and removing the user's subscribed topics. By combining
these with user preferences from a configuration page (detailed in 
) it is possible to allow
users to choose which pin sources they receive updates and events from.

> The timeline APIs to subscribe users to topics and retrieve user tokens are
> only available in PebbleKit JS.
>
> If you wish to use the timeline APIs with a Pebble app that uses PebbleKit iOS
> or Android please [contact us](/contact) to discuss your specific use-case.

## Requirements

These APIs require some knowledge of your app before they can work. For example,
in order to return the user's timeline token, the web API must know your app's
UUID. This also ensures that only users who have your app installed will receive
the correct pins.

If you have not performed this process for your app and attempt to use these
APIs, you will receive an error similar to the following message:

```text
[INFO    ] No token available for this app and user.
```

### Shared Pins

For best compatibility with applications, when using shared pins, it is
recommended to define the following in your PebbleKit JS code:

```js
var getTimelineSubscribeToTopicURL = function(topic) {
    var encodedTopic = encodeURIComponent(topic);
    return "https://timeline-api.rebble.io/v1/user/subscriptions/" + encodedTopic;
};

var getTimelineSubscriptionsListURL = function() {
    return "https://timeline-api.rebble.io/v1/user/subscriptions";
};
```

## Get a Timeline Token

The timeline token is unique for each user/app combination. This can be used by
an app's third party backend server to selectively send pins only to those users
who require them, or even to target users individually for complete
personalization.

```js
Pebble.getTimelineToken(function(token) {
  console.log('My timeline token is ' + token);
}, function(error) {
  console.log('Error getting timeline token: ' + error);
});
```

## Subscribe to a Topic

A user can also subscribe to a specific topic in each app. Every user that
subscribes to this topic will receive the pins pushed to it. This can be used to
let the user choose which features of your app they wish to subscribe to. For
example, they may want 'world news' stories but not 'technology' stories. In
this case they would be subscribed only to the topic that includes pins with
'world news' information.

```js
Pebble.timelineSubscribe('world-news', function() {
  console.log('Subscribed to world-news');
}, function(err) {
  console.log('Error subscribing to topic: ' + err);
});
```

## Unsubscribe from a Topic

The user may unsubscribe from a topic they previously subscribed to. They will
no longer receive pins from this topic.

```js
Pebble.timelineUnsubscribe('world-news', function() {
  console.log('Unsubscribed from world-news');
}, function(err) {
  console.log('Error unsubscribing from topic: ' + err);
});
```

## List Current Subscriptions

You can use the function below to list all the topics a user has subscribed to.

```js
Pebble.timelineSubscriptions(function(topics) {
  // List all the subscribed topics
  console.log('Subscribed to ' + topics.join(', '));
}, function(errorString) {
  console.log('Error getting subscriptions: ' + errorString);
});
```

## Libraries for Pushing Pins

This page contains libraries that are currently available to interact with
the timeline. You can use these to build apps and services that push pins to
your users.

## timeline.js

**JavaScript Code Snippet** - [Available on GitHub](https://gist.github.com/pebble-gists/6a4082ef12e625d23455)

**Install**

Copy into the `src/pkjs/` directory of your project, add `enableMultiJS: true` in
`package.json`, then `require` and use in `index.js`.

**Example**

```js
var timeline = require('./timeline');

// Push a pin when the app starts
Pebble.addEventListener('ready', function() {
  // An hour ahead
  var date = new Date();
  date.setHours(date.getHours() + 1);

  // Create the pin
  var pin = {
    "id": "example-pin-0",
    "time": date.toISOString(),
    "layout": {
      "type": "genericPin",
      "title": "Example Pin",
      "tinyIcon": "system://images/SCHEDULED_EVENT"
    }
  };

  console.log('Inserting pin in the future: ' + JSON.stringify(pin));

  // Push the pin
  timeline.insertUserPin(pin, function(responseText) {
    console.log('Result: ' + responseText);
  });
});
```

## pebble-api

**Node Module** - [Available on NPM](https://www.npmjs.com/package/pebble-api)

**Install**

```bash
npm install pebble-api --save
```

**Example**

```js
var Timeline = require('pebble-api');

var USER_TOKEN = 'a70b23d3820e9ee640aeb590fdf03a56';

var timeline = new Timeline();

var pin = new Timeline.Pin({
  id: 'test-pin-5245',
  time: new Date(),
  duration: 10,
  layout: new Timeline.Pin.Layout({
    type: Timeline.Pin.LayoutType.GENERIC_PIN,
    tinyIcon: Timeline.Pin.Icon.PIN,
    title: 'Pin Title'
  })
});

timeline.sendUserPin(USER_TOKEN, pin, function (err) {
  if (err) {
    return console.error(err);
  }

  console.log('Pin sent successfully!');
});
```

## PebbleTimeline API Ruby

**Ruby Gem** - [Available on RubyGems](https://rubygems.org/gems/pebble_timeline/versions/0.0.1)

**Install**

```bash
gem install pebble_timeline
```

**Example**

```ruby
require 'pebble_timeline'

api = PebbleTimeline::API.new(ENV['PEBBLE_TIMELINE_API_KEY'])

# Shared pins
pins = PebbleTimeline::Pins.new(api)
pins.create(id: "test-1", topics: 'test', time: "2015-06-10T08:01:10.229Z", layout: { type: 'genericPin', title: 'test 1' })
pins.delete("test-1")

# User pins
user_pins = PebbleTimeline::Pins.new(api, 'user', USER_TOKEN)
user_pins.create(id: "test-1", time: "2015-06-12T16:42:00Z", layout: { type: 'genericPin', title: 'test 1' })
user_pins.delete("test-1")
```

## pypebbleapi

**Python Library** - [Available on pip](https://pypi.python.org/pypi/pypebbleapi/0.0.1)

**Install**

```bash
pip install pypebbleapi
```

**Example**

```python
from pypebbleapi import Timeline, Pin
import datetime

timeline = Timeline(my_api_key)

my_pin = Pin(id='123', datetime.date.today().isoformat())

timeline.send_shared_pin(['a_topic', 'another_topic'], my_pin)
```

## php-pebble-timeline

**PHPebbleTimeline** - [Available on Github](https://github.com/fletchto99/PHPebbleTimeline)

**Install**

Copy the TimelineAPI folder (from the above repository) to your project's directory and include the required files.

**Example**

<div>

//Include the timeline API
require_once 'TimelineAPI/Timeline.php';

//Import the required classes
use TimelineAPI\Pin;
use TimelineAPI\PinLayout;
use TimelineAPI\PinLayoutType;
use TimelineAPI\PinIcon;
use TimelineAPI\PinReminder;
use TimelineAPI\Timeline;

//Create some layouts which our pin will use
$reminderlayout = new PinLayout(PinLayoutType::GENERIC_REMINDER, 'Sample reminder!', null, null, null, PinIcon::NOTIFICATION_FLAG);
$pinlayout = new PinLayout(PinLayoutType::GENERIC_PIN, 'Our title', null, null, null, PinIcon::NOTIFICATION_FLAG);

//Create a reminder which our pin will push before the event
$reminder = new PinReminder($reminderlayout, (new DateTime('now')) -> add(new DateInterval('PT10M')));

//Create the pin
$pin = new Pin('<YOUR USER TOKEN HERE>', (new DateTime('now')) -> add(new DateInterval('PT5M')), $pinlayout);

//Attach the reminder
$pin -> addReminder($reminder);

//Push the pin to the timeline
Timeline::pushPin('sample-userToken', $pin);

</div>

## PinPusher

**PHP Library** - [Available on Composer](https://packagist.org/packages/valorin/pinpusher)

**Install**

```bash
composer require valorin/pinpusher
```

**Example**

<div>

use Valorin\PinPusher\Pusher;
use Valorin\PinPusher\Pin;

$pin = new Pin(
    'example-pin-generic-1',
    new DateTime('2015-03-19T18:00:00Z'),
    new Pin\Layout\Generic(
        "News at 6 o'clock",
        Pin\Icon::NOTIFICATION_FLAG
    )
);

$pusher = new Pusher()
$pusher->pushToUser($userToken, $pin);

</div>

## pebble-api-dotnet

**PCL C# Library** - [Available on Github](https://github.com/nothingmn/pebble-api-dotnet)

**Install**

```text
git clone git@github.com:nothingmn/pebble-api-dotnet.git
```

**Example**

In your C# project, define your global API Key.

```csharp
public static string APIKey = "APIKEY";
```

Launch your app on the watch, and make the API call...

Now, on the server, you can use your "userToken" from the client app, and send pins as follows:

```csharp
var timeline = new Timeline(APIKey);
var result = await timeline.SendUserPin(userToken, new Pin()
{
    Id = System.Guid.NewGuid().ToString(),
    Layout = new GenericLayout()
    {
        Title = "Generic Layout",
        Type = LayoutTypes.genericPin,
        SmallIcon = Icons.Notification.Flag
    },
});
```

See more examples on the 
[GitHub repo](https://github.com/nothingmn/pebble-api-dotnet).

## Public Web API

While users can register subscriptions and receive data from the timeline using
the PebbleKit JS subscriptions API 
(detailed in ), app developers can
use the public timeline web API to provide that data by pushing pins. Developers
will need to create a simple web server to enable them to process and send the
data they want to display in the timeline. Each pin represents a specific event
in the past or the future, and will be shown on the watch once pushed to the
public timeline web API and automatically synchronized with the watch via the
Pebble mobile applications.

The Pebble SDK emulator supports the timeline and automatically synchronizes
every 30 seconds.

## Pushing Pins

Developers can push data to the timeline using their own backend servers. Pins
are created and updated using HTTPS requests to the Pebble timeline web API.

> Pins pushed to the Pebble timeline web API may take **up to** 30 minutes to
> appear on a user's watch. Although most pins can arrive faster than this, we
> recommend developers do not design apps that rely on near-realtime updating of
> pins.

### Create a Pin

To create a pin, send a `PUT` request to the following URL scheme, where `ID` is
the `id` of the pin object. For example 'reservation-1395203':

```text
PUT https://timeline-api.rebble.io/v1/user/pins/ID
```

Use the following headers, where `X-User-Token` is the user's
timeline token (read 
 
to learn how to get a token):

```text
Content-Type: application/json
X-User-Token: a70b23d3820e9ee640aeb590fdf03a56
```

Include the JSON object as the request body from a file such as `pin.json`. A
sample of an object is shown below:

```json
{
  "id": "reservation-1395203",
  "time": "2014-03-07T08:01:10.229Z",
  "layout": {
    "shortTitle": "Dinner at La Fondue",
    ...
  },
  ...
}
```

#### Curl Example

```bash
$ curl -X PUT https://timeline-api.rebble.io/v1/user/pins/reservation-1395203 \
    --header "Content-Type: application/json" \
    --header "X-User-Token: a70b23d3820e9ee640aeb590fdf03a56" \
    -d @pin.json
OK
```

### Update a Pin

To update a pin, send a `PUT` request with a new JSON object with the **same
`id`**.

```text
PUT https://timeline-api.rebble.io/v1/user/pins/reservation-1395203

```

Remember to include the user token in the headers.

```text
X-User-Token: a70b23d3820e9ee640aeb590fdf03a56
```

When an update to an existing pin is issued, it replaces the original
pin entirely, so all fields (including those that have not changed) should be
included. The example below shows an event updated with a new `time`:

```json
{
    "id": "reservation-1395203",
    "time": "2014-03-07T09:01:10.229Z",
    "layout": {
      "shortTitle": "Dinner at La Fondue",
      ...
    },
    ...
}
```

#### Curl Example

```bash
$ curl -X PUT https://timeline-api.rebble.io/v1/user/pins/reservation-1395203 \
    --header "Content-Type: application/json" \
    --header "X-User-Token: a70b23d3820e9ee640aeb590fdf03a56" \
    -d @pin.json
OK
```

### Delete a Pin

Delete a pin by issuing a HTTP `DELETE` request.

```text
DELETE https://timeline-api.rebble.io/v1/user/pins/reservation-1395203
```

Remember to include the user token in the headers.

```text
X-User-Token: a70b23d3820e9ee640aeb590fdf03a56
```

This pin will then be removed from that timeline on the user's watch.
In some cases it may be preferred to simply update a pin with a cancelled
event's details so that it can remain visible and useful to the user.

#### Curl Example

```bash
$ curl -X DELETE https://timeline-api.rebble.io/v1/user/pins/reservation-1395203 \
    --header "Content-Type: application/json" \
    --header "X-User-Token: a70b23d3820e9ee640aeb590fdf03a56"
OK
```

## Shared Pins

### Create a Shared Pin

It is possible to send a pin (and updates) to multiple users at once by
modifying the `PUT` header to include `X-Pin-Topics` (the topics a user must be
subscribed to in order to receive this pin) and `X-API-Key` (issued by the
[Developer Portal]()). In this case, the URL is
also modified:

```text
PUT /v1/shared/pins/giants-game-1
```

The new headers:

```text
Content-Type: application/json
X-API-Key: fbbd2e4c5a8e1dbef2b00b97bf83bdc9
X-Pin-Topics: giants,redsox,baseball
```

The pin body remains the same:

```json
{
    "id": "giants-game-1",
    "time": "2014-03-07T10:01:10.229Z",
    "layout": {
      "title": "Giants vs Red Sox: 5-3",
      ...
    },
    ...
}
```

#### Curl Example

```bash
$ curl -X PUT https://timeline-api.rebble.io/v1/shared/pins/giants-game-1 \
    --header "Content-Type: application/json" \
    --header "X-API-Key: fbbd2e4c5a8e1dbef2b00b97bf83bdc9" \
    --header "X-Pin-Topics: giants,redsox,baseball" \
    -d @pin.json
OK
```

### Delete a Shared Pin

Similar to deleting a user pin, shared pins can be deleted by issuing a `DELETE`
request:

```text
DELETE /v1/shared/pins/giants-game-1
```

As with creating a shared pin, the API key must also be provided in the request
headers:

```text
X-API-Key: fbbd2e4c5a8e1dbef2b00b97bf83bdc9
```

#### Curl Example

```bash
$ curl -X DELETE https://timeline-api.rebble.io/v1/shared/pins/giants-game-1 \
    --header "Content-Type: application/json" \
    --header "X-API-Key: fbbd2e4c5a8e1dbef2b00b97bf83bdc9" \
OK
```

## Listing Topic Subscriptions

Developers can also query the public web API for a given user's currently
subscribed pin topics with a `GET` request:

```text
GET /v1/user/subscriptions
```

This requires the user's timeline token:

```text
X-User-Token: a70b23d3820e9ee640aeb590fdf03a56
```

#### Curl Example

```bash
$ curl -X GET https://timeline-api.rebble.io/v1/user/subscriptions \
    --header "X-User-Token: a70b23d3820e9ee640aeb590fdf03a56" \
```

The response will be a JSON object containing an array of topics the user is
currently subscribed to for that app:

```json
{
  "topics": [
    "topic1",
    "topic2"
  ]
}
```

## Pin Time Limitations

The `time` property on a pin pushed to the public API must not be more than two
days in the past, or a year in the future. The same condition applies to the
`time` associated with a pin's reminders and notifications.

Any pins that fall outside these conditions may be rejected by the web API. In
addition, the actual range of events shown on the watch may be different under
some conditions.

For shared pins, the date and time of an event will vary depending on the user's
timezone.

## Error Handling

In the event of an error pushing a pin, the public timeline API will return one
of the following responses.

| HTTP Status | Response Body | Description |
|-------------|---------------|-------------|
| 200 | None | Success. |
| 400 | `{ "errorCode": "INVALID_JSON" }` | The pin object submitted was invalid. |
| 403 | `{ "errorCode": "INVALID_API_KEY" }` | The API key submitted was invalid. |
| 410 | `{ "errorCode": "INVALID_USER_TOKEN" }` | The user token has been invalidated, or does not exist. All further updates with this user token will fail. You should not send further updates for this user token. A user token can become invalidated when a user uninstalls an app for example. |
| 429 | `{ "errorCode": "RATE_LIMIT_EXCEEDED" }` | Server is sending updates too quickly, and has been rate limited (see [*Rate Limiting*](#rate-limiting) below). |
| 503 | `{ "errorCode": "SERVICE_UNAVAILABLE" }` | Could not save pin due to a temporary server error. |

## Pebble Timeline

The Pebble timeline is a system-level display of chronological events that apps
can insert data into to deliver user-specific data, events, notifications and
reminders. These items are called pins and are accessible outside the running
app, but are deeply associated with an app the user has installed on their
watch.

Every user can view their personal list of pins from the main watchface by
pressing Up for the past and Down for the future. Examples of events the user
may see include weather information, calendar events, sports scores, news items,
and notifications from any web-based external service.

## Contents

## Enabling a New App

To push pins via the Pebble timeline API, a first version of a new app must be
uploaded to the [Developer Portal](). This is
required so that the appstore can identify the app's UUID, and so generate
sandbox and production API keys for the developer to push pins to. It is then
possible to use the timeline web API in sandbox mode for development or in
production mode for published apps.

1. In the Developer Portal, go to the watchapp's details page in the 'Dashboard'
   view and click the 'Enable timeline' button.

2. To obtain API keys, click the 'Manage Timeline Settings' button at the
   top-right of the page. New API keys can also be generated from this page. If
   required, users with sandbox mode access can also be whitelisted here.

## About Sandbox Mode

The sandbox mode is automatically used when the app is sideloaded using the SDK.
By default, sandbox pins will be delivered to all users who sideload a PBW.

The production mode is used when a user installs the app from the Pebble
appstore. Use the two respective API key types for these purposes. If
whitelisting is enabled in sandbox mode, the developer's account is
automatically included, and they can add more Pebble users by adding the users'
email addresses in the [Developer Portal]().

If preferred, it is possible to enable whitelisting to limit this access to only
users involved in development and testing of the app. Enter the email addresses
of users to be authorized to use the app's timeline in sandbox mode on the
'Manage Timeline Settings' page of an app listing.

> When whitelisting is enabled, the `Pebble.getTimelineToken()` will return an
> error for users who are not in the whitelist.

