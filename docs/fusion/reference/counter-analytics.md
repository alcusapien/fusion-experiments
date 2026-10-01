---
title: Photon Application Analytics
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/reference/counter-analytics
product: fusion-godot
version: v3-client-server
language: en-us
description: "Track your Photon application with built-in analytics counters: CCU and more per region and timespan, with zoomable graphs in the Photon Dashboard."
timestamp: 2026-07-20
---

# Photon Application Analytics

The Photon Cloud records a set of analytics counters per application to help measure success and identify potential problems.

To access the counters, [open the Photon Dashboard](https://dev-dashboard.photonengine.com/) and click on the Analyze button for a given app.

## General

Initially, the analytics page opens with a single counter: CCU, showing the data for "All Regions" in the past week.

![Initial look of the Analytics page.](https://dev-doc.photonengine.com/docs/img/photon-app-counter_sample.png)

*Initial look of the Analytics page.*

Clicking below **Counters**, **Regions** or **Timespan** will reveal more options to customize the view. Changing the selection refreshes the view and stores it in your browser.

The Regions category only includes regions which had some user activity, so some regions might not show up even if they are available to your users.

The "All Regions" counter wraps up all regional counters, even if they are not shown individually.

Independent of the regional timezones, all values use UTC timestamps.

Within the loaded timespan, you can zoom into the data per graph: Click and drag with the mouse, doubleclick to reset.

![Several counters, one zoomed in.](https://dev-doc.photonengine.com/docs/img/photon-app-counter_sample-zoom.png)

*Several counters, one zoomed in.*

To get an overview of billable values (CCUs, Traffic, etc.) make sure to include "All Regions" and select a month as timespan.

**Free apps are restricted to the 24 hours timespan and the "All Regions" graphs.**

## Available Application Counters

## About the Data

### "All Regions"

When you choose **"all regions"** from the regions select, a new graph will show in addition to the other regions selected.

For the application counters "Msg/s per Room" ("Msg/s per Channel" for Chat apps), "Bandwidth/s per Peer" and "CCU per Room" it shows as the respective average for your app across all available regions.

Other charts render "all regions" as the topmost graph represeting the sum of the values of the same counter for all available regions.

### "Bandwidth" vs. "Traffic"

Intentionally, we differ between the **traffic** (referred to as the amount of bytes consumed by your application in the queried timespan or "volume of the pipeline") and the **bandwidth** (referred to as bytes per second your app is using or "the pipeline's diameter").

## Custom Analytics

As your audience grows you might want to take a different look at your game data.

Our **Counter API** is available with Premium Cloud, Circle and Enterprise plans and enables you to fetch the application counters from remote. Aside from the data available in our Dashboard, there are several other counters you could access this way.

If you are interested in using the Counter API, please [send a request](https://dev-dashboard.photonengine.com/support/create).
