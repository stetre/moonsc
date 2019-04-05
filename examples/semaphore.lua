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
while true do
   local tnext = moonsc.trigger()
   if not tnext then break end -- no more sessions running in the system
   -- tnext is the next time we need to call trigger(), unless in the meanwhile
   -- we send events from the application to any running session, in which case
   -- we must call it immediately after so that sessions can process them.
   -- Since this is not the case, we can sleep() until tnext arrives (or, if for
   -- example we are listening to sockets, we could set the select() timeout
   -- accordingly). This allows us to save a huge amount of CPU time in systems
   -- that are not continuosly stimulated and/or do not have (for example) to
   -- render graphics at the highest possible rate.
   moonsc.sleep(tnext - moonsc.now())
end

