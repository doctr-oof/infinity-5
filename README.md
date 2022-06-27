


# Introduction

**Infinity 5** (or just **Infinity**) is a lightweight job executor and module loader that aims to speed the project setup and controller creation process. It serves as the backbone of most of my projects. It's whole purpose is to let you quickly and easily write client and server code without excess overhead, worrying about order of execution, etc.

# Getting Started

Setting up Infinity for your project requires little work on your part. All you need to do is:
1) Clone the repo to your local drive.
2) Copy all files and folders EXCEPT the `.git` folder to your project.
3) Done!

# Understanding Project Hierarchy
Infinity uses a relatively typical Rojo project hierarchy. That said, not every module and folder included in the default installation is necessary. This section aims to clarify which parts of the framework are *mandatory* for Infinity to work correctly, and which ones are not.

## Required Files and Folders
These files and folders are REQUIRED for Infinity to work correctly. Removing any of these components will break the framework.

**/_loader/** -> The secondary Rojo subproject that contains the Infinity Module Loader. This is cloned in `ReplicatedStorage`.

**/src/character/** -> Points to StarterCharacterScripts. Used for plain LocalScripts that you need to run when the player spawns.

**/src/client/** -> Points to StarterPlayerScripts. Houses client jobs and the InfinityClient loader.

**/src/client/jobs/** -> The folder that contains all client jobs.

**/src/first/** -> Points to ReplicatedFirst. Used for plain LocalScripts that you need to... well... replicate first.

**/src/server/** -> Points to ServerScriptService. Houses server jobs and the InfinityServer loader.

**/src/server/jobs/** -> The folder that contains all server jobs.

**/src/shared/** -> Points to ReplicatedStorage. Houses the shared jobs folder.

**/src/shared/jobs/** -> Jobs in this folder run on both the server and the client, in separate threads.

# Loading Modules
Infinity comes with a lightweight module loader that allows you to require with path strings that are 1:1 to the project hierarchy.

## Importing the Loader
To use the module loader, you need (or at least, should) override the default `require()` function like so:

```lua
local require = require(game.ReplicatedStorage:WaitForChild('Infinity'))
```

Once you have imported the loader, you can require modules directly from their path in the project hierarchy like so:

```lua
local platform = require('util/Platform') -- points to src/client/util/Platform
```

**NEW IN VERSION 6:** You can now require modules without directly pathing to them. For example:

```lua
local platform = require('Platform')
```

## Path Contexts
When requiring a module, Infinity uses the current network context to determine which folder to search in. For example, if a **client** job is requiring **util/Platform**, the loader will check for `client/util/Platform`. Whereas if the **server** requires that module, the loader will check `server/util/Platform`, which does not exist. *This will cause your scripts to error.*

Client scripts cannot require modules from the server, and vice-versa.

## Requiring a Shared Module
Knowing the above information, you might be wondering how to require a module located in `src/shared/`. To do so, you'll simply need to append the shared path prefix to your require string. The prefix is `$`. Example:

```lua
local maid = require('$lib/Maid') -- points to src/shared/lib/Maid
```

**NEW IN VERSION 6:** You can now require modules without directly pathing to them. For example:

```lua
local maid = require('$Maid')
```

# Understanding and Creating Jobs
At run time (both on the client and the server), Infinity will recurse through all `src/client/jobs/`, `src/server/jobs/`, and `src/shared/jobs/` and require any module that is located in those folders. This is where you will put all of your game code depending on which context you want it to run in.

## Job Properties
Each job has a pre-defined list of semi-optional properties that can be specified in the returned module data.
| Property Name | Default Value | Required | Description |
|--|--|--|--|
| **Priority** | 999 | No | Sets the priority of the `::Init()` and `::Run()` callbacks |
| **TickPriority** | 999 | No | Sets the priority of the `::Tick()` callback |
| **TickRate** | 1 | No | Sets the interval in frames of the `::Tick()` callback |
| **UpdateRate** | n/a | Yes, if `::Update()` exists | Sets the interval in seconds of the `::Update()` callback |

## Job Callbacks
Each job has a set of optional, pre-defined callbacks that you can use to quickly get your code executed in a specified manner or order. This list order is the same order in which these callbacks are processed.
| Function Name | Yields | Description |
|--|--|--|
| `::Immediate()` | No | Runs during lazy loading. Does not respect priority. |
| `::Init()` | Yes | Runs after lazy loading, one at a time per-job. Respects priority. Will hold up lower priority jobs until execution completes. |
| `::InitAsync()` | No | Runs after lazy loading, one at a time per-job. Respects priority. Will not hold up lower priority jobs. |
| `::PlayerAdded(client: Player)` | No | Binds `PlayerAdded` and manually triggers once at runtime to account for delayed startup. Cannot be disconnected. |
| `::PlayerLeft(client: Player)` | No | Binds `PlayerRemoving`. Cannot be disconnected. |
| `::Stepped(time: number, delta: number)` | No | Binds `Stepped`. Cannot be disconnected. |
| `::Heartbeat(delta: number)` | No | Binds `Heartbeat`. Cannot be disconnected. |
| `::RenderStepped(delta: number)` | No | Binds `RenderStepped`. Cannot be disconnected. CLIENT ONLY. |
| `::Update()` | Yes, only itself | Runs in set intervals of *time* if `UpdateRate` is specified. Cannot be stopped once started. |
| `::Tick()` | Yes, all ticks | Runs in set intervals of *frames* in order of `TickPriority` (default 999). Holds up lower priority tickers during execution, so make your code quick! Server can run up to 30 times per second, client up to 60. |

## Contextual Flags
In version 6.0 and forward, Infinity now allows you to create and distribute Flag data to all jobs.

### Flag File Locations
Flag files are modules that essentially store a set of constants that can be access in any job. They are located as follows:
**/src/client/_executor/Flags.lua** -> Client-only Flags.
**/src/server/_executor/Flags.lua** -> Server-only Flags.

