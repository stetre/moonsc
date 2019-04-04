require("moonsc").import_tags()

-- test that _event stays bound during the onexit and entry into the next state -->

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1" },
   }, 
     
   _state{ id="s0",
      _onentry{ _raise{ event="foo" }}, 
      _transition{ event="foo", target="s1"  },
   }, 
   
   _state{ id="s1",
      _onentry{
         _raise{ event="bar" },
         -- _event should still be bound to 'foo' at this point 
         _assign{ location="var1", expr="_event.name" },
      }, 
      _transition{ cond="var1=='foo'", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

