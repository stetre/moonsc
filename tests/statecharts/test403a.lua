require("moonsc").import_tags()

-- We test one part of 'optimal enablement' meaning that of all transitions
-- that are enabled, we chose the ones in child states over parent states,
-- and use document order to break ties.
-- We have a parent state s0 with two children, s01 and s02. In s01, we test
-- that a) if a transition in the child matches, we don't consider matches in
-- the parent and b) that if two transitions match in any state, we take the
-- first in document order. In s02 we test that we take a transition in the
-- parent if there is no matching transition in the child.

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="1s" }}, -- catch the failure case
      _transition{ event="timeout", target="fail" },
      _transition{ event="event1", target="fail" },
      _transition{ event="event2", target="pass" },

      _state{ id="s01",
         -- this should be caught by the first transition in this state, taking us to S02
         _onentry{ _raise{ event="event1" }}, 
         _transition{ event="event1", target="s02" },
         _transition{ event="*", target="fail" },
      }, 
 
      _state{ id="s02",
         -- since the local transition has a cond that evaluates to false this should be
         -- caught by a transition in the parent state, taking us to pass
         _onentry{ _raise{ event="event2" }}, 
         _transition{ event="event1", target="fail" },
         _transition{ event="event2", cond="false", target="fail" },
      }, 
   },
 
   _final{id='pass'},
   _final{id='fail'},
}


