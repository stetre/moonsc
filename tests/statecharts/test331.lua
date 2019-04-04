require("moonsc").import_tags()

-- Test that _event.type is set correctly for internal, platform, and external events 

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1" },
   },
     
   _state{ id="s0",
      _onentry{ _raise{ event="foo" }}, -- internal event 
      _transition{ event="foo", target="s1", _assign{ location="var1", expr="_event.type" }},
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var1=='internal'", target="s2" },
      _transition{ target="fail" },
   },
   
   _state{ id="s2",
      -- this will generate an error, which is a platform event 
      _onentry{ _assign{ location="invalid.location", expr="1" }},
      _transition{ event="error", target="s3", _assign{ location="var1", expr="_event.type" }},
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s3",
      _transition{ cond="var1=='platform'", target="s4" },
      _transition{ target="fail" },
   },
   
   _state{ id="s4",
      _onentry{ _send{ event="foo" }}, -- external event 
      _transition{ event="foo", target="s5", _assign{ location="var1", expr="_event.type" }},  
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s5",
      _transition{ cond="var1=='external'", target="pass" },
      _transition{ target="fail" },
  },

   _final{id='pass'},
   _final{id='fail'},
}

