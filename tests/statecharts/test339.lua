require("moonsc").import_tags()

-- test that invokeid is blank in an event that wasn't returned from an invoked process 

return _scxml{ initial="s0", name="machineName",  
   _state{ id="s0",
      _onentry{ _raise{  event="foo" }}, 
      _transition{ event="foo", cond="_event.invokeid==nil", target="pass" },
      _transition{ event="*", target="fail"  },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

