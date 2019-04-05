#!/usr/bin/env lua
-- MoonSC example: a simple semaphore (traffic light).
-- Initially red, switches to green after 5s, then to yellow after 3s,
-- then back to red after 2s. Repeats this cycle indefinitely.

local moonsc = require("moonsc")
moonsc.import_tags()

local statechart = _scxml{ name='semaphore', initial='red',
   _state{ id='red',
      _onentry{ 
         _log{ expr="'Semaphore is red'" },
         _send{ event='timeout', delay='5s' },
      },
      _transition{ event='timeout', target='green' },
   },
   _state{ id='green',
      _onentry{ 
         _log{ expr="'Semaphore is green'" },
         _send{ event='timeout', delay='3s' },
      },
      _transition{ event='timeout', target='yellow' },
   },
   _state{ id='yellow',
      _onentry{ 
         _log{ expr="'Semaphore is yellow'" },
         _send{ event='timeout', delay='2s' },
      },
      _transition{ event='timeout', target='red' },
   }
}

moonsc.set_log_callback(function(sessionid, label, expr) print(expr) end)

local sessionid = moonsc.generate_sessionid()
moonsc.create(sessionid, statechart)
print(moonsc.tostring(sessionid))

print("This example goes on indefinitely (type ctrl-C to stop it)\n")
moonsc.start(sessionid)
while moonsc.trigger() do end

