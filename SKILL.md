---
name: rebble-developer
description: Rebble/Pebble watchapp developer documentation. Use when helping develop Pebble watchapps, answering questions about the Pebble C SDK, PebbleKit JS/Android/iOS, Rocky.js, app configuration, communication, UI layers, resources, publishing, or any Pebble/Rebble platform topic.
---

# Rebble Developer Skill

You are an expert in Pebble/Rebble smartwatch app development.

## Platform Overview

- **Language**: C (watchapp) + JavaScript (PebbleKit JS / Rocky.js for companion/web)
- **Targets**: Aplite (B&W), Basalt (color 144×168), Chalk (round 180×180), Diorite, Emery
- **Build tool**: `pebble` CLI; apps packaged as `.pbw`
- **Key APIs**: `Window`, `Layer`, `TextLayer`, `BitmapLayer`, `AppMessage`, `AppTimer`, `Persistent Storage`, `DataLogging`, `Timeline`, `Wakeup`
- **PebbleKit JS**: runs on phone; bridge between watch C app and internet/phone sensors
- **Rocky.js**: write watchfaces in JavaScript directly on the watch

## How to use these docs

Detailed reference files live alongside this skill. Read the relevant file when answering questions about that topic:

- **`app-resources.md`** — App Resources: Information on the many kinds of files that can be used inside Pebble apps.
- **`appstore-publishing.md`** — Appstore Publishing: How to get your app ready for going live in the Pebble appstore.
- **`best-practices.md`** — Best Practices: Information to help optimize apps and ensure a good user experience.
- **`communication.md`** — Communication: How to talk to the phone via PebbleKit with JavaScript and on Android or iOS.
- **`debugging.md`** — Debugging: How to find and fix common compilation and runtime problems in apps.
- **`design-and-interaction.md`** — Design And Interaction: How to design apps to maximise engagement, satisfaction, efficiency and overall user experience.
- **`events-and-services.md`** — Events And Services: How to get data from the onboard sensors including the accelerometer, compass, and microphone.
- **`graphics-and-animations.md`** — Graphics And Animations: Information on using animations and drawing shapes, text, and images, as well as more advanced techniques.
- **`migration.md`** — Migration: Details on how to update older apps affected by API changes.
- **`pebble-packages.md`** — Pebble Packages: Details on how to create and use Pebble Packages
- **`pebble-timeline.md`** — Pebble Timeline: How to use Pebble timeline to bring timely information to app users outside the app itself via web services.
- **`rocky-js.md`** — Rocky Js: Information on using JavaScript to create watchfaces with Rocky.js
- **`smartstraps.md`** — Smartstraps: Information on creating and talking to smartstraps.
- **`tools-and-resources.md`** — Tools And Resources: Information on all the software tools available when writing Pebble apps, as well as other resources.
- **`user-interfaces.md`** — User Interfaces: How to build app user interfaces. Includes information on events, persistent storage, background worker, wakeups and app configuration.
- **`examples.md`** — Example Apps: 29 curated example projects on GitHub
