---
title: Glossary
url: https://dev-doc.photonengine.com/fusion-godot/v3-client-server/reference/glossary
product: fusion-godot
version: v3-client-server
language: en-us
description: "Plain-language definitions of every Photon term: room, lobby, CCU, master client, actor number, interest groups, regions, and more."
timestamp: 2026-08-19
---

# Glossary

### ACK

A (low level) command to acknowledge reliable commands. Used for Reliable UDP (RUDP).

___


### Actor

Players in a room are also called "Actors".
An actor has an ActorNumber, also referred to as *actorId*, *player number* and *player id*, valid in the [room](#room).
Values for the ActorNumber start at 1 in each room and are not re-used (when a client leaves and another joins).

___


### Application

Applications contain the game logic, written in C\# and run by the Photon Core.
They extend the abstract class Application for this. The Photon Cloud makes use of [Virtual Applications](#virtual-application).

___


### Application ID (AppId)

In the Photon Cloud, the Application ID (AppId) is the main identifier for a Title and its [Virtual Application](#virtual-application).  
You can find your AppId prominently in the [Dashboard](#dashboard). It is needed for most of our demos.

___


### Application Version (AppVersion)

The Application Version goes along with the Application ID to define the [Virtual Application](#virtual-application).
It is used to separate builds and players in matchmaking into compatible multiplayer builds.
There is a limit of how many an AppId can have in parallel.

___


### Binaries Folder

In the [Photon Server SDK](#photon-server-sdk), the binaries folders contain platform-specific builds of the Photon Core.
They are prefixed with "bin\_" and in the "deploy" folder.

___


### Build script

A batch file or MsBuild project to compile and copy applications for their deployment.
Takes care of getting a clean build for deployment.

___


### Business Logic

A game's logic, which runs on top of Photon Core.
This "layer" handles operations and events.

___


### Channel

Can refer to either low-level channels in the RUDP protocol or to the "conversation" channels in [Photon Chat](#chat).

___


### Chat

Photon Chat is a lightweight service for communication between users.
Users can join channels, send private messages and make use of a user status which is available for friends.
Chat uses a separate connection and is independent of rooms.

___


### Client

Applications that connect to a server are called clients.
In Photon's case, they initiate a connection to a server, which enables them to message other clients.
Photon clients are programmed with a client API, also referred to as client library.

___


### Cluster

A cluster consists of a [Master Server](#master-server) and several [Game Servers](#game-server). Each cluster is separated from any others.
Often a [Region](#region) has only one cluster.

___


### Command

Commands are used on the eNet protocol layer to transport your data or establish / shutdown connections.
You won't write these, but we will explain them for your background knowledge.

___


### Concurrent User (CCU)

Concurrent Users for a game are all clients that have a connection to a server at the same time.
The CCU count is the basis for the prices in of Photon Cloud subscriptions.

Don't mix this up with Daily Active Users (DAU) or Monthly Active Users (MAU).
Users of a game play only a small amount of time per day and much less per month (just think about all the days you couldn't play for some reason).

___


### Connect

Before clients can call operations on Photon, they need to connect and establish a connection.

___


### Custom Operation

Any operation that is not in the client API or new to the server side.

___


### Custom Properties

In Photon, you can set Custom Properties for Rooms and Players.
In both cases, the custom properties are provided as Hashtable and the key must be of type String but can have any (serializable) value.

Custom Player Properties are deleted when players abandon a game.

___


### Dashboard

The dashboard aggregates counter data and generates graphs for monitoring purposes.
Photon applications can be managed from their respective dashboard.

[Realtime Apps Dashboard](https://dev-dashboard.photonengine.com/)

___


### Deploy Folder

In the Server SDK, this folder contains everything that is needed to run Photon.
Namely: the binaries-folders and compiled Applications.

___


### Device

In general: a mobile.
Or any other system to runs your client application.

___


### Disconnect

Ends a connection between client and server.
Happens when a player wants to exit the client-app or there is a timeout.
Also, the server logic could disconnect players.

___


### EmptyRoomTTL

Amount of time in milliseconds that Photon servers should wait before disposing an empty room.
A room is considered empty as long as there is no active actors joined to it.
So the room deletion timer starts when the last active actors leaves.
When an actor joins or rejoins the room when it's empty the countdown is reset.

By default, maximum value allowed is:

- 300.000ms (5 minutes) on Photon Cloud
- 60.000ms (1minute) on Photon Server

___


### Event

Events are asynchronous messages sent to clients.
They can be triggered by operations (as side effect) or raised (as main purpose of an operation) and are identified by an event code.
The origin is identified as [ActorNumber](#actor).

___


### EvCode

Short for event code.
Identifies the type of events and which information (and types) the event contains.

___


### Exit Games, Photon and Photon Engine

“Exit Games” is the company behind Photon technology, services, and products. Founded in 2003, the company specializes in providing multiplayer Software as a Service (SaaS) solutions. Externally, “Photon” is used as the overarching product family brand, while “Photon Engine” highlights Photon’s engine-like capabilities.

The company is management-owned and led by its founders, employing a product-first, engineer-focused strategy. Traditional marketing and sales functions do not exist within the organization, emphasizing a technology-driven approach and direct engagement with users.

The name “Exit Games” is used primarily in legal or contractual contexts. The company’s official website is photonengine.com. As of 2025, Exit Games has a globally distributed team of over 60 fulltime professionals. The headquarters are located in Hamburg, Germany, with distribution managed by Exit Games Inc. in the United States.

___


### Fusion

Fusion is our state of the art state transfer networking solution. It aims to support more than 100 players in a session even for competitive games.

___


### Game

Depending on context, "game" refers to a title/application or a round/match between a few players.
We try to stick to "Title" for the first meaning and use ["Room"](#room) for the second.

___


### Game Server

Game Servers handle the actual in-game communication for the clients.
They only communicate with the [Master Server](#master-server), so they neither provide friends lists nor room lists.

___


### GameVersion

The GameVersion is a string any game can set.
In the Photon Cloud it can be useful to separate users of incompatible versions into separate [Virtual Applications](#virtual-application).

___


### Latency

Time between request and ACK.
Might differ on client and server. Measured as RoundTrip Time (RTT).

___


### Hive

Refers to the Hive Application in the [Photon Server SDK](#photon-server-sdk).
A basic business logic to get you started.

___


### LoadBalancingClient

This class the fondation for many of our SDKS, including Photon Client SDK
It contains logic to wrap Photon's load balancing workflow in which a Master Server knows several Game Servers.
When joining a room, clients switch to a specific Game Server.

___


### Lobby

A lobby is a virtual container or "list" of rooms. You can use multiple lobbies and there are different types of lobbies, too.
E.g. not every lobby type will send the room-list to clients.

By default, players can't communicate in the lobby. In fact, they never know another client is also in the lobby.
A client can only be in a lobby, a room or neither.

___


### Log Files

The [Photon Server](#photon-server-sdk) is designed to run as service and does not have extensive GUI.

There are two sets of log files used instead: Applications write into "deploy\\log".
Photon Core writes into "deploy\\bin\_\*\\log".

___


### Matchmaking

The process of finding a game or match.

___


### Master Client

Master Client is a "special" [client](#client) per [room](#room).
In absence of custom server code, it can be made responsible for handling logic that should only be executed by one client in a room (e.g. starting a match when everyone is ready).
A new Master Client is automatically assigned when the former leaves.
Unless explicitly set, the Master Client is the actor (player) with the least actor number among the active actors.

___


### Master Server

The Master Server handles the matchmaking for a region or cluster. It distributes rooms across a range of [Game Servers](#game-server).
It is important that clients look up their Master Server via the [Name Server](#name-server).

___


### Messages

Messages are in general anything that updates someone else or does something on the server.

- **In Photon terms:** All Operations, Responses and Events are messages.
- **In PUN terms:** All RPCs, synchronization updates, Instantiate calls, changing Custom Properties (including playerName) are messages.

Sending an Event (or RPC) to all other clients counts as one message per player in that room: One send, the others receive.

PUN is special, because it tries to aggregate updates by `OnPhotonSerializeView`.
If possible, the updates of several objects are aggregated into one message.
Also, the observe mode affects this: "Unreliable On Change" stops sending anything when the GO doesn't move between updates.
In worst case one object can cause 10 messages per second per player. That's not common however.

___


### Multiplayer Topologies (aka Topologies)

“Multiplayer Topologies” refer to the architectural models used in synchronous multiplayer games to synchronize the game state across multiple players in real time. Photon Fusion and Photon Quantum support four primary approaches:

“Dedicated Server” (Fusion in dedicated server mode)

- A headless (no UI) game instance runs on dedicated hardware or cloud infrastructure.
- The server is authoritative: it processes all game logic, updates clients, and corrects inconsistencies.
- Advantages include a single source of game state and stronger cheat prevention.
- Disadvantages include higher infrastructure costs and the need for dependable hosting.
- Direct connections between the clients and the server are typical. Relay is only used in rare cases.

“Client Hosted” (Fusion in host mode)

- Functionally similar to the Dedicated Server model, but one player’s device acts as the server.
- This setup eliminates the need for a dedicated server, reducing infrastructure overhead.
- However, if the host experiences issues (e.g., connectivity or cheating), the entire session is affected.
- Direct connections between the clients and a host are not always possible. This mode is not recommended for mobile clients.

“Shared Mode” (Fusion in shared mode)

- In this mode there is no central instance to run the simulation. Instead, the server coordinates updates from the clients.
- The authority over game objects gets distributed across clients, which handle the simulation work.
- The server aggregates and distributes the global game state.
- This design reduces server load but requires careful coordination and synchronization since clients are partially authoritative.
- Recommended for applications with mobile or web clients.

“Deterministic” (Quantum)

- Each client runs an identical, deterministic simulation using the same logic, settings, and initial conditions.
- Only input data is exchanged among clients, significantly reducing bandwidth.
- The server manages input distribution and timing.
- Photon Quantum provides a comprehensive deterministic engine with built-in physics, pathfinding, AI bots, and more.

___


### Messages Limit

We limit the messages (updates) per room and per second for two reasons:

- Things break when you send too many updates. There is no fixed cap though. This depends on traffic, devices, etc.
- Make sure everyone has a fixed slice of our shared servers.

The messages per room and second are shown in the [Dashboard](#dashboard).

___


### Name Server

The Name Server provides a list of available regions to clients and handles their authentication requests.
When the client selected a region, the Name Server provides the [Master Server](#master-server) address for it.
There are multiple, loadbalanced Name Servers.

___


### Operation

Another word for RPC functions on the Photon server side.
Clients use operations to do anything on the server and even to send events to others.

___


### OpCode

Short for operation code.
A byte-value that's used to trigger operations on the server side.
Clients get operation responses with opCodes to identify the type of action for the returned values.

___


### Peer

This term refers to one side of a connection.
The [client](#client) has a peer and the server is the remote peer for the [client](#client).

___


### Photon Circle (aka Circle)

“Photon Circle” is a dedicated support offering designed to help developers successfully integrate and maintain Photon’s multiplayer services. It provides specialized resources, such as documentation, tutorials, and best practices, that streamline the development process. Members receive priority assistance from Photon’s technical support team, ensuring quick resolutions to challenges.

Photon Circle also fosters a community where developers can exchange insights, troubleshooting tips, and innovative ideas. By actively engaging with its members, Photon Circle helps shape the platform’s continuous improvement and feature evolution.

It is offered in two editions: (i) “Photon Gaming Circle” for gaming studios, and (ii) “Photon Industries Circle” for non-gaming organizations. Each edition provides specialized expertise, resources, and priority support tailored to its domain’s unique scenarios.

___


### Photon Cloud

“Photon Cloud” is a real-time, cloud-based multiplayer service offered by Exit Games. It provides a global server infrastructure which is automatically scaled to provide low-latency connections for all Photon Products.

Developers can integrate its matchmaking, synchronous multiplayer, voice, and chat features into their games using official Photon Product SDKs. By handling server infrastructure and network complexities, it allows developers to focus on creating engaging gameplay experiences.

Photon Cloud is provided on three cloud types: (i) Photon Public Cloud, (ii) Photon Premium Cloud, and (iii) Photon Enterprise Cloud. Each type supports different numbers of concurrent users (CCU) and service level agreements (SLAs).

Depending on the use-case and scenario (gaming or non-gaming) there are two Photon Cloud options: (i) Photon Cloud for Gaming and (ii) Photon Cloud for Industries. Different regions are available for these options (gaming or non-gaming).

___


### Photon Cloud Region (aka Region)

Client devices connect to the Photon Cloud via specific Regions, which correspond to specific physical hosting centers.

Each region is identified by a region-name, a region-code (an abbreviation used internally for connection management), and a region-city (the geographical location of the data center), ensuring precise routing and location tracking.

By selecting a suitable region for a Photon client session, developers can optimize latency and performance for players in different parts of the world.

The available regions depend on the (i) Photon product used, and (ii) the scenario (Photon Cloud for Gaming or for Industries).
Example: Photon Chat, which is not latency critical, is available in fewer regions than the other Photon products such as Quantum or Fusion. The same applies to non-gaming applications that run in the Photon Cloud for Industries.

___


### Photon Control

The Photon administration tool of the Photon Server SDK.
Start the PhotonControl.exe to get a tray-bar menu and easily manage Photon's services.

___


### Photon Core

The C++ core of Photon. It handles connections and the eNet protocol for you.

___


### Photon Products (aka Products)

“Photon Products” is a range of networking products created by Exit Games to power real-time multiplayer games and experiences across multiple platforms. Most important platforms supported are Mobile, VR/XR, PC, Console, Web.

There are two categories of products: synchronous multiplayer and communication. (i) Synchronous multiplayer products are: Photon Quantum, Photon Fusion, Photon Realtime and PUN (Photon Unity Networking). (ii) Communication products are: Photon Voice and Photon Chat. Those deliver real-time voice and text-based communication channels within multiplayer projects. You may omit the leading “Photon” if the context is clear, e.g. use Quantum instead of Photon Quantum.

The further product, Photon Server, allows you to host Photon Cloud yourself and develop Server Plugins. It is only available for Photon Industries customers.

The Photon product Bolt was discontinued in 2023 and replaced by Fusion. Fusion is superior in terms of features, performance and usability.

Together, these products provide developers with scalable, cross-platform solutions for building, hosting, and managing online game services as well as non-gaming (so called “industries”) services.

___


### Photon SDKs (aka SDK) and Versions

“Photon SDKs” are downloadable Software Development Kits for Photon products. They follow a versioning scheme of major.minor.build. Major versions are referenced by shortcuts, for example, “Fusion 2” to denote all Fusion 2.x releases. The same convention applies to other Photon products and SDKs.

In documentation tables, abbreviations (e.g., “F2” for Fusion 2, “Q2” for Quantum 2, “RT” for Realtime) may be used.

___


### Photon Server SDK

The Photon Server SDK contains the tools to run and build your own Photon Server instances on basically any Windows Machine.
[Read more](https://dev-doc.photonengine.com/server).

___


### PhotonServer.config

This is the configuration file for the Photon Core.
It configures IPs, applications and performance settings.
Formerly it was called PhotonSocketServer.xml and for a short time PhotonSocketServer.config.

___


### Photon Unity Networking (PUN)

Photon Unity Networking is a C# client package for Unity.
It uses Photon's lower-level features to re-implement Unity's built-in networking in a more advanced form.
Many of the lower-level Photon features are covered by PUN. You rarely have to worry about a [ReturnCode](#returncode) or [Commands](#command), e.g.
It is now in Long Term Support mode and won't get major feature updates anymore. New projects should use Fusion or Quantum on the client side.

___


### PlayerTTL

Amount of time in milliseconds that an actor can remain inactive inside the room before it gets removed.
An actor becomes inactive when it leaves the room temporarily or gets disconnected unexpectedly.

A value of -1 means inactive actors do not timeout.

___


### Policy File

The Policy Application runs on Photon to send the "crossdomain.xml".
Webplayer platforms like Unity Webplayer, Flash and Silverlight request authorization before they contact a server.

___


### Quantum

Quantum is our state of the art predict rollback networking solution.

___


### Region

See [Photon Cloud Region](#photon-cloud-region-aka-region).

___


### Reliable

Reliable commands will reach the other side or lead to a timeout disconnect.
They are sequenced per channel and dispatching will stall when a reliable command is temporarily missing.

___


### ReturnCode

Primary result of every operation in form of a byte-value.
Can be checked if an operation was done successfully (RC\_OK == 0) or which error happened.

___


### Room

Players meet in rooms to play a match or communicate.
Communication outside of rooms is not possible.
Any client can only be active in one room.

![Photon Room Core Concept](https://dev-doc.photonengine.com/docs/img/photon-rooms-core-concept.png)

*Photon Room Core Concept*

Photon rooms have these properties and methods:

- create and join rooms by name
- set [Custom Properties](#custom-properties) for the room and players
- define maximum amount of players
- hidden (do not show in lobby) or visible
- close (no one can enter) or open

___


### RPC

Short for Remote Procedure Call.
Can be a term for Operations (calling methods on the server) but in most cases it refers to calling a method on remote clients within [PUN](#photon-unity-networking-pun) games.

___


### RUDP

Reliable UDP.
A protocol on top of UDP which makes sent commands reliable on demand.
A sender repeats reliable messages until they are [acknowledged](#ack)

___


### Socket Server

Another name for the Photon Core.

___


### Timeout

With eNet, client and server monitor if the other side is acknowledging reliable commands.
If these ACKs are missing for a longer time, the connection is considered lost.

___


### Unreliable

Unreliable commands are not ACKd by the other side.
They are sequenced per channel but when dispatching, the sequence can have holes.

___


### Virtual Application

The Photon Cloud runs a single game logic ([Application](#application)) for all titles.
Internally, games are separated per [AppId](#application-id-appid) and [GameVersion](#gameversion).
