require("moonsc").import_tags()

-- Test that history states works correctly.
-- The counter Var1 counts how many times we have entered s0.
-- The initial state is s012. We then transition to s1, which transitions
-- to s0's deep history state.  entering.s012 should be raised, otherwise failure.
-- Then we transition to s02, which transitions to s0's shallow history state. 
-- That should have value s01, and its initial state is s011, so we should get
-- entering.s011, otherwise failure.


return _scxml{ initial="s012",
   _datamodel{
      _data{ id="var1", expr="0" },
   }, 
       
   _state{ id="s0", initial="s01",
      _onentry{ _assign{ location="var1", expr="var1+1" }}, 
      -- the first time through, go to s1, setting  a timer just in case something hangs
      _transition{ event="entering.s012", cond="var1==1", target="s1",
         _send{ event="timeout", delay="2s" },
      }, 
      -- the second time, we should get entering.s012.  If so, go to s2, otherwise fail
      _transition{ event="entering.s012", cond="var1==2", target="s2" },
      _transition{ event="entering", cond="var1==2", target="fail" },
      -- the third time we should get entering-s011. If so, pass, otherwise fail
      _transition{ event="entering.s011", cond="var1==3", target="pass" },
      _transition{ event="entering", cond="var1==3", target="fail" },
      -- if we timeout, the state machine is hung somewhere, so fail
      _transition{ event="timeout", target="fail" },
      _history{ type="shallow", id="s0HistShallow", _transition{ target="s02" }}, 
      _history{ type="deep", id="s0HistDeep", _transition{ target="s022" }}, 
      _state{ id="s01", initial="s011",
         _state{ id="s011", _onentry{ _raise{ event="entering.s011" }}}, 
         _state{ id="s012", _onentry{ _raise{ event="entering.s012" }}}, 
      }, 
      _state{ id="s02", initial="s021",
         _state{ id="s021", _onentry{ _raise{ event="entering.s021" }}}, 
         _state{ id="s022", _onentry{ _raise{ event="entering.s022" }}}, 
      }, 
   },

   _state{ id="s1", _transition{ target="s0HistDeep" }},
   _state{ id="s2", _transition{ target="s0HistShallow" }},
 
   _final{id='pass'},
   _final{id='fail'},
}


