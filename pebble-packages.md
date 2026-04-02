# Pebble Packages

> Details on how to create and use Pebble Packages

## Creating Pebble Packages

## Getting Started

To get started creating a package, run `pebble new-package some-name`.
Make `some-name` something meaningful and unique; it is what you'll be
publishing it under. You can check if it's taken on [npm](https://npmjs.org).
If you'll be including a JavaScript component, you can add `--javascript` for
a sample javascript file.

## Components of a Package

### C code

**Tip**: If you want to use an
``Event Service``,
you should use the
[pebble-events](https://www.npmjs.com/package/pebble-events) package to
handle subscriptions from multiple packages.

Packages can export C functions to their consumers, and the default package
exports `somelib_find_truth` as an example. To export a function, it
simply has to be declared in a C file in `src/c/`, and declared in a header
file in `include/`. For instance:

`src/c/somelib.c`:

```c
#include <pebble.h>
#include "somelib.h"

bool somelib_find_truth(void) {
    return true;
}
```

`include/somelib.h`:

```c
#pragma once

bool somelib_find_truth(void);
```

Notice that `include/` is already in the include path when building packages,
so include files there can be included easily. By convention, packages should
prefix their non-static functions with their name (in this case `somelib`) in
order to avoid naming conflicts. If you don't want to export a function, don't
include it in a file in `includes/`; you can instead use `src/c/`. You should
still prefix any non-static symbols with your library name to avoid conflicts.

Once the package is imported by a consumer — either an app or package — its
include files will be in a directory named for the package, and so can be
included with `#include <somelib/somelib.h>`. There is no limit on the number
or structure of files in the `include` directory.

### JavaScript code

Packages can export JavaScript code for use in PebbleKit JS. The default
JavaScript entry point for packages is always in `src/js/index.js`. However,
files can also be required directly, according to
[standard node `require` rules](https://nodejs.org/api/modules.html). In either
case they are looked up relative to their root in `src/js/`.

JavaScript code can export functions by attaching them to the global `exports`
object:

`src/js/index.js`:

```
exports.addNumbers = function(a, b) {
    return a + b;
};
```

Because JavaScript code is scoped and namespaced already, there is no need to
use any naming convention.

### Resources

Packages can include resources in the same way as apps, and those resources can
then be used by both the package and the app. They are included in
`package.json` in
[the same manner as they are for apps](/guides/app-resources/).
To avoid naming conflicts, packages should prefix their resource names with the
package name, e.g. `SOMELIB_IMAGE_LYRA`.

It's best practice to define an image resource using the package name as a
prefix on the resource `name`:

```javascript
"resources": {
  "media": [
    {
      "name": "MEDIA_PACKAGE_IMAGE_01_TINY",
      "type": "bitmap",
      "file": "images/01-tiny.png"
    },
    //...
  ]
}
```

Create a `publishedMedia` entry if you want to make the images available for
 or
.

```javascript
"resources": {
  //...
  "publishedMedia": [
    {
      "name": "MEDIA_PACKAGE_IMAGE_01",
      "glance": "MEDIA_PACKAGE_IMAGE_01_TINY",
      "timeline": {
        "tiny": "MEDIA_PACKAGE_IMAGE_01_TINY",
        "small": "MEDIA_PACKAGE_IMAGE_01_SMALL",
        "large": "MEDIA_PACKAGE_IMAGE_01_LARGE"
      }
    }
  ]
}
```

> Note: Do NOT assign an `id` when defining `publishedMedia` within packages,
see .

Resource IDs are not assigned until the package has been linked with an app and
compiled, so `RESOURCE_ID_*` constants cannot be used as constant initializers
in packages. To work around this, either assign them at runtime or reference
them directly. It is also no longer valid to try iterating over the resource id
numbers directly; you must use the name defined for you by the SDK.

### AppMessage Keys

Libraries can use AppMessage keys to reduce friction when creating a package
that needs to communicate with the phone or internet, such as a weather package.
A list of key names can be included in `package.json`, under
`pebble.messageKeys`. These keys will be allocated numbers at app build time.
We will inject them into your C code with the prefix `MESSAGE_KEY_`, e.g.
`MESSAGE_KEY_CURRENT_TEMP`.

If you want to use multiple keys as an 'array', you can specify a name like
`ELEMENTS[6]`. This will create a single key, `ELEMENTS`, but leave five empty
spaces after it, for a total of six available keys. You can then use arithmetic
to access the additional keys, such as `MESSAGE_KEY_ELEMENTS + 5`.

To use arrays in JavaScript you will need to know the actual numeric values of
your keys. They will exist as keys on an object you can access via
`require('message_keys')`. For instance:

```js
var keys = require('message_keys');
var elements = ['honesty', 'generosity', 'loyalty', 'kindness', 'laughter', 'magic'];
var dict = {}
for (var i = 0; i < 6; ++i) {
	dict[keys.ELEMENTS + i] = elements[i];
}
Pebble.sendAppMessage(dict, successCallback, failureCallback);
```

## Building and testing

Run `pebble build` to build your package. You can install it in a test project
using `pebble package install ../path/to/package`. Note that you will have to
repeat both steps when you change the package. If you try symlinking the package,
you are likely to run into problems building your app.

## Publishing

Publishing a Pebble Package requires you to have an npm account. For your
convenience, you can create or log in to one using `pebble package login`
(as distinct from `pebble login`). Having done this once, you can use
`pebble package publish` to publish a package.

Remember to document your package! It isn't any use to anyone if they can't
figure out how to use it. README.md is a good place to include some
documentation.

Adding extra metadata to package.json is also worthwhile. In particular,
it is worth specifying:

* `repository`: if your package is open source, the repo you can find it in.
  If it's hosted on github, `"username/repo-name"` works; otherwise a git
  URL.
* `license`: the license the package is licensed under. If you're not sure,
  try [choosealicense.com](http://choosealicense.com). You will also want to
  include a copy of the full license text in a file called LICENSE.
* `description`: a one-sentence description of the package.

For more details on package.json, check out
[npm's package.json documentation](https://docs.npmjs.com/getting-started/using-a-package.json).

## Using Pebble Packages

## Getting started

Using pebble packages is easy:

1. Find a package. We will have a searchable listing soon, but for now you
   can [browse the pebble-package keyword on npm](https://www.npmjs.com/browse/keyword/pebble-package).
2. Run `pebble package install pebble-somelib` to install pebble-somelib.
3. Use the package.

It is possible to use _some_ standard npm packages. However, packages that
depend on being run in node, or in a real web browser, are likely to fail. If
you install an npm package, you can use it in the usual manner, as described
below.

### C code

Packages should document their specific usage. However, in general,
for C packages you can include their headers and call them like so:

```c
#include <pebble-somelib/somelib.h>

int main() {
  somelib_do_the_thing();
}
```

All of the package's include files will be in a folder named after the package.
Packages may have any structure inside that folder, so you are advised to
read their documentation.

**Tip**: If you want to use an
``Event Service``,
you should use the
[pebble-events](https://www.npmjs.com/package/pebble-events) package to
avoid conflicting with handlers registered by packages.

### JavaScript code

JavaScript packages are used via the `require` function. In most cases you can
just `require` the package by name:

```js
var somelib = require('pebble-somelib');

somelib.doTheThing();
```

### Resources

If the package you are using has included image resources, you can reference
them directly using their `RESOURCE_ID_*` identifiers.

```c
static GBitmap *s_image_01;
s_image_01 = gbitmap_create_with_resource(RESOURCE_ID_MEDIA_PACKAGE_IMAGE_01_TINY);
```

### Published Media

If the package you are using has defined `publishedMedia` resources, you can
either reference the resources using their resource identifier (as above), or
you can create an alias within the `package.json`. The `name` you specify in
your own project can be used to reference that `publishedMedia` item for
AppGlances and Timeline pins, eg. `PUBLISHED_ID_<name>`

For example, if the package exposes the following `publishedMedia`:

```javascript
"resources": {
  //...
  "publishedMedia": [
    {
      "name": "MEDIA_PACKAGE_IMAGE_01",
      "glance": "MEDIA_PACKAGE_IMAGE_01_TINY",
      "timeline": {
        "tiny": "MEDIA_PACKAGE_IMAGE_01_TINY",
        "small": "MEDIA_PACKAGE_IMAGE_01_SMALL",
        "large": "MEDIA_PACKAGE_IMAGE_01_LARGE"
      }
    }
  ]
}
```

You could define the following `name` and `alias` with a unique `id` in your
`package.json`:

```javascript
"resources": {
  //...
  "publishedMedia": [
    {
      "name": "SHARED_IMAGE_01",
      "id": 1,
      "alias": "MEDIA_PACKAGE_IMAGE_01"
    }
  ]
}
```

You can then proceed to use that `name`, prefixed with `PUBLISHED_ID_`, within
your code:

```c
const AppGlanceSlice entry = (AppGlanceSlice) {
  .layout = {
    .icon = PUBLISHED_ID_SHARED_IMAGE_01,
    .subtitle_template_string = "message"
  }
};
```

## Pebble Packages

It is very common to want to use some piece of common functionality that
we do not provide directly in our SDK: for instance, show the weather or
swap our colors in a bitmap.

To provide this functionality, developers can create _Pebble Packages_,
which provide developers with easy ways to share their code.

## Contents

