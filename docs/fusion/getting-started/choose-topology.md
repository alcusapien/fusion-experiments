---
title: Choose a Topology
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/getting-started/choose-topology
product: fusion-godot
version: v3-client-server
language: en-us
description: Compare Godot multiplayer architectures — shared authority, dedicated server, client-host — and weigh cost, cheat protection, and genre fit to choose fast.
timestamp: 2026-07-21
---

# Choose a Topology

## Overview

Two layered concepts shape this choice: a **mode** (the programming model) and a **topology** (the network arrangement). They are linked: pick a topology, and the mode follows from it.

- A **mode** is the programming model: who owns and writes state, where state authority lives for each object, how data flows between clients and the cloud, and whether you write prediction code. The two modes are **Shared-Authority** and **Client-Server**. They share the same connection, spawning and RPC systems but differ fundamentally in who owns game state and how authority is managed.
- A **topology** is the network arrangement: where are the different "nodes" running, if external orchestration/hosting is needed, how complex and costly it is, and which game types it fits. The three topologies for Fusion are **Shared-Authority** (matches the mode), **Dedicated Server** and **Client-Host** (there is also a fourth topology, Determinism, that is supported by another product: Photon Quantum).

The mapping between topologies, modes and **state authority** (the right to write canonical state):

<table class="table">
<thead>
    <tr>
        <th>Topology</th>
        <th>Mode</th>
        <th>State authority</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th>Shared-Authority</th>
        <td>Shared-Authority</td>
        <td>Distributed: each client is authoritative for the objects it owns</td>
    </tr>
    <tr>
        <th>Dedicated Server</th>
        <td>Client-Server</td>
        <td>Centralized on a headless server process (third-party hosting)</td>
    </tr>
    <tr>
        <th>Client-Host</th>
        <td>Client-Server</td>
        <td>Centralized on one player's machine (the master client)</td>
    </tr>
    <tr>
        <th>Determinism</th>
        <td><a href="https://dev-doc.photonengine.com/quantum/current/quantum-intro" target="_blank">Photon Quantum</a> (separate product)</td>
        <td>Symmetric: every client runs the same deterministic simulation</td>
    </tr>
</tbody>
</table>


In all Fusion topologies, the **Photon Cloud Room** caches the world state and distributes it to clients (and serves snapshots to late joiners). Authorities only write to the cloud, never directly to other clients, so player IPs are never exposed.

The **Quadrant** below organizes game genres and popular titles by topology to help guide your decision.

