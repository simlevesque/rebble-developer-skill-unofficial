<!-- Generated from pebble-dev/developer.rebble.io (Apache 2.0) with modifications -->

# Appstore Publishing

> How to get your app ready for going live in the Pebble appstore.

## Appstore Assets

A number of graphical assets are required when publishing an app on the
[Developer Portal](), such as a marketing
banners. The resources on this page serve to help developers give these assets a
more authentic feel.

## Example Marketing Banners

Example
[marketing banners](https://s3.amazonaws.com/developer.getpebble.com/assets/other/banner-examples.zip)
from existing apps may help provide inspiration for an app's appstore banner
design. Readable fonts, an appropriate background image, and at least one framed
screenshot are all recommended.

## Marketing Banner Templates

![](/images/guides/appstore-publishing/perspective-right.png =400x)

Use these
[blank PSD templates](https://s3.amazonaws.com/developer.getpebble.com/assets/other/banner-templates-design.zip)
to start a new app marketing banner in Photoshop from a template.

## App Screenshot Frames

Use these
[example screenshot frames](https://s3.amazonaws.com/developer.getpebble.com/assets/other/pebble-frames.zip)
for Pebble, Pebble Steel, Pebble Time, Pebble Time Steel, and Pebble Time Round
to decorate app screenshots in marketing banners and other assets.

> Note: The screenshots added to the listing itself must not be framed.

## Preparing a Submission

Once a new Pebble watchface or watchapp has been created, the
[Pebble Developer Portal]() allows the
developer to publish their creation to the appstore either publicly, or
privately. The appstore is built into the official mobile apps and means that
every new app can be found and also featured for increased exposure and
publicity.

> Note: An app can only be published privately while it is not already published
> publicly. If an app is already public, it must be unpublished before it can be
> made private.

To build the appstore listing for a new app, the following resources are
required from the developer. Some may not be required, depending on the type of
app being listed. Read

for a comparison.

## Basic Info

| Resource | Details |
|----------|---------|
| App title | Title of the app. |
| Website URL | Link to the brand or other website related to the app. |
| Source code URL | Link to the source code of the app (such as GitHub or BitBucket). |
| Support email address | An email address for support issues. If left blank, the developer's account email address will be used. |
| Category | A watchapp may be categorized depending on the kind of functionality it offers. Users can browse the appstore by these categories. |
| Icons | A large and small icons representing the app. |

## Asset Collections

An asset collection must be created for each of the platforms that the app
supports. These are used to tailor the description and screenshots shown to
users browing with a specific platform connected.

| Resource | Details |
|----------|---------|
| Description | The details and features of the app. Maximum 1600 characters. |
| Screenshots | Screenshots showing off the design and features of the app. Maximum 5 per platform in PNG, GIF, or Animated GIF format. |
| Marketing banner | Large image used at the top of a listing in some places, as well as if an app is featured on one of the main pages. |

## Releases

In addition to the visual assets in an appstore listing, the developer must
upload at least one valid release build in the form of a `.pbw` file generated
by the Pebble SDK. This is the file that will be distributed to users if they
choose to install your app.

The appstore will automatically select the appropriate version to download based
on the SDK version. This is normally the latest release, with the one exception
of the latest release built for SDK 2.x (deprecated) distributed to users
running a watch firmware less than 3.0. A release is considered valid if the
UUID is not in use and the version is greater than all previously published
releases.

## Companion Apps

If your app requires an Android or iOS companion app to function, it can be
listed here by providing the name, icon, and URL that users can use to obtain
the companion app. When a user install the watchapp, they will be prompted to
also download the companion app automatically.

## Timeline

Developers that require the user of the timeline API will need to click 'Enable
timeline' to obtain API keys used for pushing pins. See the
 guides for more information.

## Promotion

Once published, the key to growth in an app is through promotion. Aside from
users recommending the app to each other, posting on websites such as the
[Discord server](),
[Reddit](), [Bluesky](),
and [Mastodon]() can help increase exposure.

## Developer Retreat Video

Watch the presentation given by Aaron Cannon at the 2016 Developer Retreat to
learn more about preparing asset collections for the appstore.

[EMBED](//www.youtube.com/watch?v=qXmz3eINObU&index=10&list=PLDPHNsf1sb48bgS5oNr8hgFz0pL92XqtO)

## Publishing an App

When an app is ready for publishing, the `.pbw` file needs to be uploaded to the
Pebble [Developer Portal](), where a listing is
created. Depending on the type of app, different sets of additional resources
are required. These resources are then used to generate the listing pages
visible to potential users in the Pebble appstore, which is embedded within the Pebble mobile app.

You can also view the [watchfaces](http://apps.rebble.io/en_US/watchfaces)
and [watchapps](http://apps.rebble.io/en_US/watchapps) from a desktop
computer, as well as perform searches and get shareable links.

## Listing Resources

The table below gives a summary of which types of resources required by
different types of app. Use this to quickly assess how complete assets and
resources are before creating the listing.

| Resource | Watchface | Watchapp | Companion |
|----------|-----------|----------|-----------|
| Title | Yes | Yes | Yes |
| `.pbw` release build | Yes | Yes | - |
| Asset collections | Yes | Yes | Yes |
| Category | - | Yes | Yes |
| Large and small icons | - | Yes | Yes |
| Compatible platforms | - | - | Yes |
| Android or iOS companion appstore listing | - | - | Yes |

## Publishing a Watchface

1. After logging in, click 'Add a Watchface'.

2. Enter the basic details of the watchface, such as the title, source code URL,
   and support email (if different from the one associated with this developer
   account):

    ![face-title](/images/guides/appstore-publishing/face-title.png)

3. Click 'Create' to be taken to the listing page. This page details the status
   of the listing, including links to subpages, a preview of the public page,
   and any missing information preventing release.

    ![face-listing](/images/guides/appstore-publishing/face-listing.png)

4. The status now says 'Missing: At least one published release'. Click 'Add a
   release' to upload the `.pbw`, optionally adding release notes:

    ![face-release](/images/guides/appstore-publishing/face-release.png)

5. Click 'Save'. After reloading the page, make the release public by clicking
   'Publish' next to the release:

    ![face-release-publish](/images/guides/appstore-publishing/face-release-publish.png)

6. The status now says 'Missing: A complete X asset collection' for
   each X supported platform. Click 'Manage Asset Collections', then click
   'Create' for a supported platform.

7. Add a description, up to 5 screenshots, and optionally a marketing banner
   before clicking 'Create Asset Collection'.

    ![face-assets](/images/guides/appstore-publishing/face-assets.png)

8. Once all asset collections required have been created, click 'Publish' or
   'Publish Privately' to make the app available only to those viewing it
   through the direct link. Note that once made public, an app cannot then be
   made private.

9. After publishing, reload the page to get the public appstore link for social
   sharing, as well as a deep link that can be used to directly open the
   appstore in the mobile app.

## Publishing a Watchapp

1. After logging in, click 'Add a Watchapp'.

2. Enter the basic details of the watchapp, such as the title, source code URL,
   and support email (if different from the one associated with this developer
   account):

    ![app-title](/images/guides/appstore-publishing/app-title.png)

3. Select the most appropriate category for the app, depending on the features
   it provides:

    ![app-category](/images/guides/appstore-publishing/app-category.png)

4. Upload the large and small icons representing the app:

    ![app-icons](/images/guides/appstore-publishing/app-icons.png)

5. Click 'Create' to be taken to the listing page. This page details the status
   of the listing, including links to subpages, a preview of the public page,
   and any missing information preventing release.

    ![app-listing](/images/guides/appstore-publishing/app-listing.png)

6. The status now says 'Missing: At least one published release'. Click 'Add a
   release' to upload the `.pbw`, optionally adding release notes:

    ![app-release](/images/guides/appstore-publishing/app-release.png)

7. Click 'Save'. After reloading the page, make the release public by clicking
   'Publish' next to the release:

    ![face-release-publish](/images/guides/appstore-publishing/face-release-publish.png)

8. The status now says 'Missing: A complete X asset collection' for
   each X supported platform. Click 'Manage Asset Collections', then click
   'Create' for a supported platform.

9. Add a description, up to 5 screenshots, optionally up to three header images,
   and a marketing banner before clicking 'Create Asset Collection'.

    ![app-assets](/images/guides/appstore-publishing/app-assets.png)

10. Once all asset collections required have been created, click 'Publish' or
    'Publish Privately' to make the app available only to those viewing it
    through the direct link.

11. After publishing, reload the page to get the public appstore link for social
    sharing, as well as a deep link that can be used to directly open the
    appstore in the mobile app.

## Publishing a Companion App

> A companion app is one that is written for Pebble, but exists on the Google
> Play store, or the Appstore. Adding it to the Pebble appstore allows users to
> discover it from the mobile app.

1. After logging in, click 'Add a Companion App'.

2. Enter the basic details of the companion app, such as the title, source code
   URL, and support email (if different from the one associated with this
   developer account):

    ![companion-title](/images/guides/appstore-publishing/companion-title.png)

3. Select the most appropriate category for the app, depending on the features
   it provides:

    ![companion-category](/images/guides/appstore-publishing/companion-category.png)

4. Check a box beside each hardware platform that the companion app supports.
   For example, it may be a photo viewer app that does not support Aplite.

5. Upload the large and small icons representing the app:

    ![companion-icons](/images/guides/appstore-publishing/companion-icons.png)

6. Click 'Create' to be taken to the listing page. The status will now read
   'Missing: At least one iOS or Android application'. Add the companion app
   with eithr the 'Add Android Companion' or 'Add iOS Companion' buttons (or
   both!).

7. Add the companion app's small icon, the name of the other appstore app's
   name, as well as the direct link to it's location in the appropriate
   appstore. If it has been compiled with a PebbleKit 3.0, check that box:

    ![companion-link](/images/guides/appstore-publishing/companion-link.png)

8. Once the companion appstore link has been added, click 'Publish' or 'Publish
   Privately' to make the app available only to those viewing it through the
   direct link.

9. After publishing, reload the page to get the public appstore link for social
   sharing, as well as a deep link that can be used to directly open the
   appstore in the mobile app.

## iOS App Whitelisting

Pebble is part of the Made For iPhone program, a requirement that hardware
accessories must meet to interact with iOS apps. If an iOS app uses PebbleKit
iOS, it must be whitelisted **before** it can be submitted to the Apple App
Store for approval.

## Requirements

* The iOS companion app must only start communication with a Pebble watch on
  an explicit action in the UI. It cannot auto­start upon connection and it must
  stop whenever the user stops using it. Refer to the
   guide for details.

* `com.getpebble.public` is the only external accessory protocol that can be
  used by 3rd party apps. Make sure this is listed in the `Info.plist` in the
  `UISupportedExternalAccessoryProtocols` array.

* Pebble may request a build of the iOS application. If this happens, the
  developer will be supplied with UDIDs to add to the provisioning profile.
  TestFlight/HockeyApp is the recommended way to share builds with Pebble.

[Whitelist a New App >{center,bg-lightblue,fg-white}](http://pbl.io/whitelist)

After whitelisting of the new app has been confirmed, add the following
information to the "Review Notes" section of the app's Apple app submission:

<div style="text-align: center;">
  <strong>MFI PPID 126683­-0003</strong>
</div>

> Note: An iOS app does not need to be re-whitelisted every time a new update is
> released. However, Pebble reserves the right to remove an application from the
> whitelist if it appears that the app no longer meets these requirements.

## Appstore Publishing

When a developer is happy that their app is feature-complete and stable, they
can upload the compiled `.pbw` file to the
[Developer Portal]() to make it available on the
Pebble appstore for all users with compatible watches to share and enjoy.

In order to be successfully listed in the Pebble appstore the developer must:

* Provide all required assets and marketing material.

* Provide at least one `.pbw` release.

* Use a unique and valid UUID.

* Build their app with a non-beta SDK.

* Ensure their app complies with the various [legal agreements](/legal/).

Information on how to meet these requirements is given in this group of guides,
as well as details about available analytical data for published apps and
example asset material templates.

## Contents

