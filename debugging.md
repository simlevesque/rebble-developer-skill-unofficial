# Debugging

> How to find and fix common compilation and runtime problems in apps.

## Common Runtime Errors

Whether just beginning to create apps for the Pebble platform or are creating a
more complex app, the output from app logs can be very useful in tracking down
problems with an app's code. Some examples of common problems are explored here,
including some examples to help gain familiarity with compiler output.

In contrast with syntactical errors in written code (See 
), 
there can also be problems that only occur when the app is actually run on a
Pebble. The reason for this is that perfectly valid C code can sometimes cause
improper behavior that is incompatible with the hardware.

These problems can manifest themselves as an app crashing and very little other 
information available as to what the cause was, which means that they can take 
an abnormally long time to diagnose and fix. 

One option to help track down the offending lines is to begin at the start of
app initialization and use a call to ``APP_LOG()`` to establish where execution
stops. If the message in the log call appears, then execution has at least
reached that point. Move the call further through logical execution until it
ceases to appear, as it will then be after the point where the app crashes.

## Null Pointers

The Pebble SDK uses a dynamic memory allocation model, meaning that all the SDK
objects and structures available for use by developers are allocated as and when
needed. This model has the advantage that only the immediately needed data and
objects can be kept in memory and unloaded when they are not needed, increasing
the scale and capability of apps that can be created.

In this paradigm a structure is first declared as a pointer (which may be given
an initial value of `NULL`) before being fully allocated a structure later in
the app's initialization. Therefore one of the most common problems that can
arise is that of the developer attempting to use an unallocated structure or
data item.

For example, the following code segment will cause a crash:

```c
Window *main_window;

static void init() {
  // Attempting to push an uninitialized Window!
  window_stack_push(main_window, true);
}
```

The compiler will not report this, but when run the app will crash before the
``Window`` can be displayed, with an error message sent to the console output
along the following lines:

```nc|text
[INFO    ] E ault_handling.c:77 App fault! {f23aecb8-bdb5-4d6b-b270-602a1940575e} PC: 0x8016716 LR: 0x8016713
[WARNING ]    Program Counter (PC):  0x8016716 ???
[WARNING ]      Link Register (LR):  0x8016713 ???
```

When possible, the pebble tool will tell the developer the PC (Program Counter,
or which statement is currently being executed) and LR (Link Register, address
to return to when the current function scope ends) addresses and line numbers at
the time of the crash, which may help indicate the source of the problem.

This problem can be fixed by ensuring that any data structures declared as
pointers are properly allocated using the appropriate `_create()` SDK functions
before they are used as arguments:

```c
Window *main_window;

static void init(void) {
  main_window = window_create();
  window_stack_push(main_window, true);
}
```

In situations where available heap space is limited, `_create()` functions may
return `NULL`, and the object will not be allocated. Apps can detect this
situation as follows:

```c
Window *main_window;

static void init(void) {
  main_window = window_create();

  if(main_window != NULL) {
    // Allocation was successful!
    window_stack_push(main_window, true);
  } else {
    // The Window could not be allocated! 
    // Tell the user that the operation could not be completed
    text_layer_set_text(s_output_layer, 
                                  "Unable to use this feature at the moment.");
  }
}
```

This `NULL` pointer error can also occur to any dynamically allocated structure
or variable of the developer's own creation outside the SDK. For example, a
typical dynamically allocated array will cause a crash if it is used before it
is allocated:

```c
char *array;

// Array is still NULL!
array[0] = 'a';
```

This problem can be fixed in a similar manner as before by making sure the array 
is properly allocated before it is used:

```c
char *array = (char*)malloc(8 * sizeof(char));
array[0] = 'a';
```