Flags can be accessed from any Infinity main-executor callback (e.g. `::InitAsync()`) via `self`:
```lua
function MyJob:InitAsync()
    if self.FLAGS.DEVELOPER_MODE then
        print('Developer mode enabled!')
    end
end
```

## Execution Flow
Both the client and server executors load and run jobs in the same fashion:
1) The executor recurses through its contextual `jobs/` folder and lazy loads each module into memory if the job's `Enabled` property is not `false`.

	1.1 If a loaded job has an `::Immediate()` callback, the function is fast-spawned right away. `Priority` is not respected.
	
2) The executor sorts the loaded jobs based on their `Priority` property. If none is specified, the job is pushed to the end of the queue.

3) The executor recurses through the loaded jobs and process them as follows:

	3.1 Each job's `::Init()` function is called, in order of priority, if present. Each call yields until completion.
	
	3.2 Each job's `::Run()` function is deferred, in order of priority, if present. Each call is asynchronous and will not halt the executor if the function errors or yields indefinitely.
	
	3.3 Built-in helper functions (`::Stepped()`, `::PlayerAdded()`, etc.) are connected to their respective events and allowed to run.
	
	3.4 If the `UpdateRate` property and `::Update()` function is present, a cache will be created with the specified timer and callback.
	
	3.5 If the `::Tick()` function is present, a cache will be created with the function as well as the optional `TickPriority` and `TickRate` properties.
4) After all contextual jobs are loaded, all updaters and tickers are started.
	
	4.1 Updaters will run asynchronously of other updaters, but WILL yield themselves to prevent race conditions and overlaps.
	
	4.2 Tickers run one at a time, in order of `TickPriority`, and WILL yield ALL tickers with a lower priority until they finish execution.

5) Steps 1 - 4 are repeated for `shared/jobs/` on both the client and the server.

# Conclusion
That's pretty much it. I'm not writing a fancy conclusion... sorry ;(
