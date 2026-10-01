---
title: Regions
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/reference/regions
product: fusion-godot
version: v3-client-server
language: en-us
description: "Photon Cloud regions explained: available region codes and hosting locations, how clients select the best region by ping, and the region allowlist per AppId."
timestamp: 2026-08-14
---

# Regions

The Photon Cloud provides low latency gaming globally by hosting servers in various regions.

Clients get the list of regions from our Photon Name Servers. Over the lifetime of a project, new regions may be added or old ones may be deprecated and removed.

With the Region Allowlist, you can define which regions should be available per AppId (see below).

## Available Regions

The Photon Cloud consists of servers in several regions, distributed across multiple hosting centers worldwide.

Each Photon Cloud region is identified by a "region code", which is a case insensitive, short string.
For example, "EU" or "eu" are both accepted and refer to the same Europe region.

The lists below indicate the location of the hosting center and the region code for each region.

### Photon Cloud for Gaming

The Photon Products Quantum, Fusion, Voice, Realtime and PUN are available to the **Photon Cloud for Gaming** in the following regions.

| Region | Hosted in | Code |
| --- | --- | --- |
| Asia | Singapore | asia |
| Australia | Sydney | au |
| Canada, East | Montreal | cae |
| Chinese Mainland ([See Instructions](#using-the-chinese-mainland-region)) | Shanghai | cn |
| Europe | Amsterdam | eu |
| Hong Kong | Hong Kong | hk |
| India | Chennai | in |
| Japan | Tokyo | jp |
| South Africa | Johannesburg | za |
| South America | Sao Paulo | sa |
| South Korea | Seoul | kr |
| Turkey | Istanbul | tr |
| United Arab Emirates | Dubai | uae |
| USA, East | Washington D.C. | us |
| USA, West | San José | usw |
| USA, South Central | Dallas | ussc |


Photon Chat is available in the following regions:

| Region | Hosted in | Code |
| --- | --- | --- |
| Asia | Singapore | asia |
| Europe | Amsterdam | eu |
| USA, East | Washington D.C. | us |
| Chinese Mainland ([See Instructions](#using-the-chinese-mainland-region)) | Shanghai | cn |


### Photon Industries Premium Cloud

The Photon Products Quantum, Fusion, Voice, Realtime and PUN are available to the **Photon Industries Premium Cloud** in the following regions.

| Region | Hosted in | Code |
| --- | --- | --- |
| Asia | Singapore | asia |
| Australia | Sydney | au |
| Europe | Amsterdam | eu |
| India | Chennai | in |
| Japan | Tokyo | jp |
| South Africa | Johannesburg | za |
| South America | Sao Paulo | sa |
| South Korea | Seoul | kr |
| USA, East | Washington D.C. | us |
| USA, West | San José | usw |


Photon Chat is available in the following regions:

| Region | Hosted in | Code |
| --- | --- | --- |
| USA, East | Washington D.C. | us |


### Regions for China for Gaming/Industries

There are special conditions for using the Photon Cloud Region Chinese Mainland:

- Access must be unlocked (<a href="#using-the-chinese-mainland-region">see below</a>)
- Photon Voice is not available in China
- 20CCU for development is free (non commercial use)
- Only a 500CCU subscription available on Photon Cloud
- Large setups need custom agreements

The Photon Products Quantum, Fusion, Realtime, PUN and Chat are available to the Photon Cloud in the following regions:

| Region | Hosted in | Code |
| --- | --- | --- |
| China Mainland | Shanghai | cn |


## Region Allowlist

The Region Allowlist enables you to customize the available regions per application directly from the dashboard. Clients using the Best Region feature, will adapt automatically.

By using using more or less regions, you balance the quality of service (roundtrip times are better, when there is a region close to players) versus the matchmaking experience (less regions mean more players per region).

To define the regions per app, [open the dashboard](https://dev-dashboard.photonengine.com/), click "Manage" for a chosen application and then click "Edit Allowlist".
You will find an input field to enter the list of allowed regions as follows:

- the available regions are listed above per SDK and sometimes separately for the Industries Circle.
- the allowlist must be a string of region codes separated by semicolons. e.g. "eu;us".
- region codes are case insensitive.
- undefined or unrecognized region codes will be ignored from the list.
- empty ("") or malformed string (e.g. ";;;") means all available regions are allowed.

Within 10 minutes of a change (confirm and save), the Name Servers will send the filtered list to connecting clients.
To avoid conflicts on the client side, connect to the "Best Region" by ping or make sure to pick a region received with the regions list.

> **Warning**
> 
> **Note**: Changing the available regions for a popular app will affect the Peak CCUs in multiple regions, which is the basis for subscription fees. Adjust the subscription plan as needed to avoid the more expensive overage fees. Reducing the subscription is perfectly fine when the switch settled down.

## How To Choose A Region

Users in the US have the lowest latency if connected to the Photon Cloud US region. Easy.

<i id="geoloadbalancing"></i>
But what if you have users from **all over the world**?

Options are..

- **a)** let the game client ping the different Photon Cloud regions and pre-select the one with the best ping, read our how to below.
- **b)** distribute client builds tied to a region, so users from different regions connect to different Photon Cloud regions or
- **c)** let the user choose a matching region from within your game`s UI.
- **d)** let all users connect to the same region if the higher latency is acceptable for your gameplay.

All Photon Cloud apps are working in all available regions without any extra charge.

[See pricing.](https://dev-www.photonengine.com/en-us/pricing)

Photon Cloud's dashboard lets you monitor the usage of your game in each region and easily upgrade or downgrade your subscription plan.

[Go to your dashboard.](https://dev-dashboard.photonengine.com/)
