require("moonsc").import_tags()

-- The assertion that errors are 'like any other event' is pretty broad,
-- but we can check that they are pulled off the internal queue in order,
-- and that prefix matching works on them.  

return _scxml{ initial="s0",
       
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="1s" }}, -- catch the failure case 
      _transition{ event="timeout", target="fail" },
      _state{ id="s01",
         _onentry{
            -- the first internal event. The error will be the second, and event2 will be the third 
            _raise{ event="event1" },
            -- assigning to a non-existent location should raise an error 
            --_assign{ location="", expr="2"  },
            _assign{ location="xxx", expr="notdefined()"  }, --@@
         }, 
         _transition{ event="event1", target="s02", _raise{ event="event2" }}, 
         _transition{  event="*", target="fail" },
      }, 
 
      _state{ id="s02",
         _transition{ event="error", target="s03" },
         _transition{ event="*", target="fail" },
      }, 
  
      _state{ id="s03",
         _transition{ event="event2", target="pass" },
         _transition{ event="*", target="fail" },
      }, 

   },
 
   _final{id='pass'},
   _final{id='fail'},
}

