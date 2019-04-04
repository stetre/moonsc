require("moonsc").import_tags()

-- Test that _sessionid remains bound to the same value throught the session.
-- This means that it can't be assigned to  

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1", expr="_sessionid" },
      _data{ id="var2" },
   },
     
   _state{ id="s0",
      _transition{  target="s1" },
   },
   
   _state{ id="s1",
      _onentry{
         _assign{ location="_sessionid", expr="'otherName'" },
         _raise{ event="foo" },
      },
      _transition{ event="error.execution", target="s2" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s2",
      _transition{ cond="var1==_sessionid", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

