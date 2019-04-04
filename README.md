## MoonSC: Harel Statecharts in Lua

MoonSC is an execution environment for
[Harel statecharts](https://en.wikipedia.org/wiki/State_diagram#Harel_statechart)
following the W3C [SCXML Recommendation](https://www.w3.org/TR/scxml/), capable
of running multiple concurrent SCXML sessions defined by statecharts written
as Lua tables.

It runs on GNU/Linux <!-- and on Windows (MSYS2/MinGW) --> and requires 
[Lua](http://www.lua.org/) (>=5.3).


_Author:_ _[Stefano Trettel](https://www.linkedin.com/in/stetre)_

[![Lua logo](./doc/powered-by-lua.gif)](http://www.lua.org/)

#### License

MIT/X11 license (same as Lua). See [LICENSE](./LICENSE).

#### Documentation

See the [Reference Manual](https://stetre.github.io/moonsc/doc/index.html).

#### Getting and installing

Setup the build environment as described [here](https://github.com/stetre/moonlibs), then:

```sh
$ git clone https://github.com/stetre/moonsc
$ cd moonsc
moonsc$ make
moonsc$ sudo make install
```

#### Example

The example below defines a simple statechart and executes it.

Other examples can be found in the **examples/** and the **tests/** directories.

```lua
-- MoonSC 'Hello World' example - hello.lua
local moonsc = require("moonsc")

-- Import the element constructors:
moonsc.import_tags()

-- Define a statechart using them:
local helloworld = _scxml{ name="hello", initial="s1",
   _script{ text=[[print("Hello, World!")]] },
   _state{ id="s1",
      _onentry{ _log{ expr="'entering state s1'" } },
      _transition{ event="go", target="s2",
         _log{ expr=[["received event '".._event.name.."'"]] }
      },
      _onexit{ _log{ expr="'exiting state s1'" } },
   },
   _final{ id="s2",
      _onentry{ _log{ expr="'entering state s2'" } },
      _onexit{ _log{ expr="'exiting'" } },
   },
}

-- Set a callback to redirect <log> executions to stdout:
moonsc.set_log_callback(function(...) print(...) end)

-- Create a session with the statechart, start it, and send it an event:
moonsc.create("mysession", helloworld)
moonsc.start("mysession")
moonsc.send("mysession", "go")

-- Enter the main event loop:
while true do
   if not moonsc.trigger() then break end
end

```

The script can be executed at the shell prompt with the standard Lua interpreter:

```shell
$ lua hello.lua
```

#### See also

* [MoonLibs - Graphics and Audio Lua Libraries](https://github.com/stetre/moonlibs).
