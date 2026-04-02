# Smartstraps

> Information on creating and talking to smartstraps.

## Hardware Specification

This page describes how to make smartstrap hardware and how to interface it with
the watch.

The smartstrap connector has four contacts: two for ground, one for power and a
one-wire serial bus. The power pin is bi-directional and can be used to power
the accessory, or for the strap to charge the watch. The amount of power that
can be drawn **must not exceed** 20mA, and will of course impact the battery
life of Pebble Time.

[Download 3D models of Pebble Time and the DIY Smartstrap >{center,bg-lightblue,fg-white}](https://github.com/pebble/pebble-3d/tree/master/Pebble%20Time)

> Note: Due to movement of the user the contacts of the DIY Smartstrap may come
> undone from time to time. This should be taken into account when designing
> around the accessory and its protocol.

## Electronic Characteristics

The table below summarizes the characteristics of the accessory port connection
on the back of Pebble Time.

| Characteristic | Value |
|----------------|-------|
| Pin layout (watch face down, left to right) | Ground, data, power in/out, ground. |
| Type of data connection | Single wire, open drain serial connection with external pull-up required. |
| Data voltage level | 1.8V input logic level with tolerance for up to 5V. |
| Baud rate | Configurable between 9600 and 460800 bps. |
| Output voltage (power pin) | 3.3V (+/- 10%) |
| Maximum output current draw (power pin) | 20mA |
| Minimum charging voltage (power pin) | 5V (+/- 5%) |
| Maximum charging current draw | 500mA |

## Battery Smartstraps and Chargers

If a smartstrap is designed to charge a Pebble smartwatch, simply apply +5V to
the power pin and make sure that it can provide up to 500mA of current. This is
the maximum power draw of Pebble Time when the screen is on, the battery
charging, the radios are on, etc.

## Accessories Drawing Power

If the accessory is drawing power from the watch it will need to include a
pull-up resistor (10kΩ is recommended) so that the watch can detect that a
smartstrap is connected.

By default, the smartstrap port is turned off. The app will need to turn on the
smartstrap port to actually receive power. Refer to ``smartstrap_subscribe()``.

## Example Circuits

### Single-component Data Interface

The simplest interface to the smartstrap connector is just a pull-up resistor
between the power and the data pin of the watch. This pull-up is required so
that the watch can detect that something is connected. By default the data bus
will be at +3.3V and the watch or the smartstrap can force the bus to 0V when
sending data.

> This is the general principle of an open-drain or open-collector bus. Refer to
> an [electronic reference](https://en.wikipedia.org/wiki/Open_collector) for
> more information.

![software-serial](/images/guides/hardware/software-serial.png =500x)

On the smartstrap side, choose to use one or two pins of the chosen 
micro-controller:

* If using only one pin, the smartstrap will most likely have to implement the
  serial communication in software because most micro-controllers expect
  separated TX and RX pins. This is demonstrated in the
  [ArduinoPebbleSerial](https://github.com/pebble/arduinopebbleserial) project
  when running in 'software serial' mode.

* If using two pins, simply connect the data line to both the TX and RX pins.
  The designer should make sure that the TX pin is in high-impedance mode when
  not talking on the bus and that the serial receiver is not active when sending
  (otherwise it will receive everything sent). This is demonstrated in the
  [ArduinoPebbleSerial](https://github.com/pebble/arduinopebbleserial) project
  when running in the 'hardware serial' mode.

### Transistor-based Buffers

When connecting the smartstrap to a micro-controller where the above options are
not possible then a little bit of hardware can be used to separate the TX and RX
signals and emulate a standard serial connection.

![buffer](/images/guides/hardware/buffer.png =500x)

### A More Professional Interface

Finally, for production ready smartstraps it is recommended to use a more robust
setup that will provide voltage level conversion as well as protect the
smartstraps port from over-voltage.

The diagram below shows a suggested circuit for interfacing the smartstrap
connector (right) to a traditional two-wire serial connection (left) using a
[SN74LVC1G07](http://www.ti.com/product/sn74lvc1g07) voltage level converter as
an interface with Zener diodes for
[ESD](http://en.wikipedia.org/wiki/Electrostatic_discharge) protection.

![strap-adapter](/images/more/strap-adapter.png)

## Smartstrap Connectors

Two possible approaches are suggested below, but there are many more potential
ways to create smartstrap connectors. The easiest way involves modifying a
Pebble Time charging cable, which provides a solid magnetized connection at the
cost of wearability. By contrast, 3D printing a connector is a more comfortable
approach, but requires a high-precision 3D printer and additional construction
materials.

### Hack a Charging Cable

The first suggested method to create a smartstrap connector for prototyping
hardware is to adapt a Pebble Time charging cable using common hardware hacking
tools, such as a knife, soldering iron and jumper cables. The end result is a
component that snaps securely to the back of Pebble Time, and connects securely
to common male-to-female prototyping wires, such as those sold with Arduino
kits.

First, cut off the remainder of the cable below the end containing the magnets.
Next, use a saw or drill to split the malleable outer casing.

![](/images/guides/hardware/cable-step1.jpg =450x)

Pull the inner clear plastic part of the cable out of the outer casing, severing
the wires.

![](/images/guides/hardware/cable-step2.jpg =450x)

Use the flat blade of a screwdriver to separate the clear plastic from the front
plate containing the magnets and pogo pins.

![](/images/guides/hardware/cable-step3.jpg =450x)

Using a soldering iron, remove the flex wire attached to the inner pogo pins.
Ensure that there is no common electrical connection between any two contacts.
In its original state, the two inner pins are connected, and **must** be
separated.

Next, connect a row of three headers to the two middle pins, and one of the
magnets.

> Note: Each contact may require tinning in order to make a solid electrical
> connection.

![](/images/guides/hardware/cable-step4.jpg =450x)

The newly created connector can now be securely attached to the back of Pebble
Time.

![](/images/guides/hardware/cable-step5.jpg =450x)

With the connector in place, the accessory port pins may be easily interfaced
with using male-to-female wires.

![](/images/guides/hardware/cable-step6.jpg =450x)

### 3D Printed Connector

An alternate method of creating a compatible connector is to 3D print a
connector component and add the electrical connectivity using some additional
components listed below. To make a 3D printed smartstrap connector the following
components will be required:

![components](/images/more/strap-components.png =400x)

* 1x Silicone strap or similar, trimmed to size (See
  [*Construction*](#construction)).

* 1x Quick-release style pin or similar
  ([Amazon listing](http://www.amazon.com/1-8mm-Release-Spring-Cylindrical-Button/dp/B00Q7XE866)).

* 1x 3D printed adapter
  ([STP file](https://github.com/pebble/pebble-3d/blob/master/Pebble%20Time/Smartstrap-CAD.stp)).

* 4x Spring loaded pogo pins
  ([Mill-Max listing](https://www.mill-max.com/products/pin/0965)).

* 4x Lengths of no.24 AWG copper wire.

#### Construction

For the 3D printed adapter, it is highly recommended that the part is created
using a relatively high resolution 3D printer (100-200 microns), such as a 
[Form 1](http://formlabs.com/products/form-1-plus/) printer. Alternatively there 
are plenty of websites that 3D print parts, such as
[Shapeways](http://www.shapeways.com/). Make sure to use a **non-conductive**
material such as ABS, and print a few copies, just to be safe.

(A lower resolution printer like a Makerbot may not produce the same results.
The 3D part depends on many fine details to work properly).

For the strap, it is recommend to use a silicone strap (such as the one included
with Pebble Time or a white Pebble Classic), and cut it down. Put the strap
along the left and right side of the lug holes, as shown below.

> Ensure the strap is cut after receiving the 3D printed part so that it can be
> used as a reference.

![cutaway](/images/more/strap-measurements.png =300x)

#### Assembly

Slide the quick-release pin into the customized silicone strap.

![strap-insert-pin](/images/more/strap-insert-pin.png =300x)

Slide the strap and pin into the 3D printed adapter.

![strap-into-adapter](/images/more/strap-into-adapter.png =300x)

Insert the copper wire pieces into the back of the 3D printed adapter.

![strap-insert-wires](/images/more/strap-insert-wires.png =300x)

Place the pogo pins into their respective holes, then slide them into place away
from the strap.

![strap-insert-pogo-pins](/images/more/strap-insert-pogo-pins.png =300x)

## Protocol Specification

This page describes the protocol used for communication with Pebble smartstraps,
intended to gracefully handle bus contention and allow two-way communication.
The protocol is error-free and unreliable, meaning datagrams either arrive
intact or not at all.

## Communication Model

Most smartstrap communication follows a master-slave model with the watch being
the master and the smartstrap being the slave. This means that the watch will
never receive data from the smartstrap which it isn't expecting. The one
exception to the master/slave model is the notification mechanism, which allows
the smartstrap to notify the watch of an event it may need to respond to. This
is roughly equivalent to an interrupt line on an I2C device, but for smartstraps
is done over the single data line (marked 'Data' on diagrams).

## Assumptions

The following are assumed to be universally true for the purposes of the
smartstrap protocol:

1. Data is sent in [little-endian](https://en.wikipedia.org/wiki/Endianness)
   byte order.
2. A byte is defined as an octet (8 bits).
3. Any undefined values should be treated as reserved and should not be used.

## Sample Implementation

Pebble provides complete working sample implementations for common
micro-controllers platforms such as the [Teensy](https://www.pjrc.com/teensy/)
and [Arduino Uno](https://www.arduino.cc/en/Main/arduinoBoardUno).
This means that when using one of these platforms, it is not necessary to
understand all of the details of the low level communications and thus can rely
on the provided library.

[Arduino Pebble Serial Sample Library >{center,bg-dark-red,fg-white}](https://github.com/pebble/ArduinoPebbleSerial/)

Read [*Talking to Pebble*](/guides/smartstraps/talking-to-pebble) for
instructions on how to use this library to connect to Pebble.

## Protocol Layers

The smartstrap protocol is split up into 3 layers as shown in the table below:

| Layer | Function |
|-------|----------|
| [Profile Layer](#profile-layer) | Determines the format of the high-level message being transmitted. |
| [Link Layer](#link-layer) | Provides framing and error detection to allow transmission of datagrams between the watch and the smartstrap. |
| [Physical Layer](#physical-layer) | Transmits raw bits over the electrical connection. |

### Physical Layer

The physical layer defines the hardware-level protocol that is used to send bits
over the single data wire. In the case of the smartstrap interface, there is a
single data line, with the two endpoints using open-drain outputs with an
external pull-up resistor on the smartstrap side. Frames are transmitted over
this data line as half-duplex asynchronous serial (UART).

The UART configuration is 8-N-1: eight data bits, no
[parity bit](https://en.wikipedia.org/wiki/Parity_bit), and one
[stop bit](https://en.wikipedia.org/wiki/Asynchronous_serial_communication). The
default baud rate is 9600 bps (bits per second), but can be changed by the
higher protocol layers. The smallest data unit in a frame is a byte.

**Auto-detection**

The physical layer is responsible for providing the smartstrap auto-detection
mechanism. Smartstraps are required to have a pull-up resistor on the data line
which is always active and not dependent on any initialization (i.e. activating
internal pull-ups on microcontroller pins). The value of the pull-up resistor
must be low enough that adding a 30kΩ pull-down resistor to the data line will
leave the line at >=1.26V (10kΩ is generally recommended). Before communication
with the smartstrap is attempted, the watch will check to see if the pull-up is
present. If (and only if) it is, the connection will proceed.

**Break Character**

A break character is defined by the physical layer and used by the
[link layer](#link-layer) for the notification mechanism. The physical layer for
smartstraps defines a break character as a `0x00` byte with an extra low bit
before the stop bit. For example, in 8-N-1 UART, this means the start bit is
followed by nine low (`0`) bits and a stop bit.

### Link Layer

The link layer is responsible for transmitting frames between the smartstrap and
the watch. The goal of the link layer is to detect transmission errors such as
flipped bits (including those caused by bus contention) and to provide a framing
mechanism to the upper layers.

#### Frame Format

The structure of the link layer frame is shown below. The fields are transmitted
from top to bottom.

> Note: This does not include the delimiting flags or bytes inserted for
> transparency as described in the [encoding](#encoding) section below.

| Field Name | Length |
|------------|--------|
| `version` | 1 byte |
| `flags` | 4 bytes |
| `profile` | 2 bytes |
| `payload` | Variable length (may be empty) |
| `checksum` | 1 byte |

**Version**

The `version` field contains the current version of the link layer of the
smartstrap protocol.

| Version | Description |
|---------|-------------|
| 1 | Initial release version. |

**Flags**

The `flags` field is four bytes in length and is made up of the following
fields.

| Bit(s) | Name | Description |
|--------|------|-------------|
| 0 | `IsRead` | `0`: The smartstrap should not reply to this frame.</br>`1`: This is a read and the smartstrap should reply.</br></br>This field field should only be set by the watch. The smartstrap should always set this field to `0`. |
| 1 | `IsMaster` | `0`: This frame was sent by the smartstrap.</br>`1`: This frame was sent by the watch. |
| 2 | `IsNotification` | `0`: This is not a notification frame.</br>`1`: This frame was sent by the smartstrap as part of the notification.</br></br>This field should only be set by the smartstrap. The watch should always set this field to `0`. |
| 3-31 | `Reserved` | All reserved bits should be set to `0`. |

**Profile**

The `profile` field determines the specific profile used for communication. The
details of each of the profiles are defined in the 
[Profile Layer](#profile-layer) section.

| Number | Value | Name |
|--------|-------|------|
| 1 | `0x0001` | Link Control Profile |
| 2 | `0x0002` | Raw Data Profile |
| 3 | `0x0003` | Generic Service Profile |

**Payload**

The `payload` field contains the profile layer data. The link layer considers an
empty frame as being valid, and there is no maximum length.

**Checksum**

The checksum is an 8-bit 
[CRC](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) with a polynomial 
of `x^8 + x^5 + x^3 + x^2 + x + 1`. This is **not** the typical CRC-8 
polynomial.

An example implementation of this CRC can be found in the
[ArduinoPebbleSerial library](https://github.com/pebble/ArduinoPebbleSerial/blob/master/utility/crc.c).

**Frame Length**

The length of a frame is defined as the number of bytes in the `flags`,
`profile`, `checksum`, and `payload` fields of the link layer frame. This does
not include the delimiting flags or the bytes inserted for transparency as part
of [encoding](#encoding). The smallest valid frame is eight bytes in size: one
byte for the version, four for the flags, two for the profile type, one for the
checksum, and zero for the empty payload. The protocol is designed to work
without the need for fixed buffers.

#### Encoding

A delimiting flag (i.e.: a byte with value of `0x7e`) is used to delimit frames
(indicating the beginning or end of a frame). The byte stream is examined on a
byte-by-byte basis for this flag value. Each frame begins and ends with the
delimiting flag, although only one delimiting flag is required between two
frames. Two consecutive delimiting flags constitute an empty frame, which is
silently discarded by the link layer and is not considered an error.

**Transparency**

A byte-stuffing procedure is used to escape `0x7e` bytes in the frame payload.
After checksum computation, the link layer of the transmitter within the
smartstrap encodes the entire frame between the two delimiting flags. Any
occurrence of `0x7e` or `0x7d` in the frame is escaped with a proceeding `0x7d`
byte and logically-XORed with `0x20`. For example:

* The byte `0x7d` when escaped is encoded as `0x7d 0x5d`.

* The byte `0x7e` when escaped is encoded as `0x7d 0x5e`.

On reception, prior to checksum computation, decoding is performed on the byte
stream before passing the data to the profile layer.

#### Example Frames

The images below show some example frames of the smartstrap protocol under two
example conditions, including the calculated checksum. Click them to see more
detail.

**Raw Profile Read Request**

<a href="/assets/images/guides/hardware/raw-read.png"><img src="/assets/images/guides/hardware/raw-read.png"></img></a>

**Raw Profile Response**

<a href="/assets/images/guides/hardware/raw-response.png"><img src="/assets/images/guides/hardware/raw-response.png"></img></a>

#### Invalid Frames

Frames which are too short, have invalid transparency bytes, or encounter a UART
error (such as an invalid stop bit) are silently discarded.

#### Timeout

If the watch does not receive a response to a message sent with the `IsRead`
flag set (a value of `1`) within a certain period of time, a timeout will occur.
The amount of time before a timeout occurs is always measured by the watch from
the time it starts to send the message to the time it completely reads the
response.

The amount of time it takes to send a frame (based on the baud rate, maximum
size of the data after encoding, and efficiency of the physical layer UART
implementation) should be taken into account when determining timeout values.
The value itself can be set with ``smartstrap_set_timeout()``, up to a maximum
value of 1000ms.

> Note: In order to avoid bus contention and potentially corrupting other
> frames, the smartstrap should not respond after the timeout has elapsed. Any frame
> received after a timeout has occurred will be dropped by the watch.

### Notification Mechanism

There are many use-cases where the smartstrap will need to notify the watch of
some event. For example, smartstraps may contain input devices which will be
used to control the watch. These smartstraps require a low-latency mechanism for
notifying the watch upon receiving user-input. The primary goal of this
mechanism is to keep the code on the smartstrap as simple as possible.

In order to notify the watch, the smartstrap can send a break character
(detailed under [*Physical Layer*](#physical-layer)) to the watch. Notifications
are handled on a per-profile granularity, so the frame immediately following
a break character, called the context frame, is required in order to communicate
which profile is responsible for handling the notification. The context
frame must have the `IsNotification` flag (detailed under [*Flags*](#flags)) set
and have an empty payload. How the watch responds to notifications is dependent
on the profile.

### Profile Layer

The profile layer defines the format of the payload. Exactly which profile a
frame belongs to is determined by the `profile` field in the link layer header.
Each profile type defines three things: a set of requirements, the format of
all messages of that type, and notification handling.

#### Link Control Profile

The link control profile is used to establish and manage the connection with the
smartstrap. It must be fully implemented by all smartstraps in order to be
compatible with the smartstrap protocol as a whole. Any invalid responses or
timeouts encountered as part of link control profile communication will cause
the smartstrap to be marked as disconnected and powered off unless otherwise
specified. The auto-detection mechanism will cause the connection establishment
procedure to restart after some time has passed.

**Requirements**

| Name | Value |
|------|-------|
| Notifications Allowed? | No |
| Message Timeout | 100ms. |
| Maximum Payload Length | 6 bytes. |

**Payload Format**

| Field | Length (bytes) |
|-------|----------------|
| Version | 1 |
| Type | 1 |
| Data | Variable length (may be empty) |

**Version**

The Version field contains the current version of link control profile.

| Version | Notes |
|---------|-------|
| `1`  | Initial release version. |

**Type**

| Type | Value | Data |
|------|-------|-------------|
| Status | `0x01` | Watch: *Empty*. Smartstrap: Status (see below). |
| Profiles | `0x02` | Watch: *Empty*. Smartstrap: Supported profiles (see below). |
| Baud rate | `0x03` | Watch: *Empty*. Smartstrap: Baud rate (see below). |

**Status**

This message type is used to poll the status of the smartstrap and allow it to
request a change to the parameters of the connection. The smartstrap should send
one of the following status values in its response.

| Value | Meaning | Description |
|-------|---------|-------------|
| `0x00` | OK | This is a simple acknowledgement that the smartstrap is still alive and is not requesting any changes to the connection parameters. |
| `0x01` | Baud rate | The smartstrap would like to change the baud rate for the connection. The watch should follow-up with a baud rate message to request the new baud rate. |
| `0x02` | Disconnect | The smartstrap would like the watch to mark it as disconnected. |

A status message is sent by the watch at a regular interval. If a timeout
occurs, the watch will retry after an interval of time. If an invalid response
is received or the retry also hits a timeout, the smartstrap will be marked as
disconnected.

**Profiles**

This message is sent to determine which profiles the smartstrap supports. The
smartstrap should respond with a series of two byte words representing all the
[profiles](#profile) which it supports. There are the following requirements for
the response.

* All smartstraps must support the link control profile and should not include
  it in the response.

* All smartstraps must support at least one profile other than the link control
  profile, such as the raw data profile.

* If more than one profile is supported, they should be reported in consecutive
  bytes in any order.

> Note: Any profiles which are not supported by the watch are silently ignored.

**Baud Rate**

This message type is used to allow the smartstrap to request a change in the
baud rate. The smartstrap should respond with a pre-defined value corresponding
to the preferred baud rate as listed below. Any unlisted value is invalid. In
order to conserve power on the watch, the baud rate should be set as high as
possible to keep time spent alive and communicating to a minimum.

| Value | Baud Rate (bits per second) |
|-------|-----------------------------|
| `0x00` | 9600 |
| `0x01` | 14400 |
| `0x02` | 19200 |
| `0x03` | 28800 |
| `0x04` | 38400 |
| `0x05` | 57600 |
| `0x06` | 62500 |
| `0x07` | 115200 |
| `0x08` | 125000 |
| `0x09` | 230400 |
| `0x0A` | 250000 |
| `0x0B` | 460800 |

Upon receiving the response from the smartstrap, the watch will change its baud
rate and then send another status message. If the smartstrap does not respond to
the status message at the new baud rate, it is treated as being disconnected.
The watch will revert back to the default baud rate of 9600, and the connection
establishment will start over. The default baud rate (9600) must always be the
lowest baud rate supported by the smartstrap.

**Notification Handling**

Notifications are not supported for this profile.

#### Raw Data Service

The raw data profile provides a mechanism for exchanging raw data with the
smartstrap without any additional overhead. It should be used for any messages
which do not fit into one of the other profiles.

**Requirements**

| Name | Value |
|------|-------|
| Notifications Allowed? | Yes |
| Message Timeout | 100ms from sending to complete reception of the response. |
| Maximum Payload Length | Not defined. |

**Payload Format**

There is no defined message format for the raw data profile. The payload may
contain any number of bytes (including being empty).

| Field | Value |
|-------|-------|
| `data` | Variable length (may be empty). |

**Notification Handling**

The handling of notifications is allowed, but not specifically defined for the
raw data profile.

#### Generic Service Profile

The generic service profile is heavily inspired by (but not identical to) the
[GATT bluetooth profile](https://developer.bluetooth.org/gatt/Pages/default.aspx).
It allows the watch to write to and read from pre-defined attributes on the
smartstrap. Similar attributes are grouped together into services. These
attributes can be either read or written to, where a read requires the
smartstrap to respond with the data from the requested attribute, and a write
requiring the smartstrap to set the value of the attribute to the value provided
by the watch. All writes require the smartstrap to send a response to
acknowledge that it received the request. The data type and size varies by
attribute.

**Requirements**

| Name | Value |
|------|-------|
| Notifications Allowed? | Yes |
| Message Timeout | Not defined. A maximum of 1000ms is supported. |
| Maximum Payload Length | Not defined. |

**Payload Format**

| Field | Length (bytes) |
|-------|----------------|
| Version | 1 |
| Service ID | 2 |
| Attribute ID | 2 |
| Type | 1 |
| Error Code | 1 |
| Length | 2 |
| Data | Variable length (may be empty) |

**Version**

The Version field contains the current version of generic service profile.

| Version | Notes |
|---------|-------|
| `1`  | Initial release version. |

**Service ID**

The two byte identifier of the service as defined in the Supported Services and
Attributes section below. The available Service IDs are blocked off into five
ranges:

| Service ID Range (Inclusive) | Service Type | Description |
|------------------------------|--------------|-------------|
| `0x0000` - `0x00FF` | Reserved | These services are treated as invalid by the watch and should never be used by a smartstrap. The `0x0000` service is currently aliased to the raw data profile by the SDK. |
| `0x0100` - `0x0FFF` | Restricted | These services are handled internally in the firmware of the watch and are not available to apps. Smartstraps may (and in the case of the management service, must) support services in this range. |
| `0x1000` - `0x1FFF` | Experimentation | These services are for pre-release product experimentation and development and should NOT be used in a commercial product. When a smartstrap is going to be sold commercially, the manufacturer should contact Pebble to request a Service ID in the "Commerical" range. |
| `0x2000` - `0x7FFF` | Spec-Defined | These services are defined below under [*Supported Services and Attributes*](#supported-services-and-attributes), and any smartstrap which implements them must strictly follow the spec to ensure compatibility. |
| `0x8000` - `0xFFFF` | Commercial | These services are allocated by Pebble to smartstrap manufacturers who will define their own attributes. |

**Attribute ID**

The two byte identifier of the attribute as defined in the Supported Services
and Attributes section below.

**Type**

One byte representing the type of message being transmitted. When the smartstrap
replies, it should preserve this field from the request.

| Value | Type | Meaning |
|-------|------|---------|
| `0` | Read | This is a read request with the watch not sending any data, but expecting to get data back from the smartstrap. |
| `1` | Write | This is a write request with the watch sending data to the smartstrap, but not expected to get any data back. |
| `2` | WriteRead | This is a write+read request which consists of the watch writing data to the smartstrap **and** expecting to get some data back in response. |

**Error Code**

The error code is set by the smartstrap to indicate the result of the previous
request and must be one of the following values.

| Value | Name | Meaning |
|-------|------|---------|
| `0` | OK | The read or write request has been fulfilled successfully. The watch should always use this value when making a request. |
| `1` | Not Supported | The requested attribute is not supported by the smartstrap. |

**Length**

The length of the data in bytes.

#### Supported Services and Attributes

**Management Service (Service ID: `0x0101`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Service Discovery | Read | uint16[1..10] | A list of Service ID values for all of the services supported by the smartstrap. A maximum of 10 (inclusive) services may be reported. In order to support the generic service profile, the management service must be supported and should not be reported in the response. |
| `0x0002` | Notification Info | Read | uint16_t[2] | If a read is performed by the watch after the smartstrap issues a notification, the response data should be the IDs of the service and attribute which generated the notification. |

**Pebble Control Service (Service ID: `0x0102`)**

> Note: This service is not yet implemented.

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Launch App | Read | uint8[16] | The UUID of the app to launch. |
| `0x0002` | Button Event | Read | uint8[2] | This message allows the smartstrap trigger button events on the watch. The smartstrap should send two bytes: the button being acted on and the click type. The possible values are defined below:</br></br>Buttons Values:</br>`0x00`: No Button</br>`0x01`: Back button</br>`0x02`: Up button</br>`0x03`: Select button</br>`0x04`: Down button</br></br>Click Types:</br>`0x00`: No Event</br>`0x01`: Single click</br>`0x02`: Double click</br>`0x03`: Long click</br></br>The smartstrap can specify a button value of `0x00` and a click type of `0x00` to indicate no pending button events. Any other use of the `0x00` values is invalid. |

**Location and Navigation Service (Service ID: `0x2001`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Location | Read | sint32[2] | The current longitude and latitude in degrees with a precision of 1/10^7. The latitude comes before the longitude in the data. For example, Pebble HQ is at (37.4400662, -122.1583808), which would be specified as {374400662, -1221583808}. |
| `0x0002` | Location Accuracy | Read | uint16 | The accuracy of the location in meters. |
| `0x0003` | Speed | Read | uint16 | The current speed in meters per second with a precision of 1/100. For example, 1.5 m/s would be specified as 150. |
| `0x0101` | GPS Satellites | Read | uint8 | The number of GPS satellites (typically reported via NMEA. |
| `0x0102` | GPS Fix Quality | Read | uint8 | The quality of the GPS fix (reported via NMEA). The possible values are listed in the [NMEA specification](http://www.gpsinformation.org/dale/nmea.htm#GGA). |

**Heart Rate Service (Service ID: `0x2002`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Measurement Read | uint8 | The current heart rate in beats per minute. |

**Battery Service (Service ID: `0x2003`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Charge Level | Read | uint8 | The percentage of charge left in the smartstrap battery (between 0 and 100). |
| `0x0002` | Capacity | Read | uint16 | The total capacity of the smartstrap battery in mAh when fully charged. |

**Notification Handling**

When a notification is received for this profile, a "Notification Info" message
should be sent as described above.

## Talking To Pebble

In order to communicate successfully with Pebble, the smartstrap hardware must
correctly implement the smartstrap protocol as defined in 
.

## Arduino Library

For developers prototyping with some of the most common Arduino boards
(based on the AVR ATmega 32U4, 2560, 328, or 328P chips), the simplest way of
doing this is to use the
[ArduinoPebbleSerial](https://github.com/pebble/arduinopebbleserial) library.
This open-source reference implementation takes care of the smartstrap protocol
and allows easy communication with the Pebble accessory port.

Download the library as a .zip file. In the Arduino IDE, go to 'Sketch' ->
'Include Library' -> 'Add .ZIP LIbrary...'. Choose the library .zip file. This
will import the library into Arduino and add the appropriate include statement
at the top of the sketch:

```c++
#include <ArduinoPebbleSerial.h>
```

After including the ArduinoPebbleSerial library, begin the sketch with the
standard template functions (these may already exist):

```c++
void setup() {

}

void loop() {

}
```

## Connecting to Pebble

Declare the buffer to be used for transferring data (of type `uint8_t`), and its
maximum length. This should be large enough for managing the largest possible
request from the watch, but not so large that there is no memory left for the
rest of the program:

> Note: The buffer **must** be at least 6 bytes in length to handle internal
> protocol messages.

```c++
// The buffer for transferring data
static uint8_t s_data_buffer[256];
```

Define which service IDs the strap will support. See

for details on which values may be used here. An example service ID and
attribute ID both of value `0x1001` are shown below:

```c
static const uint16_t s_service_ids[] = {(uint16_t)0x1001};
static const uint16_t s_attr_ids[] = {(uint16_t)0x1001};
```

The last decision to be made before connection is which baud rate will be used.
This will be the speed of the connection, chosen as one of the available baud
rates from the `Baud` `enum`:

```c
typedef enum {
  Baud9600,
  Baud14400,
  Baud19200,
  Baud28800,
  Baud38400,
  Baud57600,
  Baud62500,
  Baud115200,
  Baud125000,
  Baud230400,
  Baud250000,
  Baud460800,
} Baud;
```

This should be chosen as the highest rate supported by the board used, to allow
the watch to save power by sleeping as much as possible. The recommended value
is `Baud57600` for most Arduino-like boards.

### Hardware Serial

If using the hardware UART for the chosen board (the `Serial` library),
initialize the ArduinoPebbleSerial library in the `setup()` function to prepare
for connection:

```c++
// Setup the Pebble smartstrap connection
ArduinoPebbleSerial::begin_hardware(s_data_buffer, sizeof(s_data_buffer),
                                                  Baud57600, s_service_ids, 1);
```

### Software Serial

Alternatively, software serial emulation can be used for any pin on the chosen
board that 
[supports interrupts](https://www.arduino.cc/en/Reference/AttachInterrupt). In
this case, initialize the library in the following manner, where `pin` is the
compatible pin number. For example, using Arduino Uno pin D8, specify a value of
`8`. As with `begin_hardware()`, the baud rate and supported service IDs must
also be provided here:

```c++
int pin = 8;

// Setup the Pebble smartstrap connection using one wire software serial
ArduinoPebbleSerial::begin_software(pin, s_data_buffer, sizeof(s_data_buffer),
                                                   Baud57600, s_service_ids, 1);
```

## Checking Connection Status

Once the smartstrap has been physically connected to the watch and the
connection has been established, calling `ArduinoPebbleSerial::is_connected()`
will allow the program to check the status of the connection, and detect
disconnection on the smartstrap side. This can be indicated to the wearer using
an LED, for example:

```c++
if(ArduinoPebbleSerial::is_connected()) {
  // Connection is valid, turn LED on
  digitalWrite(7, HIGH);
} else {
  // Connection is not valid, turn LED off
  digitalWrite(7, LOW);
}
```

## Processing Commands

In each iteration of the `loop()` function, the program must allow the library
to process any bytes which have been received over the serial connection using
`ArduinoPebbleSerial::feed()`. This function will return `true` if a complete
frame has been received, and set the values of the parameters to inform the
program of which type of frame was received:

```c++
size_t length;
RequestType type;
uint16_t service_id;
uint16_t attribute_id;

// Check to see if a frame was received, and for which service and attribute
if(ArduinoPebbleSerial::feed(&service_id, &attribute_id, &length, &type)) {
  // We got a frame!
  if((service_id == 0) && (attribute_id == 0)) {
    // This is a raw data service frame
    // Null-terminate and display what was received in the Arduino terminal
    s_data_buffer[min(length_read, sizeof(s_data_buffer))] = `\0`;
    Serial.println(s_data_buffer);
  } else {
    // This may be one of our service IDs, check it.
    if(service_id == s_service_ids[0] && attribute_id == s_attr_ids[0]) {
      // This frame is for our supported service!
      s_data_buffer[min(length_read, sizeof(s_data_buffer))] = `\0`;
      Serial.print("Write to service ID: ");
      Serial.print(service_id);
      Serial.print(" Attribute ID: ");
      Serial.print(attribute_id);
      Serial.print(": ");
      Serial.println(s_data_buffer);
    }
  }
}
```

If the watch is requesting data, the library also allows the Arduino to respond
back using `ArduinoPebbleSerial::write()`. This function accepts parameters to
tell the connected watch which service and attribute is responding to the read
request, as well is whether or not the read was successful:

> Note: A write to the watch **must** occur during processing for a
> `RequestType` of `RequestTypeRead` or `RequestTypeWriteRead`.

```c++
if(type == RequestTypeRead || type == RequestTypeWriteRead) {
  // The watch is requesting data, send a friendly response
  char *msg = "Hello, Pebble";

  // Clear the buffer
  memset(s_data_buffer, 0, sizeof(s_data_buffer));

  // Write the response into the buffer
  snprintf((char*)s_data_buffer, sizeof(s_data_buffer), "%s", msg);

  // Send the data to the watch for this service and attribute
  ArduinoPebbleSerial::write(true, s_data_buffer, strlen((char*)s_data_buffer)+1);
}
```

## Notifying the Watch

To save power, it is strongly encouraged to design the communication scheme in
such a way that avoids needing the watch to constantly query the status of the
smartstrap, allowing it to sleep. To aid in this effort, the ArduinoPebbleSerial
library includes the `ArduinoPebbleSerial::notify()` function to cause the
watchapp to receive a ``SmartstrapNotifyHandler``.

For example, to notify the watch once a second:

```c++
// The last time the watch was notified
static unsigned long s_last_notif_time = 0;

void loop() {

  /* other code */

  // Notify the watch every second
  if (millis() - s_last_notif_time  > 1000) {
    // Send notification with our implemented serviceID  and attribute ID
    ArduinoPebbleSerial::notify(s_service_ids[0], s_attr_ids[0]);

    // Record the time of this notification
    s_last_notif_time = millis();
  }
}
```

## Talking To Smartstraps

To talk to a connected smartstrap, the ``Smartstrap`` API is used to establish a
connection and exchange arbitrary data. The exchange protocol is specified in
 and most of
it is abstracted by the SDK. This also includes handling of the
.

Read  to learn how to use an
example library for popular Arduino microcontrollers to implement the smartstrap
side of the protocol.

> Note: Apps running on multiple hardware platforms that may or may not include
> a smartstrap connector should use the `PBL_SMARTSTRAP` compile-time define (as
> well as checking API return values) to gracefully handle when it is not
> available.

## Services and Attributes

### Generic Service Profile

The Pebble smartstrap protocol uses the concept of 'services' and 'attributes'
to organize the exchange of data between the watch and the smartstrap. Services
are identified by a 16-bit number. Some of these service identifiers have a
specific meaning; developers should read 

for a complete list of reserved service IDs and ranges of service IDs that can
be used for experimentation.

Attributes are also identified by a 16-bit number. The meaning of attribute
values is specific to the service of that attribute. The smartstrap protocol
defines the list of attributes for some services, but developers are free to
define their own list of attributes in their own services.

This abstraction supports read and write operations on any attribute as well as
sending notifications from the strap when an attribute value changes. This is
called the Generic Service Profile and is the recommended way to exchange data
with smartstraps.

### Raw Data Service

Developers can also choose to use the Raw Data Service to minimize the overhead
associated with transmitting data. To use this profile a Pebble developer will
use the same APIs described in this guide with the service ID and attribute ID
set to ``SMARTSTRAP_RAW_DATA_SERVICE_ID`` and
``SMARTSTRAP_RAW_DATA_ATTRIBUTE_ID`` SDK constants respectively.

## Manipulating Attributes

The ``Smartstrap`` API uses the ``SmartstrapAttribute`` type as a proxy for an
attribute on the smartstrap. It includes the service ID of the attribute, the ID
of the attribute itself, as well as a data buffer that is used to store the
latest read or written value of the attribute.

Before you can read or write an attribute, you need to initialize a
`SmartstrapAttribute` that will be used as a proxy for the attribute on the
smartstrap. The first step developers should take is to decide upon and define
their services and attributes:

```c
// Define constants for your service ID, attribute ID 
// and buffer size of your attribute.
static const SmartstrapServiceId s_service_id = 0x1001;
static const SmartstrapAttributeId s_attribute_id = 0x0001;
static const int s_buffer_length = 64;
```

Then, define the attribute globally:

```c
// Declare an attribute pointer
static SmartstrapAttribute *s_attribute;
```

Lastly create the attribute during app initialization, allocating its buffer:

```c
// Create the attribute, and allocate a buffer for its data
s_attribute = smartstrap_attribute_create(s_service_id, s_attribute_id, 
                                                            s_buffer_length);
```

Later on, APIs such as ``smartstrap_attribute_get_service_id()`` and
``smartstrap_attribute_get_attribute_id()`` can be used to confirm these values
for any ``SmartstrapAttribute`` created previously. This is useful if an app
deals with more than one service or attribute.

Attributes can also be destroyed when an app is exiting or no longer requires
them by using ``smartstrap_attribute_destroy()``:

```c
// Destroy this attribute
smartstrap_attribute_destroy(s_attribute);
```

## Connecting to a Smartstrap

The first thing a smartstrap-enabled app should do is call
``smartstrap_subscribe()`` to register the handler functions (described below)
that will be called when smartstrap-related events occur. Such events can be one
of four types.

The ``SmartstrapServiceAvailabilityHandler`` handler, used when a smartstrap
reports that a service is available, or has become unavailable.

```c
static void strap_availability_handler(SmartstrapServiceId service_id,
                                       bool is_available) {
  // A service's availability has changed
  APP_LOG(APP_LOG_LEVEL_INFO, "Service %d is %s available",
                                (int)service_id, is_available ? "now" : "NOT");
}
```

See below under [*Writing Data*](#writing-data) and 
[*Reading Data*](#reading-data) for explanations of the other callback types.

With all four of these handlers in place, the subscription to the associated
events can be registered.

```c
// Subscribe to the smartstrap events
smartstrap_subscribe((SmartstrapHandlers) {
  .availability_did_change = strap_availability_handler,
  .did_read = strap_read_handler,
  .did_write = strap_write_handler,
  .notified = strap_notify_handler
});
```

As with the other [`Event Services`](``Event Service``), the subscription can be
removed at any time:

```c
// Stop getting callbacks
smartstrap_unsubscribe();
```

The availability of a service can be queried at any time:

```c
if(smartstrap_service_is_available(s_service_id)) {
  // Our service is available!

} else {
  // Our service is not currently available, handle gracefully
  APP_LOG(APP_LOG_LEVEL_ERROR, "Service %d is not available.", (int)s_service_id);
}
```

## Writing Data

The smartstrap communication model (detailed under 
)
uses the master-slave principle. This one-way relationship means that Pebble can
request data from the smartstrap at any time, but the smartstrap cannot.
However, the smartstrap may notify the watch that data is waiting to be read so
that the watch can read that data at the next opportunity.

To send data to a smartstrap an app must call
``smartstrap_attribute_begin_write()`` which will return a buffer to write into.
When the app is done preparing the data to be sent in the buffer, it calls
``smartstrap_attribute_end_write()`` to actually send the data.

```c
// Pointer to the attribute buffer
size_t buff_size;
uint8_t *buffer;

// Begin the write request, getting the buffer and its length
smartstrap_attribute_begin_write(attribute, &buffer, &buff_size);

// Store the data to be written to this attribute
snprintf((char*)buffer, buff_size, "Hello, smartstrap!");

// End the write request, and send the data, not expecting a response
smartstrap_attribute_end_write(attribute, buff_size, false);
```

> Another message cannot be sent until the strap responds (a `did_write`
> callback for Write requests, or `did_read` for Read/Write+Read requests) or
> the timeout expires. Doing so will cause the API to return
> ``SmartstrapResultBusy``. Read 
>  for
> more information on smartstrap timeouts.

The ``SmartstrapWriteHandler`` will be called when the smartstrap has
acknowledged the write operation (if using the Raw Data Service, there
is no acknowledgement and the callback will be called when Pebble is done
sending the frame to the smartstrap). If a read is requested (with the
`request_read` parameter of ``smartstrap_attribute_end_write()``) then the read
callback will also be called when the smartstrap sends the attribute value.

```c
static void strap_write_handler(SmartstrapAttribute *attribute,
                                SmartstrapResult result) {
  // A write operation has been attempted
  if(result != SmartstrapResultOk) {
    // Handle the failure
    APP_LOG(APP_LOG_LEVEL_ERROR, "Smartstrap error occured: %s",
                                          smartstrap_result_to_string(result));
  }
}
```

If a timeout occurs on a non-raw-data write request (with the `request_read`
parameter set to `false`), ``SmartstrapResultTimeOut`` will be passed to the
`did_write` handler on the watch side.

## Reading Data

The simplest way to trigger a read request is to call
``smartstrap_attribute_read()``. Another way to trigger a read is to set the
`request_read` parameter of ``smartstrap_attribute_end_write()`` to `true`. In
both cases, the response will be received asynchronously and the
``SmartstrapReadHandler`` will be called when it is received.

```c
static void strap_read_handler(SmartstrapAttribute *attribute,
                               SmartstrapResult result, const uint8_t *data,
                               size_t length) {
  if(result == SmartstrapResultOk) {
    // Data has been read into the data buffer provided
    APP_LOG(APP_LOG_LEVEL_INFO, "Smartstrap sent: %s", (char*)data);
  } else {
    // Some error has occured
    APP_LOG(APP_LOG_LEVEL_ERROR, "Error in read handler: %d", (int)result);
  }
}

static void read_attribute() {
  SmartstrapResult result = smartstrap_attribute_read(attribute);
  if(result != SmartstrapResultOk) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "Error reading attribute: %s",
                                        smartstrap_result_to_string(result));
  }
}
```

> Note: ``smartstrap_attribute_begin_write()`` may not be called within a
> `did_read` handler (``SmartstrapResultBusy`` will be returned).

Similar to write requests, if a timeout occurs when making a read request the
`did_read` handler will be called with ``SmartstrapResultTimeOut`` passed in the
`result` parameter.

## Receiving Notifications

To save as much power as possible, the notification mechanism can be used by the
smartstrap to alert the watch when there is data that requires processing. When
this happens, the ``SmartstrapNotifyHandler`` handler is called with the
appropriate attribute provided. Developers can use this mechanism to allow the
watch to sleep until it is time to read data from the smartstrap, or simply as a
messsaging mechanism.

```c
static void strap_notify_handler(SmartstrapAttribute *attribute) {
  // The smartstrap has emitted a notification for this attribute
  APP_LOG(APP_LOG_LEVEL_INFO, "Attribute with ID %d sent notification",
                        (int)smartstrap_attribute_get_attribute_id(attribute));

  // Some data is ready, let's read it
  smartstrap_attribute_read(attribute);
}
```

## Callbacks For Each Type of Request

There are a few different scenarios that involve the ``SmartstrapReadHandler``
and ``SmartstrapWriteHandler``, where the callbacks to these
``SmartstrapHandlers`` will change depending on the type of request made by the
watch.

| Request Type | Callback Sequence |
|--------------|-------------------|
| Read only | `did_write` when the request is sent. `did_read` when the response arrives or an error (e.g.: a timeout) occurs. |
| Write+Read request | `did_write` when the request is sent. `did_read` when the response arrives or an error (e.g.: a timeout) occurs. |
| Write (Raw Data Service) | `did_write` when the request is sent. |
| Write (any other service) | `did_write` when the write request is acknowledged by the smartstrap. |

For Write requests only, `did_write` will be called when the attribute is ready
for another request, and for Reads/Write+Read requests `did_read` will be called
when the attribute is ready for another request.

## Timeouts

Read requests and write requests to an attribute expect a response from the
smartstrap and will generate a timeout error if the strap does not respond
before the expiry of the timeout.

The maximum timeout value supported is 1000ms, with the default value
``SMARTSTRAP_TIMEOUT_DEFAULT`` of 250ms. A smaller or larger value can be
specified by the developer:

```c
// Set a timeout of 500ms
smartstrap_set_timeout(500);
```

## Smartstrap Results

When data is sent to the smartstrap, one of several results is possible. These
are returned by various API functions (such as ``smartstrap_attribute_read()``),
and are enumerated as follows:

| Result | Value | Description |
|--------|-------|-------------|
| `SmartstrapResultOk` | `0` | No error occured. |
| `SmartstrapResultInvalidArgs` | `1` | The arguments provided were invalid. |
| `SmartstrapResultNotPresent` | `2` | The Smartstrap port is not present on this watch. |
| `SmartstrapResultBusy` | `3` | The connection is currently busy. For example, this can happen if the watch is waiting for a response from the smartstrap. |
| `SmartstrapResultServiceUnavailable` | `4` | Either a smartstrap is not connected or the connected smartstrap does not support the specified service. |
| `SmartstrapResultAttributeUnsupported` | `5` | The smartstrap reported that it does not support the requested attribute. |
| `SmartstrapResultTimeOut` | `6` | A timeout occured during the request. |

The function shown below returns a human-readable string for each value, useful
for debugging.

```c
static char* smartstrap_result_to_string(SmartstrapResult result) {
  switch(result) {
    case SmartstrapResultOk:
      return "SmartstrapResultOk";
    case SmartstrapResultInvalidArgs:
      return "SmartstrapResultInvalidArgs";
    case SmartstrapResultNotPresent:
      return "SmartstrapResultNotPresent";
    case SmartstrapResultBusy:
      return "SmartstrapResultBusy";
    case SmartstrapResultServiceUnavailable:
      return "SmartstrapResultServiceUnavailable";
    case SmartstrapResultAttributeUnsupported:
      return "SmartstrapResultAttributeUnsupported";
    case SmartstrapResultTimeOut:
      return "SmartstrapResultTimeOut";
    default:
      return "Not a SmartstrapResult value!";
  }
}
```

## Smartstraps

The smart accessory port on the back of Pebble Time, Pebble Time Steel, and
Pebble Time Round makes it possible to create accessories with electronics
built-in to improve the capabilities of the watch itself. Wrist-mounted pieces
of hardware that interface with a Pebble watch are called smartstraps and can
potentially host many electronic components from LEDs, to temperature sensors,
or even external batteries to boost battery life.

This section of the developer guides details everything a developer
should need to produce a smartstrap for Pebble; from 3D CAD diagrams, to
electrical characteristics, to software API and protocol specification details.

## Contents

## Availablility

The ``Smartstrap`` API is available on the following platforms and firmwares.

| Platform | Model | Firmware |
|----------|-------|----------|
| Basalt | Pebble Time/Pebble Time Steel | 3.4+ |
| Chalk | Pebble Time Round | 3.6+ |

Apps that use smartstraps but run on incompatible platforms can use compile-time
defines to provide alternative behavior in this case. Read
 for more information
on supporting multiple platforms with differing capabilities.

## Video Introduction

Watch the video below for a detailed introduction to the Smartstrap API by Brian
Gomberg (Firmware team), given at the 
[PebbleSF Meetup](http://www.meetup.com/PebbleSF/).

[EMBED](//www.youtube.com/watch?v=uB9r2lw7Bt8)

