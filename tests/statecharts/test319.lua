require("moonsc").import_tags()

-- test that _event is not bound before any event has been raised 

return _scxml{ initial="s0", name="machineName",
   _state{ id="s0",
      _onentry{
         _if{ cond="_event~=nil",
            _raise{ event="bound" },
         _else{},
            _raise{ event="unbound" },
         }, 
      }, 
      _transition{ event="unbound", target="pass" },
      _transition{ event="bound", target="fail"  },
   }, 
   _final{id='pass'},
   _final{id='fail'},
}

