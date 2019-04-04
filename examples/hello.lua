#!/usr/bin/env lua
-- MoonSC 'Hello World' example

local moonsc = require("moonsc")
moonsc.import_tags() -- import the element constructors

-- Define a statechart:
local helloworld = _scxml{ name="hello", initial="s1",
   _script{text=[[print("Hello, World!")]]},
   _state{ id="s1",
      _onentry{ _log{ expr="'entering state s1'" } },
      _transition{ event="go", target="s2",
         _log{ expr=[["received event '".._event.name.."'"]]}
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

-- Create a running session of the statechart and send an event to it:
moonsc.create("mysession", helloworld)

print(moonsc.tostring("mysession"))

moonsc.start("mysession")
moonsc.send("mysession", "go")

-- Enter the main event loop:
while true do
   if not moonsc.trigger() then break end
end