As mentioned above for ``window_create()``, be sure also check the 
[return value](http://pubs.opengroup.org/onlinepubs/009695399/functions/malloc.html) 
of `malloc()` to determine whether the memory allocation requested was completed
successfully:

```c
array = (char*)malloc(8 * sizeof(char));

// Check the malloc() was successful
if(array != NULL) {
  array[0] = 'a';
} else {
  // Gracefully handle the failed situation

}
```

## Outside Array Bounds

Another problem that can look OK to the compiler, but cause an error at runtime
is improper use of arrays, such as attempting to access an array index outside
the array's bounds. This can occur when a loop is set up to iterate through an
array, but the size of the array is reduced or the loop conditions change.

For example, the array iteration below will not cause a crash, but includes the
use of 'magic numbers' that can make a program brittle and prone to errors when
these numbers change:

```c
int *array;

static void init(void) {
  array = (int*)malloc(8 * sizeof(int));
  
  for(int i = 0; i < 8; i++) {
    array[i] = i * i;
  }
}
```

If the size of the allocated array is reduced, the app will crash when the 
iterative loop goes outside the array bounds:

```c
int *array;

static void init(void) {
  array = (int*)malloc(4 * sizeof(int));
  
  for(int i = 0; i < 8; i++) {
    array[i] = i * i;

    // Crash when i == 4!
  }
}
```

Since the number of loop iterations is linked to the size of the array, this
problem can be avoided by defining the size of the array in advance in one
place, and then using that value everywhere the size of the array is needed:

```c
#define ARRAY_SIZE 4

int *array;

static void init(void) {
  array = (int*)malloc(ARRAY_SIZE * sizeof(int));
  
  for(int i = 0; i < ARRAY_SIZE; i++) {
    array[i] = i * i;
  }
}
```

An alternative solution to the above is to use either the `ARRAY_LENGTH()` macro
or the `sizeof()` function to programmatically determine the size of the array
to be looped over.

## Common Syntax Errors

If a developer is relatively new to writing Pebble apps (or new to the C
language in general), there may be times when problems with an app's code will
cause compilation errors. Some types of errors with the code itself can be
detected by the compiler and this helps reduce the number that cause problems
when the code is run on Pebble.

These are problems with how app code is written, as opposed to runtime errors
(discussed in ), which may
include breaking the rules of the C language or bad practices that the compiler
is able to detect and show as an error. The following are some examples.

### Undeclared Variables

This error means that a variable that has been referenced is not available in
the current scope.

```nc|text
../src/main.c: In function 'toggle_logging':
../src/main.c:33:6: error: 'is_now_logging' undeclared (first use in this function)
   if(is_now_logging == true) {
      ^
```

In the above example, the symbol `is_now_logging` has been used in the
`toggle_logging` function, but it was not first declared there. This could be
because the declaring line has been deleted, or it was expected to be available
globally, but isn't. 

To fix this, consider where else the symbol is required. If it is needed in
other functions, move the declaration to a global scope (outside any function).
If it is needed only for this function, declare it before the offending line
(here line `33`).

### Undeclared Functions

Another variant of the above problem can occur when declaring new functions in a
code file. Due to the nature of C compilation, any function a
developer attempts to call must have been previously encountered by the compiler
in order to be visible. This can be done through 
[forward declaration](http://en.wikipedia.org/wiki/Forward_declaration).

For example, the code segment below will not compile:

```c
static void window_load(Window *window) {
  my_function();
}

void my_function() {
  // Some code here

}
```

The compiler will report this with an 'implicit declaration' error, as the app
has implied the function's existence by calling it, even though the compiler has
not seen it previously:

```nc|text
../src/function-visibility.c: In function 'window_load':
../src/function-visibility.c:6:3: error: implicit declaration of function 'my_function' [-Werror=implicit-function-declaration]
   my_function();
   ^
```

This is because the *declaration* of `my_function()` occurs after it is called
in `window_load()`. There are two options to fix this.

* Move the function declaration above any calls to it, so it has been
  encountered by the compiler:

```c
void my_function() {
  // Some code here

}

static void window_load(Window *window) {
  my_function();
}
```

* Declare the function by prototype before it is called, and provide the
  implementation later:

```c
void my_function();

static void window_load(Window *window) {
  my_function();
}

void my_function() {
  // Some code here

}
```

### Too Few Arguments

When creating functions with argument lists, sometimes the requirements of the
function change and the developer forgets to update the places where it is
called.

```nc|text
../src/main.c: In function 'select_click_handler':
../src/main.c:57:3: error: too few arguments to function 'toggle_logging'
   toggle_logging();
   ^
../src/main.c:32:13: note: declared here
 static void toggle_logging(bool will_log) {
             ^
```

The example above reports that the app tried to call the `toggle_logging()`
function in `select_click_handler()` on line 57, but did not supply enough
arguments. The argument list expected in the function definition is shown in the
second part of the output message, which here exists on line 32 and expects an
extra value of type `bool`.

To fix this, establish which version of the function is required, and update
either the calls or the declaration to match.

### Incorrect Callback Implementations

In the Pebble SDK there are many instances where the developer must implement a
function signature required for callbacks, such as for a ``WindowHandlers``
object. This means that when implementing the handler the developer-defined
callback must match the return type and argument list specified in the API
documentation.

For example, the ``WindowHandler`` callback (used for the `load` and `unload`
events in a ``Window``'s lifecycle) has the following signature:

```c
typedef void(* WindowHandler)(struct Window *window)
```

This specifies a return type of `void` and a single argument: a pointer of type
``Window``. Therefore the implemented callback should look like this:

```c
void window_load(Window *window) {
  
}
```

If the developer does not specify the correct return type and argument list in
their callback implementation, the compiler will let them know with an error
like the following, stating that the type of function passed by the developer
does not match that which is expected:

```nc|text
../src/main.c: In function 'init':
../src/main.c:82:5: error: initialization from incompatible pointer type [-Werror]
     .load = main_window_load,
     ^
../src/main.c:82:5: error: (near initialization for '(anonymous).load') [-Werror]
```

To fix this, double check that the implementation provided has the same return
type and argument list as specified in the API documentation.

## Debugging with App Logs

When apps in development do not behave as expected the developer can use app
logs to find out what is going wrong. The C SDK and PebbleKit JS can both output
messages and values to the console to allow developers to get realtime
information on the state of their app.

This guide describes how to log information from both the C and JS parts of a
watchapp or watchface and also how to read that information for debugging
purposes.

## Logging in C

The C SDK includes the ``APP_LOG()`` macro function which allows an app to
log a string containing information to the console:

```c
static int s_buffer[5];
for(int i = 0; i < 10; i++) {
  // Store loop value in array
  s_buffer[i] = i;

  APP_LOG(APP_LOG_LEVEL_DEBUG, "Loop index now %d", i);
}
```

This will result in the following output before crashing:

```nc|text
[INFO    ] D main.c:20 Loop index now 0
[INFO    ] D main.c:20 Loop index now 1
[INFO    ] D main.c:20 Loop index now 2
[INFO    ] D main.c:20 Loop index now 3
[INFO    ] D main.c:20 Loop index now 4
```

In this way it will be possible to tell the state of the loop index value if the
app encounters a problem and crashes (such as going out of array bounds in the
above example).

## Logging in JS

Information can be logged in PebbleKit JS and Pebble.js using the standard
JavaScript console, which will then be passed on to the log output view. An
example of this is to use the optional callbacks when using
`Pebble.sendAppMessage()` to know if a message was sent successfully to the
watch:

```js
console.log('Sending data to Pebble...');

Pebble.sendAppMessage({'KEY': value}, function(e) {
    console.log('Send successful!');
  }, function(e) {
    console.log('Send FAILED!');
  }
);
```

## Viewing Log Data

When viewing app logs, both the C and JS files' output are shown in the same
view.

The `pebble`  will
output any logs from C and JS files after executing the `pebble logs` command
and supplying the phone's IP address:

```text
pebble logs --phone=192.168.1.25
```

> Note: You can also use `pebble install --logs' to combine both of these
> operations into one command.

## Memory Usage Information

In addition to the log output from developer apps, statistics about memory 
usage are also included in the C app logs when an app exits:

```nc|text
[INFO] process_manager.c:289: Heap Usage for App compass-ex: Total Size <22980B> Used <164B> Still allocated <0B>
```

This piece of information reports the total heap size of the app, the amount of
memory allocated as a result of execution, and the amount of memory still
allocated when it exited. This last number can alert any forgotten deallocations
(for example, forgetting ``window_destroy()`` after ``window_create()``). A
small number such as `28B` is acceptable, provided it remains the same after
subsequent executions. If it increases after each app exit it may indicate a
memory leak.

For more information on system memory usage, checkout the
[Size presentation from the 2014 Developer Retreat](https://www.youtube.com/watch?v=8tOhdUXcSkw).

## Avoid Excessive Logging

As noted in the [API documentation](``Logging``), logging over
Bluetooth can be a power-hungry operation if an end user has the Developer
Connection enabled and is currently viewing app logs.

In addition, frequent (multiple times per second) logging can interfere with
frequent use of ``AppMessage``, as the two mechanisms share the same channel for
communication. If an app is logging sent/received AppMessage events or values
while doing this sending, it could experience slow or dropped messages. Be sure
to disable this logging when frequently sending messages.

## Debugging with GDB

As of SDK 3.10 (and [Pebble Tool](/guides/tools-and-resources/pebble-tool) 4.2),
developers can use the powerful [GDB](https://www.gnu.org/software/gdb/)
debugging tool to find and fix errors in Pebble apps while they are running in
an emulator. GDB allows the user to observe the state of the app at any point in
time, including the value of global and local variables, as well as current
function parameters and a backtrace. Strategically placing breakpoints and
observing these values can quickly reveal the source of a bug.

GDB cannot be used to debug an app running on a real watch.

## Starting GDB

To begin using GDB, start an emulator and install an app:

```text
$ pebble install --emulator basalt
```

Once the app is installed, begin using GDB:

```text
$ pebble gdb --emulator basalt
```

Once the `(gdb)` prompt appears, the app is paused by GDB for observation. To
resume execution, use the `continue` (or `c`) command. Similarly, the app can be
paused for debugging by pressing `control + c`.

```text
(gdb) c
Continuing.
```

A short list of useful commands (many more are available) can be also be
obtained from the `pebble` tool. Read the 
[*Emulator Interaction*](/guides/tools-and-resources/pebble-tool/#gdb) 
section of the  guide for more
details on this list.

```text
$ pebble gdb --help
```

## Observing App State

To see the value of variables and parameters at any point, set a breakpoint
by using the `break` (or `b`) command and specifying either a function name, or
file name with a line number. For example, the snippet below shows a typical
``TickHandler`` implementation with line numbers in comments:

```c
/* 58 */  static void tick_handler(struct tm *tick_time, TimeUnits changed) {
/* 59 */    int hours = tick_time->tm_hour;
/* 60 */    int mins = tick_time->tm_min;
/* 61 */
/* 62 */    if(hours < 10) {
/* 63 */      /* other code */
/* 64 */    }
/* 65 */  }
```

To observe the values of `hours` and `mins`, a breakpoint is set in this file at
line 61:

```text
(gdb) b main.c:61
Breakpoint 2 at 0x200204d6: file ../src/main.c, line 61.
```

> Use `info break` to see a list of all breakpoints currently registered. Each
> can be deleted with `delete n`, where `n` is the breakpoint number.

With this breakpoint set, use the `c` command to let the app continue until it
encounters the breakpoint:

```text
$ c
Continuing.
```

When execution arrives at the breakpoint, the next line will be displayed along
with the state of the function's parameters:

```text
Breakpoint 2, tick_handler (tick_time=0x20018770, units_changed=(SECOND_UNIT | MINUTE_UNIT))
    at ../src/main.c:62
62    if(hours < 10) {
```

The value of `hours` and `mins` can be found using the `info locals` command:

```text
(gdb) info locals
hours = 13
mins = 23
```

GDB can be further used here to view the state of variables using the `p`
command, such as other parts of the `tm` object beyond those being used to
assign values to `hours` and `mins`. For example, the day of the month:

```text
(gdb) p tick_time->tm_mday
$2 = 14
```

A backtrace can be generated that describes the series of function calls that
got the app to the breakpoint using the `bt` command:

```text
(gdb) bt
#0  segment_logic (this=0x200218a0) at ../src/drawable/segment.c:18
#1  0x2002033c in digit_logic (this=0x20021858) at ../src/drawable/digit.c:141
#2  0x200204c4 in pge_logic () at ../src/main.c:29
#3  0x2002101a in draw_frame_update_proc (layer=<optimized out>, ctx=<optimized out>)
    at ../src/pge/pge.c:190
#4  0x0802627c in ?? ()
#5  0x0805ecaa in ?? ()
#6  0x0801e1a6 in ?? ()
#7  0x0801e24c in app_event_loop ()
#8  0x2002108a in main () at ../src/pge/pge.c:34
#9  0x080079de in ?? ()
#10 0x00000000 in ?? ()
```

> Lines that include '??' denote a function call in the firmware. Building the
> app with `pebble build --debug` will disable some optimizations and can
> produce more readable output from GDB. However, this can increase code size
> which may break apps that are pushing the heap space limit.

## Fixing a Crash

When an app is paused for debugging, the developer can manually advance each
statement and precisely follow the path taken through the code and observe how
the state of each variable changes over time. This is very useful for tracking
down bugs caused by unusual input to functions that do not adequately check
them. For example, a `NULL` pointer.

The app code below demonstrates a common cause of an app crash, caused by a
misunderstanding of how the ``Window`` stack works. The ``TextLayer`` is created
in the `.load` handler, but this is not called until the ``Window`` is pushed
onto the stack. The attempt to set the time to the ``TextLayer`` by calling
`update_time()` before it is displayed will cause the app to crash.

```c
#include <pebble.h>

static Window *s_window;
static TextLayer *s_time_layer;

static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  s_time_layer = text_layer_create(bounds);
  text_layer_set_text(s_time_layer, "00:00");
  text_layer_set_text_alignment(s_time_layer, GTextAlignmentCenter);
  layer_add_child(window_layer, text_layer_get_layer(s_time_layer));
}

static void update_time() {
  time_t now = time(NULL);
  struct tm *tick_time = localtime(&now);

  static char s_buffer[8];
  strftime(s_buffer, sizeof(s_buffer), "%H:%M", tick_time);
  text_layer_set_text(s_time_layer, s_buffer);
}

static void init() {
  s_window = window_create();
  window_set_window_handlers(s_window, (WindowHandlers) {
    .load = window_load
  });

  update_time();

  window_stack_push(s_window, true);
}

static void deinit() {
  window_destroy(s_window);
}

int main() {
  init();
  app_event_loop();
  deinit();
}
```

Supposing the cause of this crash was not obvious from the order of execution,
GDB can be used to identify the cause of the crash with ease. It is known that
the app crashes on launch, so the first breakpoint is placed at the beginning of
`init()`. After continuing execution, the app will pause at this location:

```text
(gdb) b init
Breakpoint 2 at 0x2002010c: file ../src/main.c, line 26.
(gdb) c
Continuing.

Breakpoint 2, main () at ../src/main.c:41
41    init();
```

Using the `step` command (or Enter key), the developer can step through all the
statements that occur during app initialization until the crash is found (and
the `app_crashed` breakpoint is encountered. Alternatively, `bt full` can be
used after the crash occurs to inspect the local variables at the time of the
crash:

```text
(gdb) c
Continuing.

Breakpoint 1, 0x0804af6c in app_crashed ()
(gdb) bt full
#0  0x0804af6c in app_crashed ()
No symbol table info available.
#1  0x0800bfe2 in ?? ()
No symbol table info available.
#2  0x0800c078 in ?? ()
No symbol table info available.
#3  0x0804c306 in ?? ()
No symbol table info available.
#4  0x080104f0 in ?? ()
No symbol table info available.
#5  0x0804c5c0 in ?? ()
No symbol table info available.
#6  0x0805e6ea in text_layer_set_text ()
No symbol table info available.
#7  0x20020168 in update_time () at ../src/main.c:22
        now = 2076
        tick_time = <optimized out>
        s_buffer = "10:38\000\000"
#8  init () at ../src/main.c:31
No locals.
#9  main () at ../src/main.c:41
No locals.
#10 0x080079de in ?? ()
No symbol table info available.
#11 0x00000000 in ?? ()
No symbol table info available.
```

The last statement to be executed before the crash is a call to
`text_layer_set_text()`, which implies that one of its input variables was bad.
It is easy to determine which by printing local variable values with the `p`
command:

```text
Breakpoint 4, update_time () at ../src/main.c:22
22    text_layer_set_text(s_time_layer, s_buffer);
(gdb) p s_time_layer
$1 = (TextLayer *) 0x0 <__pbl_app_info>
```

In this case, GDB displays `0x0` (`NULL`) for the value of `s_time_layer`, which
shows it has not yet been allocated, and so will cause `text_layer_set_text()`
to crash. And thus, the source of the crash has been methodically identified. A
simple fix here is to swap `update_time()` and ``window_stack_push()`` around so
that `init()` now becomes:

```c
static void init() {
  // Create a Window
  s_window = window_create();
  window_set_window_handlers(s_window, (WindowHandlers) {
    .load = window_load
  });

  // Display the Window
  window_stack_push(s_window, true);

  // Set the time
  update_time();
}
```

In this new version of the code the ``Window`` will be pushed onto the stack,
calling its `.load` handler in the process, and the ``TextLayer`` will be
allocated and available for use once execution subsequently reaches
`update_time()`.

## Debugging

When writing apps, everyone makes mistakes. Sometimes a simple typo or omission
can lead to all kinds of mysterious behavior or crashes. The guides in this
section are aimed at trying to help developers identify and fix a variety of
issues that can arise when writing C code (compile-time) or running the compiled
app on Pebble (runtime).

There are also a few strategies outlined here, such as app logging and other
features of the `pebble`  that
can indicate the source of a problem in the vast majority of cases.

## Contents

