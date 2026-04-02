<!-- Generated from pebble-dev/developer.rebble.io (Apache 2.0) with modifications -->

# Communication

> How to talk to the phone via PebbleKit with JavaScript and on Android or iOS.

## Advanced Communication

Many types of connected Pebble watchapps and watchfaces perform common tasks
such as the ones discussed here. Following these best practices can increase the
quality of the implementation of each one, and avoid common bugs.

## Waiting for PebbleKit JS

Any app that wishes to send data from the watch to the phone via
 **must**
wait until the JavaScript `ready` event has occured, indicating that the phone
has loaded the JavaScript component of the launching app. If this JavaScript
code implements the `appmessage` event listsner, it is ready to receive data.

> An watchapp that only *receives* data from PebbleKit JS does not have to wait
> for the `ready` event. In addition, Android companion apps do not have to wait
> for such an event thanks to the `Intent` system. iOS companion apps must wait
> for `-watchDidConnect:`.

A simple method is to define a key in `package.json` that will be interpreted by
the watchapp to mean that the JS environment is ready for exchange data:

```js
"messageKeys": [
  "JSReady"
]
```

The watchapp should implement a variable that describes if the `ready` event has
occured. An example is shown below:

```c
static bool s_js_ready;
```

This can be exported in a header file for other parts of the app to check. Any
parts of the app that are waiting should call this as part of a
[retry](#timeouts-and-retries) mechanism.

```c
bool comm_is_js_ready() {
  return s_js_ready;
}
```

The state of this variable will be `false` until set to `true` when the `ready`
event causes the key to be transmitted:

```js
Pebble.addEventListener('ready', function() {
  console.log('PebbleKit JS ready.');

  // Update s_js_ready on watch
  Pebble.sendAppMessage({'JSReady': 1});
});
```

This key should be interpreted in the app's ``AppMessageInboxReceived``
implementation:

```c
static void inbox_received_handler(DictionaryIterator *iter, void *context) {
  Tuple *ready_tuple = dict_find(iter, MESSAGE_KEY_JSReady);
  if(ready_tuple) {
    // PebbleKit JS is ready! Safe to send messages
    s_js_ready = true;
  }
}
```

## Timeouts and Retries

Due to the wireless and stateful nature of the Bluetooth connection, some
messages sent between the watch and phone may fail. A tried-and-tested method
for dealing with these failures is to implement a 'timeout and retry' mechanism.
Under such a scheme:

* A message is sent and a timer started.

* If the message is sent successfully (and optionally a reply received), the
  timer is cancelled.

* If the timer elapses before the message can be sent successfully, the message
  is reattempted. Depending on the nature of the failure, a suitable retry
  interval (such as a few seconds) is used to avoid saturating the connection.

The interval chosen before a timeout occurs and the message is resent may vary
depending on the circumstances. The first failure should be reattempted fairly
quickly (one second), with the interval increasing as successive failures
occurs. If the connection is not available the timer interval should be
[even longer](https://en.wikipedia.org/wiki/Exponential_backoff), or wait until
the connection is restored.

### Using a Timeout Timer

The example below shows the sending of a message and scheduling a timeout timer.
The first step is to declare a handle for the timeout timer:

```c
static AppTimer *s_timeout_timer;
```

When the message is sent, the timer should be scheduled:

```c
static void send_with_timeout(int key, int value) {
  // Construct and send the message
  DitionaryIterator *iter;
  if(app_message_outbox_begin(&iter) == APP_MSG_OK) {
    dict_write_int(iter, key, &value, sizeof(int), true);
    app_message_outbox_send();
  }

  // Schedule the timeout timer
  const int interval_ms = 1000;
  s_timout_timer = app_timer_register(interval_ms, timout_timer_handler, NULL);
}
```

If the ``AppMessageOutboxSent`` is called, the message was a success, and the
timer should be cancelled:

```c
static void outbox_sent_handler(DictionaryIterator *iter, void *context) {
  // Successful message, the timeout is not needed anymore for this message
  app_timer_cancel(s_timout_timer);
}
```

### Retry a Failed Message

However, if the timeout timer elapses before the message's success can be
determined or an expected reply is not received, the callback to
`timout_timer_handler()` should be used to inform the user of the failure, and
schedule another attempt and retry the message:

```c
static void timout_timer_handler(void *context) {
  // The timer elapsed because no success was reported
  text_layer_set_text(s_status_layer, "Failed. Retrying...");

  // Retry the message
  send_with_timeout(some_key, some_value);
}
```

Alternatively, if the ``AppMessageOutboxFailed`` is called the message failed to
send, sometimes immediately. The timeout timer should be cancelled and the
message reattempted after an additional delay (the 'retry interval') to avoid
saturating the channel:

```c
static void outbox_failed_handler(DictionaryIterator *iter,
                                      AppMessageResult reason, void *context) {
  // Message failed before timer elapsed, reschedule for later
  if(s_timout_timer) {
    app_timer_cancel(s_timout_timer);
  }

  // Inform the user of the failure
  text_layer_set_text(s_status_layer, "Failed. Retrying...");

  // Use the timeout handler to perform the same action - resend the message
  const int retry_interval_ms = 500;
  app_timer_register(retry_interval_ms, timout_timer_handler, NULL);
}
```

> Note: All eventualities where a message fails must invoke a resend of the
> message, or the purpose of an automated 'timeout and retry' mechanism is
> defeated. However, the number of attempts made and the interval between them
> is for the developer to decide.

## Sending Lists

Until SDK 3.8, the size of ``AppMessage`` buffers did not facilitate sending
large amounts of data in one message. With the current buffer sizes of up to 8k
for each an outbox the need for efficient transmission of multiple sequential
items of data is lessened, but the technique is still important. For instance,
to transmit sensor data as fast as possible requires careful scheduling of
successive messages.

Because there is no guarantee of how long a message will take to transmit,
simply using timers to schedule multiple messages after one another is not
reliable. A much better method is to make good use of the callbacks provided by
the ``AppMessage`` API.

### Sending a List to the Phone

For instance, the ``AppMessageOutboxSent`` callback can be used to safely
schedule the next message to the phone, since the previous one has been
acknowledged by the other side at that time. Here is an example array of items:

```c
static int s_data[] = { 2, 4, 8, 16, 32, 64 };

#define NUM_ITEMS sizeof(s_data);
```

A variable can be used to keep track of the current list item index that should
be transmitted next:

```c
static int s_index = 0;
```

When a message has been sent, this index is used to construct the next message:

> Note: A useful key scheme is to use the item's array index as the key. For
> PebbleKit JS that number of keys will have to be declared in `package.json`,
> like so: `someArray[6]`

```c
static void outbox_sent_handler(DictionaryIterator *iter, void *context) {
  // Increment the index
  s_index++;

  if(s_index < NUM_ITEMS) {
    // Send the next item
    DictionaryIterator *iter;
    if(app_message_outbox_begin(&iter) == APP_MSG_OK) {
      dict_write_int(iter, MESSAGE_KEY_someArray + s_index, &s_data[s_index], sizeof(int), true);
      app_message_outbox_send();
    }
  } else {
    // We have reached the end of the sequence
    APP_LOG(APP_LOG_LEVEL_INFO, "All transmission complete!");
  }
}
```

This results in a callback loop that repeats until the last data item has been
transmitted, and the index becomes equal to the total number of items. This
technique can be combined with a timeout and retry mechanism to reattempt a
particular item if transmission fails. This is a good way to avoid gaps in the
received data items.

On the phone side, the data items are received in the same order. An analogous
`index` variable is used to keep track of which item has been received. This
process will look similar to the example shown below:

```js
var NUM_ITEMS = 6;
var keys = require('message_keys');

var data = [];
var index = 0;

Pebble.addEventListener('appmessage', function(e) {
  // Store this data item
  data[index] = e.payload[keys.someArray + index];

  // Increment index for next message
  index++;

  if(index == NUM_ITEMS) {
    console.log('Received all data items!');
  }
});
```

### Sending a List to Pebble

Conversely, the `success` callback of `Pebble.sendAppMessage()` in PebbleKit JS
is the equivalent safe time to send the next message to the watch.

An example implementation that achieves this is shown below. After the message
is sent with `Pebble.sendAppMessage()`, the `success` callback calls the
`sendNextItem()` function repeatedly until the index is larger than that of the
last list item to be sent, and transmission will be complete. Again, an index
variable is maintained to keep track of which item is being transmitted:

```js
var keys = require('message_keys');
function sendNextItem(items, index) {
  // Build message
  var key = keys.someArray + index;
  var dict = {};
  dict[key] = items[index];

  // Send the message
  Pebble.sendAppMessage(dict, function() {
    // Use success callback to increment index
    index++;

    if(index < items.length) {
      // Send next item
      sendNextItem(items, index);
    } else {
      console.log('Last item sent!');
    }
  }, function() {
    console.log('Item transmission failed at index: ' + index);
  });
}

function sendList(items) {
  var index = 0;
  sendNextItem(items, index);
}

function onDownloadComplete(responseText) {
  // Some web response containing a JSON object array
  var json = JSON.parse(responseText);

  // Begin transmission loop
  sendList(json.items);
}
```

On the watchapp side, the items are received in the same order in the
``AppMessageInboxReceived`` handler:

```c
#define NUM_ITEMS 6

static int s_index;
static int s_data[NUM_ITEMS];
```

```c
static void inbox_received_handler(DictionaryIterator *iter, void *context) {
  Tuple *data_t = dict_find(iter, MESSAGE_KEY_someArray + s_index);
  if(data_t) {
    // Store this item
    s_data[index] = (int)data_t->value->int32;

    // Increment index for next item
    s_index++;
  }

  if(s_index == NUM_ITEMS) {
    // We have reached the end of the sequence
    APP_LOG(APP_LOG_LEVEL_INFO, "All transmission complete!");
  }
}
```

This sequence of events is demonstrated for PebbleKit JS, but the same technique
can be applied exactly to either and Android or iOS companion app wishing to
transmit many data items to Pebble.

Get the complete source code for this example from the
[`list-items-example`](https://github.com/pebble-examples/list-items-example)
repository on GitHub.

## Sending Image Data

A common task developers want to accomplish is display a dynamically loaded
image resource (for example, showing an MMS photo or a news item thumbnail
pulled from a webservice). Because some images could be larger than the largest
buffer size available to the app, the techniques shown above for sending lists
also prove useful here, as the image is essentially a list of color byte values.

### Image Data Format

There are two methods available for displaying image data downloaded from the
web:

1. Download a `png` image, transmit the compressed data, and decompress using
   ``gbitmap_create_from_png_data()``. This involves sending less data, but can
   be prone to failure depending on the exact format of the image. The image
   must be in a compatible palette (1, 2, 4, or 8-bit) and small enough such
   that there is enough memory for a compessed copy, an uncompressed copy, and
   ~2k overhead when it is being processed.

2. Download a `png` image, decompress in the cloud or in PebbleKit JS into an
   array of image pixel bytes, transmit the pixel data into a blank
   ``GBitmap``'s `data` member. Each byte must be in the compatible Pebble color
   format (2 bits per ARGB). This process can be simplified by pre-formatting
   the image to be dowloaded, as resizing or palette-reduction is difficult to
   do locally.

### Sending Compressed PNG Data

As the fastest and least complex of the two methods described above, an example
of how to display a compressed PNG image will be discussed here. The image that
will be displayed is
[the HTML 5 logo](https://www.w3.org/html/logo/):

![The HTML5 logo.](/images/guides/pebble-apps/communications/html5-logo-small.png)

> Note: The above image has been resized and palettized for compatibility.

To download this image in PebbleKit JS, use an `XmlHttpRequest` object. It is
important to specify the `responseType` as 'arraybuffer' to obtain the image
data in the correct format:

```js
function downloadImage() {
  var url = 'https://developer.rebble.io/assets/images/guides/pebble-apps/communications/html5-logo-small.png';

  var request = new XMLHttpRequest();
  request.onload = function() {
    processImage(this.response);
  };
  request.responseType = "arraybuffer";
  request.open("GET", url);
  request.send();
}
```

When the response has been received, `processImage()` will be called. The
received data must be converted into an array of unsigned bytes, which is
achieved through the use of a `Uint8Array`. This process is shown below (see
the
[`png-download-example`](https://github.com/pebble-examples/png-download-example)
repository for the full example):

```js
function processImage(responseData) {
  // Convert to a array
  var byteArray = new Uint8Array(responseData);
  var array = [];
  for(var i = 0; i < byteArray.byteLength; i++) {
    array.push(byteArray[i]);
  }

  // Send chunks to Pebble
  transmitImage(array);
}
```

Now that the image data has been converted, the transmission to Pebble can
begin. At a high level, the JS side transmits the image data in chunks, using an
incremental array index to coordinate saving of data on the C side in a mirror
array. In downloading the image data, the following keys are used for the
specified purposes:

| Key | Purpose |
|-----|---------|
| `Index` | The array index that the current chunk should be stored at. This gets larger as each chunk is transmitted. |
| `DataLength` | This length of the entire data array to be downloaded. As the image is compressed, this is _not_ the product of the width and height of the image. |
| `DataChunk` | The chunk's image data. |
| `ChunkSize` | The size of this chunk. |
| `Complete` | Used to signify that the image transfer is complete. |

The first message in the sequence should tell the C side how much memory to
allocate to store the compressed image data:

```js
function transmitImage(array) {
  var index = 0;
  var arrayLength = array.length;

  // Transmit the length for array allocation
  Pebble.sendAppMessage({'DataLength': arrayLength}, function(e) {
    // Success, begin sending chunks
    sendChunk(array, index, arrayLength);
  }, function(e) {
    console.log('Failed to initiate image transfer!');
  })
}
```

If this message is successful, the transmission of actual image data commences
with the first call to `sendChunk()`. This function calculates the size of the
next chunk (the smallest of either the size of the `AppMessage` inbox buffer, or
the remainder of the data) and assembles the dictionary containing the index in
the array it is sliced from, the length of the chunk, and the actual data
itself:

```js
function sendChunk(array, index, arrayLength) {
  // Determine the next chunk size
  var chunkSize = BUFFER_SIZE;
  if(arrayLength - index < BUFFER_SIZE) {
    // Resize to fit just the remaining data items
    chunkSize = arrayLength - index;
  }

  // Prepare the dictionary
  var dict = {
    'DataChunk': array.slice(index, index + chunkSize),
    'ChunkSize': chunkSize,
    'Index': index
  };

  // Send the chunk
  Pebble.sendAppMessage(dict, function() {
    // Success
    index += chunkSize;

    if(index < arrayLength) {
      // Send the next chunk
      sendChunk(array, index, arrayLength);
    } else {
      // Complete!
      Pebble.sendAppMessage({'Complete': 0});
    }
  }, function(e) {
    console.log('Failed to send chunk with index ' + index);
  });
}
```

After each chunk is sent, the index is incremented with the size of the chunk
that was just sent, and compared to the total length of the array. If the index
exceeds the size of the array, the loop has sent all the data (this could be
just a single chunk if the array is smaller than the maximum message size). The
`AppKeyComplete` key is sent to inform the C side that the image is complete and
ready for display.

### Receiving Compressed PNG Data

In the previous section, the process for using PebbleKit JS to download and
transmit an image to the C side was discussed. The process for storing and
displaying this data is discussed here. Only when both parts work in harmony can
an image be successfully shown from the web.

The majority of the process takes place within the watchapp's
``AppMessageInboxReceived`` handler, with the presence of each key being
detected and the appropriate actions taken to reconstruct the image.

The first item expected is the total size of the data to be transferred. This is
recorded (for later use with ``gbitmap_create_from_png_data()``) and the buffer
used to store the chunks is allocated to this exact size:

```c
static uint8_t *s_img_data;
static int s_img_size;
```

```c
// Get the received image chunk
Tuple *img_size_t = dict_find(iter, MESSAGE_KEY_DataLength);
if(img_size_t) {
  s_img_size = img_size_t->value->int32;

  // Allocate buffer for image data
  img_data = (uint8_t*)malloc(s_img_size * sizeof(uint8_t));
}
```

When the message containing the data size is acknowledged, the JS side begins
sending chunks with `sendChunk()`. When one of these subsequent messages is
received, the three keys (`DataChunk`, `ChunkSize`, and
`Index`) are used to store that chunk of data at the correct offset in the
array:

```c
// An image chunk
Tuple *chunk_t = dict_find(iter, MESSAGE_KEY_DataChunk);
if(chunk_t) {
  uint8_t *chunk_data = chunk_t->value->data;

  Tuple *chunk_size_t = dict_find(iter, MESSAGE_KEY_ChunkSize);
  int chunk_size = chunk_size_t->value->int32;

  Tuple *index_t = dict_find(iter, MESSAGE_KEY_Index);
  int index = index_t->value->int32;

  // Save the chunk
  memcpy(&s_img_data[index], chunk_data, chunk_size);
}
```

Finally, once the array index exceeds the size of the data array on the JS side,
the `AppKeyComplete` key is transmitted, triggering the data to be transformed
into a ``GBitmap``:

```c
static BitmapLayer *s_bitmap_layer;
static GBitmap *s_bitmap;
```

```c
// Complete?
Tuple *complete_t = dict_find(iter, MESSAGE_KEY_Complete);
if(complete_t) {
  // Create new GBitmap from downloaded PNG data
  s_bitmap = gbitmap_create_from_png_data(s_img_data, s_img_size);

  // Show the image
  if(s_bitmap) {
    bitmap_layer_set_bitmap(s_bitmap_layer, s_bitmap);
  } else {
    APP_LOG(APP_LOG_LEVEL_ERROR, "Error creating GBitmap from PNG data!");
  }
}
```

The final result is a compressed PNG image downloaded from the web displayed in
a Pebble watchapp.

![watch >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/pebble-apps/communications/html-5-watch.png)

Get the complete source code for this example from the
[`png-download-example`](https://github.com/pebble-examples/png-download-example)
repository on GitHub.

## Datalogging

In addition to the more realtime ``AppMessage`` API, the Pebble SDK also
includes the ``Datalogging`` API. This is useful for applications where data can
be sent in batches at time intervals that make the most sense (for example, to
save battery power by allowing the watch to spend more time sleeping).

Datalogging also allows upto 640 kB of data to be buffered on the watch until a
connection is available, instead of requiring a connection be present at all
times. If data is logged while the watch is disconnected, it will be transferred
to the Pebble mobile app in batches for processing at the next opportunity. The
data is then passed on to any 
 or 
 companion
app that wishes to process it.

## Collecting Data

Datalogging can capture any values that are compatible with one of the
``DataLoggingItemType`` `enum` (byte array, unsigned integer, and integer)
values, with common sources including accelerometer data or compass data.

### Creating a Session

Data is logged to a 'session' with a unique identifier or tag, which allows a
single app to have multiple data logs for different types of data. First, define
the identifier(s) that should be used where appropriate:

```c
// The log's ID. Only one required in this example
#define TIMESTAMP_LOG 1
```

Next, a session must first be created before any data can be logged to it. This
should be done during app initialization, or just before the first time an app
needs to log some data:

```c
// The session reference variable
static DataLoggingSessionRef s_session_ref;
```

```c
static void init() {
  // Begin the session
  s_session_ref = data_logging_create(TIMESTAMP_LOG, DATA_LOGGING_INT, sizeof(int), true);

  /* ... */
}
```

> Note: The final parameter of ``data_logging_create()`` allows a previous log
> session to be continued, instead of starting from screatch on each app launch.

### Logging Data

Once the log has been created or resumed, data collection can proceed. Each call
to ``data_logging_log()`` will add a new entry to the log indicated by the
``DataLoggingSessionRef`` variable provided. The success of each logging
operation can be checked using the ``DataLoggingResult`` returned:

```c
const int value = 16;
const uint32_t num_values = 1;

// Log a single value
DataLoggingResult result = data_logging_log(s_session_ref, &value, num_values);

// Was the value successfully stored? If it failed, print the reason
if(result != DATA_LOGGING_SUCCESS) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Error logging data: %d", (int)result);
}
```

### Finishing a Session

Once all data has been logged or the app is exiting, the session must be
finished to signify that the data is to be either transferred to the connected
phone (if available), or stored for later transmission. 

```c
// Finish the session and sync data if appropriate
data_logging_finish(s_session_ref);
``` 

> Note: Once a session has been finished, data cannot be logged to its
> ``DataLoggingSessionRef`` until it is resumed or began anew.

## Receiving Data

> Note: Datalogging data cannot be received via PebbleKit JS.

Data collected with the ``Datalogging`` API can be received and processed in a
mobile companion app using PebbleKit Android or PebbleKit iOS. This enables it
to be used in a wide range of general applications, such as detailed analysis of
accelerometer data for health research, or transmission to a third-party web
service.

### With PebbleKit Android

PebbleKit Android allows collection of data by registering a
`PebbleDataLogReceiver` within your `Activity` or `Service`. When creating a
receiver, be careful to provide the correct UUID to match that of the watchapp
that is doing that data collection. For example:

```java
// The UUID of the watchapp
private UUID APP_UUID = UUID.fromString("64fcb54f-76f0-418a-bd7d-1fc1c07c9fc1");
```

Use the following overridden methods to collect data and determine when the
session has been finished by the watchapp. In the example below, each new
integer received represents the uptime of the watchapp, and is displayed in an
Android `TextView`:

```java
// Create a receiver to collect logged data
PebbleKit.PebbleDataLogReceiver dataLogReceiver = 
        new PebbleKit.PebbleDataLogReceiver(APP_UUID) {

  @Override
  public void receiveData(Context context, UUID logUuid, Long timestamp, 
                                                          Long tag, int data) {
    // super() (removed from IDE-generated stub to avoid exception)

    Log.i(TAG, "New data for session " + tag + "!");

    // Cumulatively add the new data item to a TextView's current text
    String current = dataView.getText().toString();
    current += timestamp.toString() + ": " + data 
                + "s since watchapp launch.\n";
    dataView.setText(current);
  }

  @Override
  public void onFinishSession(Context context, UUID logUuid, Long timestamp, 
                                                                    Long tag) {
    Log.i(TAG, "Session " + tag + " finished!");
  }

};

// Register the receiver
PebbleKit.registerDataLogReceiver(getApplicationContext(), dataLogReceiver);
```

<div class="alert alert--fg-white alert--bg-dark-red">

**Important**

If your Java IDE automatically adds a line of code to call super() when you
create the method, the code will result in an UnsupportedOperationException.
Ensure you remove this line to avoid the exception.

</div>

Once the `Activity` or `Service` is closing, you should attempt to unregister
the receiver. However, this is not always required (and will cause an exception
to be thrown if invoked when not required), so use a `try, catch` statement:

```java
@Override
protected void onPause() {
  super.onPause();

  try {
    unregisterReceiver(dataLogReceiver);
  } catch(Exception e) {
    Log.w(TAG, "Receiver did not need to be unregistered");
  }
}
```

### With PebbleKit iOS

The process of collecing data via a PebbleKit iOS companion mobile app is
similar to that of using PebbleKit Android. Once your app is a delegate of
``PBDataLoggingServiceDelegate`` (see 
 for details), 
simply register the class as a datalogging delegate:

```objective-c
// Get datalogging data by becoming the delegate
[[PBPebbleCentral defaultCentral] 
                      dataLoggingServiceForAppUUID:myAppUUID].delegate = self;
```

Being a datalogging delegate allows the class to receive two additional
[callbacks](/docs/pebblekit-ios/Protocols/PBDataLoggingServiceDelegate/) for when new data
is available, and when the session has been finished by the watch. Implement
these callbacks to read the new data:

```objective-c
- (BOOL)dataLoggingService:(PBDataLoggingService *)service
              hasSInt32s:(const SInt32 [])data
           numberOfItems:(UInt16)numberOfItems
              forDataLog:(PBDataLoggingSessionMetadata *)log {
  NSLog(@"New data received!");
  
  // Append newest data to displayed string
  NSString *current = self.dataView.text;
  NSString *newString = [NSString stringWithFormat:@"New item: %d", data[0]];
  current = [current stringByAppendingString:newString];
  self.dataView.text = current;
  
  return YES;
}

- (void)dataLoggingService:(PBDataLoggingService *)service
            logDidFinish:(PBDataLoggingSessionMetadata *)log {
  NSLog(@"Finished data log: %@", log);
}
```

### Special Considerations for iOS Apps

* The logic to deal with logs with the same type of data (i.e., the same
  tag/type) but from different sessions (different timestamps) must be created
  by the developer using the delegate callbacks.

* To check whether the data belongs to the same log or not, use `-isEqual:` on
  `PBDataLoggingSessionMetadata`. For convenience,
  `PBDataLoggingSessionMetadata` can be serialized using `NSCoding`.

* Using multiple logs in parallel (for example to transfer different kinds of
  information) will require extra logic to re-associate the data from these
  different logs, which must also be implemented by the developer.

## Sending and Receiving Data

Before using ``AppMessage``, a Pebble C app must set up the buffers used for the
inbox and outbox. These are used to store received messages that have not yet
been processed, and sent messages that have not yet been transmitted. In
addition, callbacks may be registered to allow an app to respond to any success
or failure events that occur when dealing with messages. Doing all of this is
discussed in this guide.

## Message Structure

Every message sent or received using the ``AppMessage`` API is stored in a
``DictionaryIterator`` structure, which is essentially a list of ``Tuple``
objects. Each ``Tuple`` contains a key used to 'label' the value associated with
that key. 

When a message is sent, a ``DictionaryIterator`` is filled with a ``Tuple`` for
each item of outgoing data. Conversely, when a message is received the
``DictionaryIterator`` provided by the callback is examined for the presence of
each key. If a key is present, the value associated with it can be read.

## Data Types

The [`Tuple.value`](``Tuple``) union allows multiple data types to be stored in
and read from each received message. These are detailed below:

| Name | Type | Size in Bytes | Signed? |
|------|------|---------------|---------|
| uint8 | `uint8_t` | 1 | No |
| uint16 | `uint16_t` | 2 | No |
| uint32 | `uint32_t` | 4 | No |
| int8 | `int8_t` | 1 | Yes |
| int16 | `int16_t` | 2 | Yes |
| int32 | `int32_t` | 4 | Yes |
| cstring | `char[]` | Variable length array | N/A |
| data | `uint8_t[]` | Variable length array | N/A |

## Buffer Sizes

The size of each of the outbox and inbox buffers must be set chosen such that
the largest message that the app will ever send or receive will fit. Incoming
messages that exceed the size of the inbox buffer, and outgoing messages that
exceed that size of the outbox buffer will be dropped.

These sizes are specified when the ``AppMessage`` system is 'opened', allowing
communication to occur:

```c
// Largest expected inbox and outbox message sizes
const uint32_t inbox_size = 64;
const uint32_t outbox_size = 256;

// Open AppMessage
app_message_open(inbox_size, outbox_size);
```

Each of these buffers is allocated at this moment, and comes out of the app's
memory budget, so the sizes of the inbox and outbox should be conservative.
Calculate the size of the buffer you require by summing the sizes of all the
keys and values in the larges message the app will handle. For example, a
message containing three integer keys and values will work with a 32 byte buffer
size.

## Choosing Keys

For each message sent and received, the contents are accessible using keys-value
pairs in a ``Tuple``. This allows each piece of data in the message to be
uniquely identifiable using its key, and also allows many different data types
to be stored inside a single message.

Each possible piece of data that may be transmitted should be assigned a unique
key value, used to read the associated value when it is found in a received
message. An example for a weather app is shown below::

* Temperature
* WindSpeed
* WindDirection
* RequestData
* LocationName

These values will be made available in any file that includes `pebble.h` prefixed
with `MESSAGE_KEY_`, such as `MESSAGE_KEY_Temperature` and `MESSAGE_KEY_WindSpeed`.

Examples of how these key values would be used in the phone-side app are
shown in , 
, and
.

## Using Callbacks

Like many other aspects of the Pebble C API, the ``AppMessage`` system makes
use of developer-defined callbacks to allow an app to gracefully handle all
events that may occur, such as successfully sent or received messages as well as
any errors that may occur.

These callback types are discussed below. Each is used by first creating a
function that matches the signature of the callback type, and then registering
it with the ``AppMessage`` system to be called when that event type occurs. Good
use of callbacks to drive the app's UI will result in an improved user
experience, especially when errors occur that the user can be guided in fixing.

### Inbox Received

The ``AppMessageInboxReceived`` callback is called when a new message has been
received from the connected phone. This is the moment when the contents can be
read and used to drive what the app does next, using the provided
``DictionaryIterator`` to read the message. An example is shown below under
[*Reading an Incoming Message*](#reading-an-incoming-message):

```c
static void inbox_received_callback(DictionaryIterator *iter, void *context) {
  // A new message has been successfully received

}
```

Register this callback so that it is called at the appropriate time:

```c
// Register to be notified about inbox received events
app_message_register_inbox_received(inbox_received_callback);
```

### Inbox Dropped

The ``AppMessageInboxDropped`` callback is called when a message was received,
but it was dropped. A common cause of this is that the message was too big for
the inbox. The reason for failure can be determined using the
``AppMessageResult`` provided by the callback:

```c
static void inbox_dropped_callback(AppMessageResult reason, void *context) {
  // A message was received, but had to be dropped
  APP_LOG(APP_LOG_LEVEL_ERROR, "Message dropped. Reason: %d", (int)reason);
}
```

Register this callback so that it is called at the appropriate time:

```c
// Register to be notified about inbox dropped events
app_message_register_inbox_dropped(inbox_dropped_callback);
```

### Outbox Sent

The ``AppMessageOutboxSent`` callback is called when a message sent from Pebble
has been successfully delivered to the connected phone. The provided
``DictionaryIterator`` can be optionally used to inspect the contents of the
message just sent.

> When sending multiple messages in a short space of time, it is **strongly**
> recommended to make use of this callback to wait until the previous message
> has been sent before sending the next.

```c
static void outbox_sent_callback(DictionaryIterator *iter, void *context) {
  // The message just sent has been successfully delivered

}
```

Register this callback so that it is called at the appropriate time:

```c
// Register to be notified about outbox sent events
app_message_register_outbox_sent(outbox_sent_callback);
```

### Outbox Failed

The ``AppMessageOutboxFailed`` callback is called when a message just sent
failed to be successfully delivered to the connected phone. The reason can be
determined by reading the value of the provided ``AppMessageResult``, and the
contents of the failed message inspected with the provided
``DictionaryIterator``.

Use of this callback is strongly encouraged, since it allows an app to detect a
failed message and either retry its transmission, or inform the user of the
failure so that they can attempt their action again.

```c
static void outbox_failed_callback(DictionaryIterator *iter,
                                      AppMessageResult reason, void *context) {
  // The message just sent failed to be delivered
  APP_LOG(APP_LOG_LEVEL_ERROR, "Message send failed. Reason: %d", (int)reason);
}
```

Register this callback so that it is called at the appropriate time:

```c
// Register to be notified about outbox failed events
app_message_register_outbox_failed(outbox_failed_callback);
```

## Constructing an Outgoing Message

A message is constructed and sent from the C app via ``AppMessage`` using a
``DictionaryIterator`` object and the ``Dictionary`` APIs. Ensure that
``app_message_open()`` has been called before sending or receiving any messages.

The first step is to begin an outgoing message by preparing a
``DictionaryIterator`` pointer, used to keep track of the state of the
dictionary being constructed:

```c
// Declare the dictionary's iterator
DictionaryIterator *out_iter;

// Prepare the outbox buffer for this message
AppMessageResult result = app_message_outbox_begin(&out_iter);
```

The ``AppMessageResult`` should be checked to make sure the outbox was
successfully prepared:

```c
if(result == APP_MSG_OK) {
  // Construct the message

} else {
  // The outbox cannot be used right now
  APP_LOG(APP_LOG_LEVEL_ERROR, "Error preparing the outbox: %d", (int)result);
}
```

If the result is ``APP_MSG_OK``, the message construction can continue. Data is
now written to the dictionary according to data type using the ``Dictionary``
APIs. An example from the hypothetical weather app is shown below:

```c
if(result == APP_MSG_OK) {
  // A dummy value
  int value = 0;

  // Add an item to ask for weather data
  dict_write_int(out_iter, MESSAGE_KEY_RequestData, &value, sizeof(int), true);
}
```

After all desired data has been written to the dictionary, the message may be
sent:

```c
// Send this message
result = app_message_outbox_send();

// Check the result
if(result != APP_MSG_OK) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Error sending the outbox: %d", (int)result);
}
```

<div class="alert alert--fg-white alert--bg-dark-red">

**Important**

Any app that wishes to send data from the watch to the phone via PebbleKit JS
must wait until the `ready` event has occured, indicating that the phone has
loaded the JavaScript for the app and it is ready to receive data. See
[*Advanced Communication*](/guides/communication/advanced-communication#waiting-for-pebblekit-js)
for more information.

</div>

Once the message send operation has been completed, either the
``AppMessageOutboxSent`` or ``AppMessageOutboxFailed`` callbacks will be called
(if they have been registered), depending on either a success or failure
outcome.

### Example Outgoing Message Construction

A complete example of assembling an outgoing message is shown below:

```c
// Declare the dictionary's iterator
DictionaryIterator *out_iter;

// Prepare the outbox buffer for this message
AppMessageResult result = app_message_outbox_begin(&out_iter);
if(result == APP_MSG_OK) {
  // Add an item to ask for weather data
  int value = 0;
  dict_write_int(out_iter, MESSAGE_KEY_RequestData, &value, sizeof(int), true);

  // Send this message
  result = app_message_outbox_send();
  if(result != APP_MSG_OK) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "Error sending the outbox: %d", (int)result);
  }
} else {
  // The outbox cannot be used right now
  APP_LOG(APP_LOG_LEVEL_ERROR, "Error preparing the outbox: %d", (int)result);
}
```

## Reading an Incoming Message

When a message is received from the connected phone the
``AppMessageInboxReceived`` callback is called, and the message's contents can
be read using the provided ``DictionaryIterator``. This should be done by
looking for the presence of each expectd `Tuple` key value, and using the
associated value as required.

Most apps will deal with integer values or strings to pass signals or some
human-readable information respectively. These common use cases are discussed
below.

### Reading an Integer

**From JS**

```js
var dict  = {
  'Temperature': 29
};
```

**In C**

```c
static void inbox_received_callback(DictionaryIterator *iter, void *context) {
  // A new message has been successfully received

  // Does this message contain a temperature value?
  Tuple *temperature_tuple = dict_find(iter, MESSAGE_KEY_Temperature);
  if(temperature_tuple) {
    // This value was stored as JS Number, which is stored here as int32_t
    int32_t temperature = temperature_tuple->value->int32;
  }
}
```

### Reading a String

A common use of transmitted strings is to display them in a ``TextLayer``. Since
the displayed text is required to be long-lived, a `static` `char` buffer can be
used when the data is received:

**From JS**

```js
var dict = {
  'LocationName': 'London, UK'
};
```

**In C**

```c
static void inbox_received_callback(DictionaryIterator *iter, void *context) {
  // Is the location name inside this message?
  Tuple *location_tuple = dict_find(iter, MESSAGE_KEY_LocationName);
  if(location_tuple) {
    // This value was stored as JS String, which is stored here as a char string
    char *location_name = location_tuple->value->cstring;

    // Use a static buffer to store the string for display
    static char s_buffer[MAX_LENGTH];
    snprintf(s_buffer, sizeof(s_buffer), "Location: %s", location_name);

    // Display in the TextLayer
    text_layer_set_text(s_text_layer, s_buffer);
  }
}
```

### Reading Binary Data

Apps that deal in packed binary data can send this data and pack/unpack as
required on either side:

**From JS**

```js
var dict = {
  'Data': [1, 2, 4, 8, 16, 32, 64]
};
```

**In C**

```c
static void inbox_received_callback(DictionaryIterator *iter, void *context) {
  // Expected length of the binary data
  const int length = 32;

  // Does this message contain the data tuple?
  Tuple *data_tuple = dict_find(iter, MESSAGE_KEY_Data);
  if(data_tuple) {
    // Read the binary data value
    uint8_t *data = data_tuple->value->data;

    // Inspect the first byte, for example
    uint8_t byte_zero = data[0];

    // Store into an app-defined buffer
    memcpy(s_buffer, data, length);
  }
```

## PebbleKit Android

[PebbleKit Android](https://github.com/pebble/pebble-android-sdk/) is a Java
library that works with the Pebble SDK and can be embedded in any Android
application. Using the classes and methods in this library, an Android companion
app can find and exchange data with a Pebble watch.

This section assumes that the reader is familiar with basic Android development
and Android Studio as an integrated development environment. Refer to the
[Android Documentation](http://developer.android.com/sdk/index.html) for more
information on installing the Android SDK.

Most PebbleKit Android methods require a `Context` parameter. An app can use
`getApplicationContext()`, which is available from any `Activity`
implementation.

### Setting Up PebbleKit Android

Add PebbleKit Android to an Android Studio project in the
`app/build.gradle` file:

```
dependencies {
  compile 'com.getpebble:pebblekit:'
}
```

### Sending Messages from Android

Since Android apps are built separately from their companion Pebble apps, there is
no way for the build system to automatically create matching appmessage keys.
You must therefore manually specify them in `package.json`, like so:

```js
{
  "ContactName": 0,
  "Age": 1
}
```

These numeric values can then be used as appmessage keys in your Android app.

Messages are constructed with the `PebbleDictionary` class and sent to a C
watchapp or watchface using the `PebbleKit` class. The first step is to create a
`PebbleDictionary` object:

```java
// Create a new dictionary
PebbleDictionary dict = new PebbleDictionary();
```

Data items are added to the 
[`PebbleDictionary`](/docs/pebblekit-android/com/getpebble/android/kit/util/PebbleDictionary) 
using key-value pairs with the methods made available by the object, such as
`addString()` and `addInt32()`. An example is shown below:

```java
// The key representing a contact name is being transmitted
final int AppKeyContactName = 0;
final int AppKeyAge = 1;

// Get data from the app
final String contactName = getContact();
final int age = getAge();

// Add data to the dictionary
dict.addString(AppKeyContactName, contactName);
dict.addInt32(AppKeyAge, age);
```

Finally, the dictionary is sent to the C app by calling `sendDataToPebble()`
with a UUID matching that of the C app that will receive the data:

```java
final UUID appUuid = UUID.fromString("EC7EE5C6-8DDF-4089-AA84-C3396A11CC95");

// Send the dictionary
PebbleKit.sendDataToPebble(getApplicationContext(), appUuid, dict);
```

Once delivered, this dictionary will be available in the C app via the
``AppMessageInboxReceived`` callback, as detailed in
.

### Receiving Messages on Android

Receiving messages from Pebble in a PebbleKit Android app requires a listener to
be registered in the form of a `PebbleDataReceiver` object, which extends
`BroadcastReceiver`:

```java
// Create a new receiver to get AppMessages from the C app
PebbleDataReceiver dataReceiver = new PebbleDataReceiver(appUuid) {

  @Override
  public void receiveData(Context context, int transaction_id,
                                                    PebbleDictionary dict) {
    // A new AppMessage was received, tell Pebble
    PebbleKit.sendAckToPebble(context, transaction_id);
  }

};
```

<div class="alert alert--fg-white alert--bg-dark-red">

**Important**

PebbleKit apps **must** manually send an acknowledgement (Ack) to Pebble to
inform it that the message was received successfully. Failure to do this will
cause timeouts.

</div>

Once created, this receiver should be registered in `onResume()`, overridden
from `Activity`:

```java
@Override
public void onResume() {
  super.onResume();

  // Register the receiver
  PebbleKit.registerReceivedDataHandler(getApplicationContext(), dataReceiver);
}
```

> Note: To avoid getting callbacks after the `Activity` or `Service` has exited,
> apps should attempt to unregister the receiver in `onPause()` with
> `unregisterReceiver()`.

With a receiver in place, data can be read from the provided 
[`PebbleDictionary`](/docs/pebblekit-android/com/getpebble/android/kit/util/PebbleDictionary)
using analogous methods such as `getString()` and `getInteger()`. Before reading
the value of a key, the app should first check that it exists using a `!= null`
check.

The example shown below shows how to read an integer from the message, in the
scenario that the watch is sending an age value to the Android companion app:

```java
@Override
public void receiveData(Context context, int transaction_id,
                                                      PebbleDictionary dict) {
  // If the tuple is present...
  Long ageValue = dict.getInteger(AppKeyAge);
  if(ageValue != null) {
    // Read the integer value
    int age = ageValue.intValue();
  }
}
```

### Other Capabilities

In addition to sending and receiving messages, PebbleKit Android also allows
more intricate interactions with Pebble. See the
[PebbleKit Android Documentation](/docs/pebblekit-android/com/getpebble/android/kit/PebbleKit/) 
for a complete list of available methods. Some examples are shown below of what
is possible:

* Checking if the watch is connected:

    ```java
    boolean connected = PebbleKit.isWatchConnected(getApplicationContext());
    ```

* Registering for connection events with `registerPebbleConnectedReceiver()` and
  `registerPebbleDisconnectedReceiver()`, and a suitable `BroadcastReceiver`.

    ```java
    PebbleKit.registerPebbleConnectedReceiver(getApplicationContext(),
                                                      new BroadcastReceiver() {

      @Override
      public void onReceive(Context context, Intent intent) { }

    });
    ```

* Registering for Ack/Nack events with `registerReceivedAckHandler()` and
  `registerReceivedNackHandler()`.

    ```java
    PebbleKit.registerReceivedAckHandler(getApplicationContext(),
                                  new PebbleKit.PebbleAckReceiver(appUuid) {

      @Override
      public void receiveAck(Context context, int i) { }

    });
    ```

* Launching and killing the watchapp with `startAppOnPebble()` and
  `closeAppOnPebble()`.

    ```java
    PebbleKit.startAppOnPebble(getApplicationContext(), appUuid);
    ```

## PebbleKit iOS

[PebbleKit iOS](https://github.com/pebble/pebble-ios-sdk/) is an Objective-C
framework that works with the Pebble SDK and can be embedded in any iOS
application for **iOS 7.1** and above. Using the classes and methods in this
framework, an iOS app can find and exchange data with a Pebble watch.

This section assumes that the reader has a basic knowledge of Objective-C, Xcode
as an IDE, and the delegate and block patterns.

> PebbleKit iOS should be compatible if your app uses Swift. The framework
> itself is written in Objective-C to avoid the requirement of the Swift runtime
> in pure Objective-C apps, and to improve the backwards and forwards
> compatibility.

### Setting Up PebbleKit iOS

If the project is using [CocoaPods](http://cocoapods.org/) (which is the
recommended approach), just add `pod 'PebbleKit'` to the `Podfile` and execute
`pod install`.

After installing PebbleKit iOS in the project, perform these final steps:

* If the iOS app needs to run in the background, you should update your target’s
  “Capabilities” in Xcode. Enable “Background Modes” and select both “Uses
  Bluetooth LE accessories” and “Acts as a Bluetooth LE accessory”. This should
  add the keys `bluetooth-peripheral` (“App shares data using CoreBluetooth”)
  and `bluetooth-central` (“App communicates using CoreBluetooth”) to your
  target’s `Info.plist` file.
* If you are using Xcode 8 or greater (and recommended for previous versions),
  you must also add the key `NSBluetoothPeripheralUsageDescription` (“Privacy -
  Bluetooth Peripheral Usage Description”) to your `Info.plist`.

> To add PebbleKit iOS manually, or some other alternatives follow the steps in
> the [repository](https://github.com/pebble/pebble-ios-sdk/). The documentation
> might also include more information that might be useful. Read it carefully.

### Targeting a Companion App

Before an iOS companion app can start communicating or exchange messages with a
watchapp on Pebble, it needs to give PebbleKit a way to identify the watchapp.
The UUID of your watchapp is used for this purpose.

Set the app UUID associated with the PBPebbleCentral instance. A simple way to
create a UUID in standard representation to `NSUUID` is shown here:

```objective-c
// Set UUID of watchapp
NSUUID *myAppUUID = 
    [[NSUUID alloc] initWithUUIDString:@"226834ae-786e-4302-a52f-6e7efc9f990b"];
[PBPebbleCentral defaultCentral].appUUID = myAppUUID;
```

If you are trying to communicate with the built-in Sports or Golf apps, their
UUID are available as part of PebbleKit with ``PBSportsUUID`` and
``PBGolfUUID``. You must register those UUID if you intend to communicate with
those apps.

### Becoming a Delegate

To communicate with a Pebble watch, the class must implement
`PBPebbleCentralDelegate`:

```objective-c
@interface ViewController () <PBPebbleCentralDelegate>
```

The `PBPebbleCentral` class should not be instantiated directly. Instead, always
use the singleton provided by `[PBPebbleCentral defaultCentral]`. An example is
shown below, with the Golf app UUID:

```objective-c
central = [PBPebbleCentral defaultCentral];
central.appUUID = myAppUUID;
[central run];
```

Once this is done, set the class to be the delegate:

```objective-c
[PBPebbleCentral defaultCentral].delegate = self;
```

This delegate will get two callbacks: `pebbleCentral:watchDidConnect:isNew:` and
`pebbleCentral:watchDidDisconnect:` every time a Pebble connects or disconnects.
The app won't get connection callbacks if the Pebble is already connected when
the delegate is set.

Implement these to receive the associated connection/disconnection events:

```objective-c
- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
  NSLog(@"Pebble connected: %@", watch.name);

  // Keep a reference to this watch
  self.connectedWatch = watch;
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
  NSLog(@"Pebble disconnected: %@", watch.name);

  // If this was the recently connected watch, forget it
  if ([watch isEqual:self.connectedWatch]) {
    self.connectedWatch = nil;
  }
}
```

### Initiating Bluetooth Communication

Once the iOS app is correctly set up to communicate with Pebble, the final step
is to actually begin communication. No communication can take place until the
following is called:

```objective-c
[[PBPebbleCentral defaultCentral] run];
```

> Once this occurs, the user _may_ be shown a dialog asking for confirmation
> that they want the app to communicate. This means the app should not call
> `run:` until the appropriate moment in the UI.

### Sending Messages from iOS

Since iOS apps are built separately from their companion Pebble apps, there is
no way for the build system to automatically create matching app message keys.
You must therefore manually specify them in `package.json`, like so:

```js
{
  "Temperature": 0,
  "WindSpeed": 1,
  "WindDirection": 2,
  "RequestData": 3,
  "LocationName": 4
}
```

These numeric values can then be used as app message keys in your iOS app.

Messages are constructed with the `NSDictionary` class and sent to the C
watchapp or watchface by the `PBPebbleCentralDelegate` when the
`appMessagesPushUpdate:` function is invoked.

To send a message, prepare an `NSDictionary` object with the data to be sent to
the C watchapp. Data items are added to the 
[`NSDictionary`](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDictionary_Class/)
using key-value pairs of standard data types. An example containing a string and
an integer is shown below:

```objective-c
NSDictionary *update = @{ @(0):[NSNumber pb_numberWithUint8:42],
                          @(1):@"a string" };
```

Send this dictionary to the watchapp using `appMessagesPushUpdate:`. The first
argument is the update dictionary to send and the second argument is a callback
block that will be invoked when the data has been acknowledged by the watch (or
if an error occurs).

```objective-c
[self.connectedWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
  if (!error) {
    NSLog(@"Successfully sent message.");
  } else {
    NSLog(@"Error sending message: %@", error);
  }
}];
```

Once delivered, this dictionary will be available in the C app via the
``AppMessageInboxReceived`` callback, as detailed in
.

### Receiving Messages on iOS

To receive messages from a watchapp, register a receive handler (a block)
with `appMessagesAddReceiveUpdateHandler:`. This block will be invoked with two
parameters - a pointer to a `PBWatch` object describing the Pebble that sent the
message and an `NSDictionary` with the message received.

```objective-c
[self.connectedWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
    NSLog(@"Received message: %@", update);

    // Send Ack to Pebble
    return YES;
}];
```

> Always return `YES` in the handler. This instructs PebbleKit to automatically
> send an ACK to Pebble, to avoid the message timing out.

Data can be read from the `NSDictionary` by first testing for each key's
presence using a `!= nil` check, and reading the value if it is present:

```objective-c
NSNumber *key = @1;

// If the key is present in the received dictionary
if (update[key]) {
  // Read the integer value
  int value = [update[key] intValue];
}
```

### Other Capabilities

In addition to sending and receiving messages, PebbleKit iOS also allows
more intricate interactions with Pebble. See the
[PebbleKit iOS Documentation](/docs/pebblekit-ios/) 
for more information. Some examples are shown below of what is possible:

* Checking if the watch is connected using the `connected` property of a
  `PBWatch`.

  ```objective-c
  BOOL isConnected = self.watch.connected;
  ```

* Receiving `watchDidConnect` and `watchDidDisconnect` events through being a
  `PBDataloggingServiceDelegate`.

### Limitations of PebbleKit on iOS

The iOS platform imposes some restrictions on what apps can do with accessories.
It also limits the capabilities of apps that are in the background. It is
critical to understand these limitations when developing an app that relies on
PebbleKit iOS.

On iOS, all communication between a mobile app and Pebble is managed through a
communication session. This communication session is a protocol specific to iOS,
with notable limitations that the reader should know and understand when
developing an iOS companion app for Pebble.

#### Bluetooth Low Energy (BLE) Connections

For Pebble apps that communicate with Pebble in BLE mode, a session can be
created for each app that requires one. This removes the 'one session only'
restriction, but only for these BLE apps. Currently, there are several
BLE only devices, such as Pebble Time Round, and Pebble 2, but all the devices
using a firmware 3.8 or greater can use BLE to communicate with PebbleKit.

For BLE apps, the 'phone must launch' restriction is removed. The iOS
companion app can be restarted by the watchapp if it stops working if user
force-quits iOS app, or it crashes. Note that the app will not work after
rebooting iOS device, which requires it be launched by the iPhone user once
after boot.

#### Communication with firmware older than 3.0

PebbleKit iOS 3.1.1 is the last PebbleKit that supports communication with
firmwares older than 3.0. PebbleKit iOS 4.0.0 can only communicate with Pebble
devices with firmware newer than 3.0.

For newer devices like Pebble Time, Pebble Time Steel, Pebble Time Round, and
Pebble 2 there should be no problem. For previous generation devices like Pebble
and Pebble Steel it means that their users should upgrade their firmware to the
latest firmware available for their devices using the new apps.

This change allows better compatibility and new features to be developed by 3rd
parties.

## PebbleKit JS

PebbleKit JS allows a JavaScript component (run in a sandbox inside the official
Pebble mobile app) to be added to any watchapp or watchface in order to extend
the functionality of the app beyond what can be accomplished on the watch
itself.

Extra features available to an app using PebbleKit JS include:

* Access to extended storage with [`localStorage`](#using-localstorage).

* Internet access using [`XMLHttpRequest`](#using-xmlhttprequest).

* Location data using [`geolocation`](#using-geolocation).

* The ability to show a configuration page to allow users to customize how the
  app behaves. This is discussed in detail in
  .

## Setting Up

PebbleKit JS can be set up by creating the `index.js` file in the project's
`src/pkjs/` directory. Code in this file will be executed when the associated
watchapp is launched, and will stop once that app exits.

The basic JS code required to begin using PebbleKit JS is shown below. An event
listener is created to listen for the `ready` event - fired when the watchapp
has been launched and the JS environment is ready to receive messages. This
callback must return within a short space of time (a few seconds) or else it
will timeout and be killed by the phone.

```js
Pebble.addEventListener('ready', function() {
  // PebbleKit JS is ready!
  console.log('PebbleKit JS ready!');
});
```

<div class="alert alert--fg-white alert--bg-dark-red">

**Important**

A watchapp or watchface **must** wait for the `ready` event before attempting to
send messages to the connected phone. See 
[*Advanced Communication*](/guides/communication/advanced-communication#waiting-for-pebblekit-js) 
to learn how to do this.

</div>

## Defining Keys

Before any messages can be sent or received, the keys to be used to store the
data items in the dictionary must be declared. The watchapp side uses
exclusively integer keys, whereas the JavaScript side may use the same integers
or named string keys declared in `package.json`. Any string key not declared
beforehand will not be transmitted to/from Pebble.

> Note: This requirement is true of PebbleKit JS **only**, and not PebbleKit
> Android or iOS.

Keys are declared in the project's `package.json` file in the `messageKeys`
object, which is inside the `pebble` object. Example keys are shown as equivalents
to the ones used in the hypothetical weather app example in
.

```json
"messageKeys": [
  "Temperature",
  "WindSpeed",
  "WindDirection",
  "RequestData",
  "LocationName"
]
```

The names chosen here will be injected into your C code prefixed with `MESSAGE_KEY_`,
like `MESSAGE_KEY_Temperature`. As such, they must be legal C identifiers.

If you want to emulate an array by attaching multiple "keys" to a name, you can
specify the size of the array by adding it in square brackets: for instance,
`"LapTimes[10]`" would create a key called `LapTimes` and leave nine empty keys
after it which can be accessed by arithmetic, e.g. `MESSAGE_KEY_LapTimes + 3`.

## Sending Messages from JS

Messages are sent to the C watchapp or watchface using
`Pebble.sendAppMessage()`, which accepts a standard JavaScript object containing
the keys and values to be transmitted. The keys used **must** be identical to
the ones declared earlier.

An example is shown below:

```js
// Assemble data object
var dict = {
  'Temperature': 29,
  'LocationName': 'London, UK'
};

// Send the object
Pebble.sendAppMessage(dict, function() {
  console.log('Message sent successfully: ' + JSON.stringify(dict));
}, function(e) {
  console.log('Message failed: ' + JSON.stringify(e));
});
```

It is also possible to read the numeric values of the keys by `require`ing
`message_keys`, which is necessary to use the array feature. For instance:

```js
// Require the keys' numeric values.
var keys = require('message_keys');

// Build a dictionary.
var dict = {}
dict[keys.LapTimes] = 42
dict[keys.LapTimes+1] = 51

// Send the object
Pebble.sendAppMessage(dict, function() {
  console.log('Message sent successfully: ' + JSON.stringify(dict));
}, function(e) {
  console.log('Message failed: ' + JSON.stringify(e));
});
```

### Type Conversion

Depending on the type of the item in the object to be sent, the C app will be
able to read the value (from the
[`Tuple.value` union](/guides/communication/sending-and-receiving-data#data-types))
according to the table below:

| JS Type | Union member |
|---------|--------------|
| String | cstring |
| Number | int32 |
| Array | data |
| Boolean | int16 |

## Receiving Messages in JS

When a message is received from the C watchapp or watchface, the `appmessage`
event is fired in the PebbleKit JS app. To receive these messages, register the
appropriate event listener:

```js
// Get AppMessage events
Pebble.addEventListener('appmessage', function(e) {
  // Get the dictionary from the message
  var dict = e.payload;

  console.log('Got message: ' + JSON.stringify(dict));
});
```

Data can be read from the dictionary by reading the value if it is present. A
suggested best practice involves first checking for the presence of each key
within the callback using an `if()` statement.

```js
if(dict['RequestData']) {
  // The RequestData key is present, read the value
  var value = dict['RequestData'];
}
```

## Using LocalStorage

In addition to the storage available on the watch itself through the ``Storage``
API, apps can take advantage of the larger storage on the connected phone
through the use of the HTML 5 [`localStorage`](http://www.w3.org/TR/webstorage/)
API. Data stored here will persist across app launches, and so can be used to
persist latest data, app settings, and other data.

PebbleKit JS `localStorage` is:

* Associated with the application UUID and cannot be shared between apps.

* Persisted when the user uninstalls and then reinstalls an app.

* Persisted when the user upgrades an app.

To store a value:

```js
var color = '#FF0066';

// Store some data
localStorage.setItem('backgroundColor', color);
```

To read the data back:

```js
var color = localStorage.getItem('backgroundColor');
```

> Note: Keys used with `localStorage` should be Strings.

## Using XMLHttpRequest

A PebbleKit JS-equipped app can access the internet and communicate with web
services or download data using the standard
[`XMLHttpRequest`](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest)
object.

To communicate with the web, create an `XMLHttpRequest` object and send it,
specifying the HTTP method and URL to be used, as well as a callback for when it
is successfully completed:

```js
var method = 'GET';
var url = 'http://example.com';

// Create the request
var request = new XMLHttpRequest();

// Specify the callback for when the request is completed
request.onload = function() {
  // The request was successfully completed!
  console.log('Got response: ' + this.responseText);
};

// Send the request
request.open(method, url);
request.send();
```

If the response is expected to be in the JSON format, data items can be easily
read after the `responseText` is converted into a JSON object:

```js
request.onload = function() {
  try {
    // Transform in to JSON
    var json = JSON.parse(this.responseText);

    // Read data
    var temperature = json.main.temp;
  } catch(err) {
    console.log('Error parsing JSON response!');
  }
};
```

## Using Geolocation

PebbleKit JS provides access to the location services provided by the phone
through the
[`navigator.geolocation`](http://dev.w3.org/geo/api/spec-source.html) object.

Declare that the app will be using the `geolocation` API by adding the
string `location` in the `capabilities` array in `package.json`:

```json
"capabilities": [ "location" ]
```

Below is an example showing how to get a single position value from the
`geolocation` API using the 
[`getCurrentPosition()`](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition) 
method:

```js
function success(pos) {
  console.log('lat= ' + pos.coords.latitude + ' lon= ' + pos.coords.longitude);
}

function error(err) {
  console.log('location error (' + err.code + '): ' + err.message);
}

/* ... */

// Choose options about the data returned
var options = {
  enableHighAccuracy: true,
  maximumAge: 10000,
  timeout: 10000
};

// Request current position
navigator.geolocation.getCurrentPosition(success, error, options);
```

Location permission is given by the user to the Pebble application for all
Pebble apps. The app should gracefully handle the `PERMISSION DENIED` error and
fallback to a default value or manual configuration when the user has denied
location access to Pebble apps.

```js
function error(err) {
  if(err.code == err.PERMISSION_DENIED) {
    console.log('Location access was denied by the user.');  
  } else {
    console.log('location error (' + err.code + '): ' + err.message);
  }
}

```

The `geolocation` API also provides a mechanism to receive callbacks when the
user's position changes to avoid the need to manually poll at regular intervals.
This is achieved by using 
[`watchPosition()`](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/watchPosition) 
in a manner similar to the example below:

```js
// An ID to store to later clear the watch
var watchId;

function success(pos) {
  console.log('Location changed!');
  console.log('lat= ' + pos.coords.latitude + ' lon= ' + pos.coords.longitude);
}

function error(err) {
  console.log('location error (' + err.code + '): ' + err.message);
}

/* ... */

var options = {
  enableHighAccuracy: true,
  maximumAge: 0,
  timeout: 5000
};

// Get location updates
watchId = navigator.geolocation.watchPosition(success, error, options);
```

To cancel the update callbacks, use the `watchId` variable received when the
watch was registered with the 
[`clearWatch()`](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/clearWatch) 
method:

```js
// Clear the watch and stop receiving updates
navigator.geolocation.clearWatch(watchId);
```

## Account Token

PebbleKit JS provides a unique account token that is associated with the Pebble
account of the current user, accessible using `Pebble.getAccountToken()`:

```js
// Get the account token
console.log('Pebble Account Token: ' + Pebble.getAccountToken());
```

The token is a string with the following properties:

* From the developer's perspective, the account token of a user is identical
  across platforms and across all the developer's watchapps.

* If the user is not logged in, the token will be an empty string ('').

## Watch Token

PebbleKit JS also provides a unique token that can be used to identify a Pebble
device. It works in a similar way to `Pebble.getAccountToken()`:

```js
// Get the watch token
console.log('Pebble Watch Token: ' + Pebble.getWatchToken());
```

The token is a string that is unique to the app and cannot be used to track
Pebble devices across applications.

<div class="alert alert--fg-white alert--bg-dark-red">

**Important**

The watch token is dependent on the watch's serial number, and therefore
**should not** be used to store sensitive user information in case the watch
changes ownership. If the app wishes to track a specific user _and_ watch, use a
combination of the watch and account token.

</div>

## Showing a Notification

A PebbleKit JS app can send a notification to the watch. This uses the standard
system notification layout with customizable `title` and `body` fields:

```js
var title = 'Update Available';
var body = 'Version 1.5 of this app is now available from the appstore!';

// Show the notification
Pebble.showSimpleNotificationOnPebble(title, body);
```

> Note: PebbleKit Android/iOS applications cannot directly invoke a
> notification, and should instead leverage the respective platform notification
> APIs. These will be passed on to Pebble unless the user has turned them off in
> the mobile app.

## Getting Watch Information

Use `Pebble.getActiveWatchInfo()` to return an object of data about the
connected Pebble.

<div class="alert alert--fg-white alert--bg-purple">

This API is currently only available for SDK 3.0 and above. Do not assume that
this function exists, so test that it is available before attempting to use it
using the code shown below.

</div>

```js
var watch = Pebble.getActiveWatchInfo ? Pebble.getActiveWatchInfo() : null;

if(watch) {
  // Information is available!

} else {
  // Not available, handle gracefully
  
}
```

> Note: If there is no active watch available, `null` will be returned.

The table below details the fields of the returned object and the information
available.

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| `platform` | String | Hardware platform name. | `aplite`, `basalt`, `chalk`. |
| `model` | String | Watch model name including color. | `pebble_black`, `pebble_grey`, `pebble_white`, `pebble_red`, `pebble_orange`, `pebble_blue`, `pebble_green`, `pebble_pink`, `pebble_steel_silver`, `pebble_steel_black`, `pebble_time_red`, `pebble_time_white`, `pebble_time_black`, `pebble_time_steel_black`, `pebble_time_steel_silver`, `pebble_time_steel_gold`, `pebble_time_round_silver_14mm`, `pebble_time_round_black_14mm`, `pebble_time_round_rose_gold_14mm`, `pebble_time_round_silver_20mm`, `pebble_time_round_black_20mm`, `qemu_platform_aplite`, `qemu_platform_basalt`, `qemu_platform_chalk`. |
| `language` | String | Language currently selected on the watch. | E.g.: `en_GB`. See the  for more information. |
| `firmware` | Object | The firmware version running on the watch. | See below for sub-fields. |
| `firmware.major` | Number | Major firmware version. | E.g.: `2` |
| `firmware.minor` | Number | Minor firmware version. | E.g.: `8` |
| `firmware.patch` | Number | Patch firmware version. | E.g.: `1` |
| `firmware.suffix` | String | Any additional firmware versioning. | E.g.: `beta3` |

## Sports API

Every Pebble watch has two built-in system watchapps called the Sports app, and
the Golf app. These apps are hidden from the launcher until launched via
PebbleKit Android or PebbleKit iOS.

Both are designed to be generic apps that display sports-related data in common
formats. The goal is to allow fitness and golf mobile apps to integrate with
Pebble to show the wearer data about their activity without needing to create
and maintain an additional app for Pebble. An example of a popular app that uses
this approach is the
[Runkeeper](http://apps.rebble.io/application/52e05bd5d8561de307000039)
app.

The Sports and Golf apps are launched, closed, and controlled by PebbleKit in an
Android or iOS app, shown by example in each section below. In both cases, the
data fields that are available to be populated are different, but data is pushed
in the same way.

## Available Data Fields

### Sports

{
  "image": "/images/guides/design-and-interaction/sports.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

The sports app displays activity duration and distance which can apply to a wide
range of sports, such as cycling or running. A configurable third field is also
available that displays pace or speed, depending on the app's preference. The
Sports API also allows the app to be configured to display the labels of each
field in metric (the default) or imperial units.

The action bar is used to prompt the user to use the Select button to pause and
resume their activity session. The companion app is responsible for listening
for these events and implementing the pause/resume operation as appropriate.

### Golf

{
  "image": "/images/guides/design-and-interaction/golf.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}

The Golf app is specialized to displaying data relevant to golf games, including
par and hole numbers, as well as front, mid, and rear yardage.

Similar to the Sports app, the action bar is used to allow appropriate feedback
to the companion app. In this case the actions are an 'up', 'ball' and 'down'
events which the companion should handle as appropriate.

## With PebbleKit Android

Once an Android app has set up
, the Sports and Golf apps
can be launched and customized as appropriate.

### Launching Sports and Golf

To launch one of the Sports API apps, simply call `startAppOnPebble()` and
supply the UUID from the `Constants` class:

```java
// Launch the Sports app
PebbleKit.startAppOnPebble(getApplicationContext(), Constants.SPORTS_UUID);
```

### Customizing Sports

To choose which unit type is used, construct and send a `PebbleDictionary`
containing the desired value from the `Constants` class. Either
`SPORTS_UNITS_IMPERIAL` or `SPORTS_UNITS_METRIC` can be used:

```java
PebbleDictionary dict = new PebbleDictionary();

// Display imperial units
dict.addUint8(Constants.SPORTS_UNITS_KEY, Constants.SPORTS_UNITS_IMPERIAL);

PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, dict);
```

To select between 'pace' or 'speed' as the label for the third field, construct
and send a `PebbleDictionary` similar to the example above. This can be done in
the same message as unit selection:

```java
PebbleDictionary dict = new PebbleDictionary();

// Display speed instead of pace
dict.addUint8(Constants.SPORTS_LABEL_KEY, Constants.SPORTS_DATA_SPEED);

PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, dict);
```

> Note: The Golf app does not feature any customizable fields.

### Displaying Data

Data about the current activity can be sent to either of the Sports API apps
using a `PebbleDictionary`. For example, to show a value for duration and
distance in the Sports app:

```java
PebbleDictionary dict = new PebbleDictionary();

// Show a value for duration and distance
dict.addString(Constants.SPORTS_TIME_KEY, "12:52");
dict.addString(Constants.SPORTS_DISTANCE_KEY, "23.8");

PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, dict);
```

Read the [`Constants`](/docs/pebblekit-android/com/getpebble/android/kit/Constants)
documentation to learn about all the available parameters that can be used for
customization.

### Handling Button Events

When a button event is generated from one of the Sports API apps, a message is
sent to the Android companion app, which can be processed using a
`PebbleDataReceiver`. For example, to listen for a change in the state of the
Sports app, search for `Constants.SPORTS_STATE_KEY` in the received
`PebbleDictionary`. The user is notified in the example below through the use of
an Android
[`Toast`](http://developer.android.com/guide/topics/ui/notifiers/toasts.html):

```java
// Create a receiver for when the Sports app state changes
PebbleDataReceiver reciever = new PebbleKit.PebbleDataReceiver(
                                                        Constants.SPORTS_UUID) {

  @Override
  public void receiveData(Context context, int id, PebbleDictionary data) {
    // Always ACKnowledge the last message to prevent timeouts
    PebbleKit.sendAckToPebble(getApplicationContext(), id);

    // Get action and display as Toast
    Long value = data.getUnsignedIntegerAsLong(Constants.SPORTS_STATE_KEY);
    if(value != null) {
      int state = value.intValue();
      String text = (state == Constants.SPORTS_STATE_PAUSED)
                                                      ? "Resumed!" : "Paused!";
      Toast.makeText(getApplicationContext(), text, Toast.LENGTH_SHORT).show();
    }
  }

};

// Register the receiver
PebbleKit.registerReceivedDataHandler(getApplicationContext(), receiver);
```

## With PebbleKit iOS

Once an iOS app has set up ,
the Sports and Golf apps can be launched and customized as appropriate. The
companion app should set itself as a delegate of `PBPebbleCentralDelegate`, and
assign a `PBWatch` property once `watchDidConnect:` has fired. This `PBWatch`
object will then be used to manipulate the Sports API apps.

Read *Becoming a Delegate* in the
 guide to see how this is
done.

### Launching Sports and Golf

To launch one of the Sports API apps, simply call `sportsAppLaunch:` or
`golfAppLaunch:` as appropriate:

```objective-c
[self.watch sportsAppLaunch:^(PBWatch * _Nonnull watch,
                                                  NSError * _Nullable error) {
  NSLog(@"Sports app was launched");
}];
```

### Customizing Sports

To choose which unit type is used, call `sportsAppSetMetric:` with the desired
`isMetric` `BOOL`:

```objective-c
BOOL isMetric = YES;

[self.watch sportsAppSetMetric:isMetric onSent:^(PBWatch * _Nonnull watch,
                                                 NSError * _Nonnull error) {
  if (!error) {
    NSLog(@"Successfully sent message.");
  } else {
    NSLog(@"Error sending message: %@", error);
  }
}];
```

To select between 'pace' or 'speed' as the label for the third field, call
`sportsAppSetLabel:` with the desired `isPace` `BOOL`:

```objective-c
BOOL isPace = YES;

[self.watch sportsAppSetLabel:isPace onSent:^(PBWatch * _Nonnull watch,
                                              NSError * _Nullable error) {
  if (!error) {
    NSLog(@"Successfully sent message.");
  } else {
    NSLog(@"Error sending message: %@", error);
  }
}];
```

> Note: The Golf app does not feature any customizable fields.

### Displaying Data

Data about the current activity can be sent to either the Sports or Golf app
using `sportsAppUpdate:` or `golfAppUpdate:`. For example, to show a value for
duration and distance in the Sports app:

```objective-c
// Construct a dictionary of data
NSDictionary *update = @{ PBSportsTimeKey: @"12:34",
                          PBSportsDistanceKey: @"6.23" };

// Send the data to the Sports app
[self.watch sportsAppUpdate:update onSent:^(PBWatch * _Nonnull watch,
                                                  NSError * _Nullable error) {
  if (!error) {
    NSLog(@"Successfully sent message.");
  } else {
    NSLog(@"Error sending message: %@", error);
  }
}];
```

Read the [`PBWatch`](/docs/pebblekit-ios/Classes/PBWatch/) documentation to learn about all
the available methods and values for customization.

### Handling Button Events

When a button event is generated from one of the Sports API apps, a message is
sent to the Android companion app, which can be processed using
`sportsAppAddReceiveUpdateHandler` and supplying a block to be run when a
message is received. For example, to listen for change in state of the Sports
app, check the value of the provided `SportsAppActivityState`:

```objective-c
// Register to get state updates from the Sports app
[self.watch sportsAppAddReceiveUpdateHandler:^BOOL(PBWatch *watch,
                                                SportsAppActivityState state) {
  // Display the new state of the watchapp
  switch (state) {
    case SportsAppActivityStateRunning:
      NSLog(@"Watchapp now running.");
      break;
    case SportsAppActivityStatePaused:
      NSLog(@"Watchapp now paused.");
      break;
    default: break;
  }

  // Finally
  return YES;
}];
```

## Communication

All Pebble watchapps and watchfaces have the ability to communicate with the
outside world through its connection to the user's phone. The PebbleKit
collection of libraries (see below) is available to facilitate this
communication between watchapps and phone apps. Examples of additional
functionality made possible through PebbleKit include, but are not limited to
apps that can:

* Display weather, news, stocks, etc.

* Communicate with other web services.

* Read and control platform APIs and features of the connected phone.

## Contents

## Communication Model

Pebble communicates with the connected phone via the Bluetooth connection, which
is the same connection that delivers notifications and other alerts in normal
use. Developers can leverage this connection to send and receive arbitrary data
using the ``AppMessage`` API.

Depending on the requirements of the app, there are three possible ways to
receive data sent from Pebble on the connected phone:

*  - A JavaScript
  environment running within the official Pebble mobile app with web,
  geolocation, and extended storage access.

*  -
  A library available to use in Android companion apps that allows them to
  interact with standard Android platform APIs.

*  -
  As above, but for iOS companion apps.

<div class="alert alert--fg-white alert--bg-dark-red">

**Important**

PebbleKit JS cannot be used in conjunction with PebbleKit Android or PebbleKit
iOS.

</div>

All messages sent from a Pebble watchapp or watchface will be delivered to the
appropriate phone app depending on the layout of the developer's project:

* If at least an `index.js` file is present in `src/pkjs/`, the message will be
  handled by PebbleKit JS.

* If there is no valid JS file present (at least an `index.js`) in the project,
  the message will be delivered to the official Pebble mobile app. If there is a
  companion app installed that has registered a listener with the same UUID as
  the watchapp, the message will be forwarded to that app via PebbleKit
  Android/iOS.

