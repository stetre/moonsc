require("moonsc").import_tags()

-- test that origin field is blank for internal events 

return _scxml{ initial="s0", name="machineName",  
   _state{ id="s0",
      _onentry{ _raise{ event="foo" }}, 
      _transition{ event="foo", cond="_event.origin==nil", target="pass" },
      _transition{ event="*", target="fail" },
   }, 
      
   _final{id='pass'},
   _final{id='fail'},
}

