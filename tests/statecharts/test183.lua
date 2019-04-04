require("moonsc").import_tags()

-- we test that _send{ stores the value of the sendid in idlocation.
-- If it does, var1 has a value and we pass.  Otherwise we fail  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
  
   _state{ id="s0",
      _onentry{ _send{ event="event1", idlocation="var1" }},
      _transition{ cond="var1~=nil", target="pass", _log{ expr="var1"} },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

