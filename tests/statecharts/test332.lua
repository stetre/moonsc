require("moonsc").import_tags()

-- test that sendid is present in error events triggered by send errors 

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1" },
      _data{ id="var2" },
   },   
   
   _state{ id="s0",
      _onentry{
         -- this will raise an error and also store the sendid in var1 
         _send{ target="baz", event="foo", idlocation="var1" }, -- illegal target
      },
      -- get the sendid out of the error event:
      _transition{ event="error", target="s1", _assign{ location="var2", expr="_event.sendid" }},
      _transition{ event="*", target="fail"  },
   },
   
   _state{ id="s1",
      -- make sure that the sendid in the error event matches the one generated when send executed 
      _transition{ cond="var1==var2", target="pass", _log{ expr="'var1='..var1"}},
      _transition{ target="fail" },
   },
      
   _final{id='pass'},
   _final{id='fail'},
}

