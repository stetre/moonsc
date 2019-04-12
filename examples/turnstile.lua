#!/usr/bin/env lua
-- MoonSC example: Turnstile Coin Machine.
--
-- This example is taken from the old paper:
-- "A Pattern Language of Statecharts", by S.M. Yacoub and H.H. Ammar (1998).
-- The example implements the statechart depicted in Figure 13, which is
-- the specification of a turnstile coin machine originally proposed by 
-- Robert Martin in a still older paper.
-- To try the statechart, we send a few events to it and, by looking at the
-- traces (printed on stdout) we should see that it works as expected.

local moonsc = require("moonsc")
moonsc.import_tags()

local S, P, H, T = _state, _parallel, _history, _transition

local statechart = _scxml{ name='Turnstile', initial="OFF",
   S{ id="OFF",
      T{ event="turn_on", target="ON" },
   },
   P{ id="ON",
      T{ event="turn_off", target="OFF" },
      S{ id="Operation", initial="history", 
         H{ id="history", T{ target="Functioning"} },
         S{ id="Broken",
            T{ event="fixed", target="Functioning", _raise{ event="warning_off" }},
         },
         S{ id="Functioning", initial="Locked",
            T{ event="failed", target="Broken" },
            S{ id="Locked", 
               T{ event="coin", target="Unlocked" },
            },
            S{ id="Unlocked", 
               T{ event="pass", target="Locked" },
               T{ event="coin", target="Unlocked" },
            },
         },
      },
      S{ id="Warning", initial="WarningOFF",
         S{ id="WarningOFF", T{ cond="In('Broken')", target="WarningON" }},
         S{ id="WarningON", T{ event="warning_off", target="WarningOFF" }},
      },
   },
}

moonsc.set_log_callback(function(sessionid, label, expr) print(expr) end)
moonsc.set_trace_callback(function(...) print(...) end)

local sessionid = moonsc.generate_sessionid()
moonsc.create(sessionid, statechart)
-- print(moonsc.tostring(sessionid))

moonsc.start(sessionid)

-- Send a few events to simulate a scenario:
moonsc.send(sessionid, "turn_on")  -- first of oll, turn the turnstile on
moonsc.send(sessionid, "coin")     -- insert coin...
moonsc.send(sessionid, "pass")     -- ...and pass
moonsc.send(sessionid, "pass")     -- sorry, you won't pass without inserting a coin!
moonsc.send(sessionid, "coin")     -- good boy...
moonsc.send(sessionid, "failed")   -- ops...
moonsc.send(sessionid, "turn_off") -- try fixing it by turning off and then on...
moonsc.send(sessionid, "turn_on")  -- ...but this won't work (notice the history, here)
moonsc.send(sessionid, "coin")     -- still locked, right?
moonsc.send(sessionid, "fixed")    -- technician at the rescue!
moonsc.send(sessionid, "coin")     -- insert coin...
moonsc.send(sessionid, "pass")     -- ...and pass
moonsc.send(sessionid, "turn_off")
moonsc.send(sessionid, "turn_on")  -- still functioning, I hope!
moonsc.cancel(sessionid)           -- this will cause the program to exit

while true do
   local tnext = moonsc.trigger()
   if not tnext then break end -- no more sessions running in the system
   moonsc.sleep(tnext - moonsc.now())
end

