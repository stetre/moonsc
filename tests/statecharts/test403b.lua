require("moonsc").import_tags()

-- We test that 'optimally enabled set' really is a set, specifically
-- that if a transition is optimally enabled in two different states,
-- it is taken only once.

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   }, 
   
   _state{ id="s0", initial="p0",
      -- this transition should never be taken because a transition in a lower
      -- state should always be selected
      _transition{ event="event1", _assign{ location="var1", expr="var1+1" }}, 
      
      _parallel{ id="p0",
         _onentry{
            _raise{ event="event1" },
            _raise{ event="event2" },
         }, 
         -- this transition will be selected by both states p0s1 and p0s2, but
         -- should be executed only once
         _transition{ event="event1", _assign{ location="var1", expr="var1+1" }}, 
         _state{ id="p0s1",
            _transition{ event="event2", cond="var1==1", target="pass" },
            _transition{ event="event2", target="fail" },
         }, 
         _state{ id="p0s2" }, 
      },
   },

   _final{id='pass'},
   _final{id='fail'},
}

