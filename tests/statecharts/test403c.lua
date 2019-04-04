require("moonsc").import_tags()

-- We test 'optimally enabled set', specifically that preemption works correctly

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   }, 
   
   _state{ id="s0", initial="p0",
      _onentry{
         _raise{ event="event1" },
         _send{ event="timeout", delay="1s" },
      }, 
      _transition{ event="event2", target="fail" },
      _transition{ event="timeout", target="fail" },
      _parallel{ id="p0",
         _state{ id="p0s1",
            _transition{ event="event1" },
            _transition{ event="event2" },
         }, 
         _state{ id="p0s2",
            _transition{ event="event1", target="p0s1", _raise{ event="event2" }},
         }, 
         _state{ id="p0s3",
            -- this transition should be blocked by the one in p0s2
            _transition{ event="event1", target="fail" },
            -- this transition will preempt the one that p0s2 inherits from an ancestor
            _transition{ event="event2", target="s1" },
         }, 
         _state{ id="p0s4",
            -- this transition never gets preempted, should fire twice
            _transition{ event="*", _assign{ location="var1", expr="var1+1" }}, 
         }, 
      },
   },

   _state{ id="s1",
      _transition{ cond="var1==2", target="pass" },
      _transition{ target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

