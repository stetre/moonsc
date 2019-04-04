require("moonsc").import_tags()

-- Test that the default history state works correctly.
-- From initial state s3 we take a transition to s0's default shallow
-- history state. That should generate "enteringS011", which takes us to s4.
-- In s4, we transition to s1's default deep history state. We should end up
-- in s122, generating "enteringS122".  Otherwise failure.

return _scxml{ initial="s3",
       
   _state{ id="s0", initial="s01",
      _transition{ event="enteringS011", target="s4" },
      _transition{ event="*", target="fail" },
      _history{ type="shallow", id="s0HistShallow", _transition{ target="s01" }},
      _history{ type="deep", id="s0HistDeep", _transition{ target="s022" }},
      _state{ id="s01", initial="s011",
         _state{ id="s011", _onentry{ _raise{ event="enteringS011" }}},
         _state{ id="s012", _onentry{ _raise{ event="enteringS012" }}},
      },
      _state{ id="s02", initial="s021",
         _state{ id="s021", _onentry{ _raise{ event="enteringS021" }}},
         _state{ id="s022", _onentry{ _raise{ event="enteringS022" }}},
      }  
   },

   _state{ id="s1", initial="s11",
      _transition{ event="enteringS122", target="pass" },
      _transition{ event="*", target="fail" },
      _history{ type="shallow", id="s1HistShallow", _transition{ target="s11" }},
      _history{ type="deep", id="s1HistDeep", _transition{ target="s122" }},
      _state{ id="s11", initial="s111",
         _state{ id="s111", _onentry{ _raise{ event="enteringS111" }}},
         _state{ id="s112", _onentry{ _raise{ event="enteringS112" }}},
      },
      _state{ id="s12", initial="s121", 
         _state{ id="s121", _onentry{ _raise{ event="enteringS121" }}},
         _state{ id="s122", _onentry{ _raise{ event="enteringS122" }}},
      }
   },

   _state{ id="s3",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _transition{ target="s0HistShallow" },
   },

   _state{ id="s4",
      _transition{ target="s1HistDeep" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

