require("moonsc").import_tags()

-- Test that origintype is blank on internal events 

return _scxml{ initial="s0", name="machineName",  
   _state{ id="s0",
      _onentry{ _raise{  event="foo" }}, 
      _transition{ event="foo", cond="_event.origintype==nil", target="pass" },
      _transition{ event="*", target="fail"  },
   }, 
      
   _final{id='pass'},
   _final{id='fail'},
}

