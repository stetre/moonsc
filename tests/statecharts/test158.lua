require("moonsc").import_tags()

-- Test that executable content executes in document order.
-- if event1 occurs then event2, succeed, otherwise fail

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
  
   _state{ id="s0",
      _onentry{
         _raise{ event="event1" },
         _raise{ event="event2" },
      },
      _transition{ event="event1", target="s1" },
      _transition{ event="*", target="fail" },
   },
 
   _state{ id="s1",
     _transition{ event="event2", target="pass" },
     _transition{ event="*", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

