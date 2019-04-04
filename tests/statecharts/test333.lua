require("moonsc").import_tags()

-- Make sure sendid is blank in a non-error event 

return _scxml{ initial="s0", name="machineName",  
   _state{ id="s0",
      _onentry{ _send{  event="foo" }}, 
      _transition{ event="foo", cond="_event.sendid==nil", target="pass" },
      _transition{ event="*", target="fail" },
   }, 
   _final{id='pass'},
   _final{id='fail'},
}