![](https://dev-doc.photonengine.com/docs/img/quadrant-2.jpg)

> **Info: Terminology**
> 
> **Master client**: the first player to create or join the room, designated by Photon. In Client-Server topologies, the master client will act as the **host/server** (the player or dedicated process running the authoritative simulation), will be refered to as the **simulation server**. In Shared-Authority, the master client is responsible for large-scene load signaling, and typically spawns and controls NPCs (although these can also use authority switch options).

## Modes

A **mode** is the programming model: who writes state, how data flows between clients and the cloud, and whether you write prediction code.

### Shared-Authority Mode

Mental model: "I own my objects and I write their state directly."

Every client owns and writes state for the objects it spawns. The Photon Cloud caches the world, distributes deltas and serves snapshots to late joiners. There is no single simulation bottleneck: if one client lags, only its objects are affected.

Authority can be transferred between clients using one of several ownership policies (Transaction, Player Attached, Dynamic, Master Client). No prediction or rollback code.

### Client-Server Mode

Mental model: "I suggest input, the authority decides what happens, and I predict locally."

A simulation server runs game logic and validates all state changes. Clients send input, the server executes and writes the results, and clients predict movement locally for responsive feel. Corrections apply when authoritative state arrives.

The Photon Cloud still handles state distribution, AOI filtering and late-join snapshots, so the simulation server only carries gameplay load. It writes state to one endpoint (the cloud room), saving bandwidth and CPU. IPs of the host or dedicated server are never exposed to other clients, providing DDoS and harassment protection.

## Topologies

A **topology** is the network arrangement: where the state authority lives, who pays for hosting, how reliable the host is, what game types it fits. The topology you pick determines the mode you program against.

### Shared-Authority

Uses Shared-Authority mode. No central authority: every client writes state for the objects it owns, the Photon Cloud caches and distributes it.

Best for: co-op, casual, party, social and physics sandbox games. Strongly recommended for mobile and web: no resimulation cost on weak devices, no host that can disappear when an app backgrounds.

### Dedicated Server

Uses Client-Server mode. A headless process runs the simulation on third-party infrastructure. Requires orchestration, hosting and monitoring, with costs that scale with concurrent matches.

Best for: high-profile or competitive titles, ranked shooters, esports, battle royale. The safest option: the host is not a player and cannot cheat, the simulation is reliable for the match duration. Hosting costs are usually prohibitive for free-to-play, so reserve this for titles where fairness and reputation justify the spend.

### Client-Host

Uses Client-Server mode. One player's machine acts as the simulation server. No hosting cost, no orchestration: the master client takes the host role.

Best for: friend-group sessions, small co-op or survival games, casual competitive play. Less safe (the host is a player and could in principle cheat) and less reliable (the host can disconnect, crash or background the app, ending the session or forcing host migration). Not viable on mobile or web because apps and browser tabs are unreliable as hosts.

## Choosing a Topology

<table class="table">
<thead>
    <tr>
        <th class="empty">&nbsp;</th>
        <th>Shared-Authority</th>
        <th>Dedicated Server</th>
        <th>Client-Host</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th>Mode</th>
        <td>Shared-Authority</td>
        <td>Client-Server</td>
        <td>Client-Server</td>
    </tr>
    <tr>
        <th>Best for</th>
        <td>Co-op, casual, party, sandbox, social</td>
        <td>Ranked competitive, shooters, BR, esports</td>
        <td>Friend co-op, small survival, casual competitive</td>
    </tr>
    <tr>
        <th>Cheat protection</th>
        <td>Clients write own state, but server plugins can add validation later on</td>
        <td>Server validates all state</td>
        <td>Host validates state but it is a player and could cheat</td>
    </tr>
    <tr>
        <th>Operating complexity</th>
        <td>None; Photon Cloud handles everything</td>
        <td>High; requires hosting, orchestration and monitoring</td>
        <td>None; master client takes host role</td>
    </tr>
    <tr>
        <th>Cost</th>
        <td>CCU + bandwidth only</td>
        <td>CCU + bandwidth + dedicated hosting per match</td>
        <td>CCU + bandwidth only</td>
    </tr>
    <tr>
        <th>Reliability</th>
        <td>Cloud-backed; survives any client drop</td>
        <td>Persistent for the match duration</td>
        <td>Host can disconnect, crash or background</td>
    </tr>
    <tr>
        <th>Mobile</th>
        <td>Strongly recommended</td>
        <td>Hosting cost prohibitive for F2P</td>
        <td>Not viable: apps backgrounded or killed</td>
    </tr>
    <tr>
        <th>Web</th>
        <td>Strongly recommended</td>
        <td>Hosting cost prohibitive for F2P</td>
        <td>Not viable: browser tabs throttled or backgrounded</td>
    </tr>
</tbody>
</table>


Fusion is billed on peak CCU (concurrent users), with Dedicated Server adding third-party hosting on top in case that topology is used. See [Fusion pricing](https://www.photonengine.com/fusion/pricing) for current rates.

For genres with super twitchy gameplay, where turnkey replays are useful, or for cases traditionally suited to Determinism (physics-heavy sandboxes, party brawlers, fighting games, RTS), consider <a href="https://dev-doc.photonengine.com/quantum/current/quantum-intro" target="_blank">Photon Quantum</a>. Quantum is a modern predict-rollback engine with snapshot-based late join, supporting up to 128 players, used by many representative titles like Stumble Guys, Windblown and No Rest for the Wicked. The trade-off is a tighter simulation envelope, since every client runs the full fixed-step game logic.

## Programming Comparison

The two modes differ in how you write game code. Pick a topology and the mode follows.

<table class="table">
<thead>
    <tr>
        <th class="empty">&nbsp;</th>
        <th>Shared-Authority Mode</th>
        <th>Client-Server Mode</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th>Used by</th>
        <td>Shared-Authority topology</td>
        <td>Dedicated Server, Client-Host</td>
    </tr>
    <tr>
        <th>State authority</th>
        <td>Distributed; each client owns its objects</td>
        <td>Centralized; simulation server owns everything</td>
    </tr>
    <tr>
        <th>Who writes state</th>
        <td>Owning client, directly</td>
        <td>Simulation server, after executing input</td>
    </tr>
    <tr>
        <th>Input prediction</th>
        <td>Not needed</td>
        <td>Built-in via input queue and prediction reset</td>
    </tr>
    <tr>
        <th>Physics</th>
        <td>Forecast: flexible correction based on extrapolation and smoothing</td>
        <td>Forecast</td>
    </tr>
    <tr>
        <th>Code complexity</th>
        <td>Simpler; no prediction code</td>
        <td>Higher; input packing, prediction, rollback</td>
    </tr>
</tbody>
</table>


## Which One Should I Use

If you are unsure, start with **Shared-Authority**. It is simpler to program, free of orchestration concerns and covers the majority of multiplayer game types.

Choose **Dedicated Server** when fairness, ranked integrity or competitive reputation justify hosting costs and operational overhead.

Choose **Client-Host** when you want server-authoritative gameplay without the hosting bill, and a player machine as host is acceptable for your audience (friend groups, small survival sessions, casual competitive).

## Changing Later

Switching mode (between Shared-Authority and Client-Server) is heavy: replication and RPC patterns are fundamentally different, so it involves reworking most of your networking code.

Switching topology within Client-Server (between Dedicated Server and Client-Host) is light: the API and programming patterns are identical, so the change is mostly a deployment and orchestration concern.

## Start Building

- [**Shared-Authority Quick Start**](https://dev-doc.photonengine.com/fusion-godot/v3-shared-authority/getting-started/quick-start-guide.md): Build a simple multiplayer game where each client owns its own objects. No prediction code, no server authority - recommended if you are unsure.
- [**Client-Server Quick Start**](quick-start-guide.md): Build a scene where the master client is the state authority and clients predict locally. For server-authoritative gameplay.
