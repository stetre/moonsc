require("moonsc").import_tags()

-- Test that events are inserted into the queue in the order in which
-- they are raised. If foo occurs before bar, success, otherwise failure

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _raise{ event="foo" },
         _raise{ event="bar" },
      },
      _transition{ event="foo", target="s1" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s1",
      _transition{ event="bar", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}


