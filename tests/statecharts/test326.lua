require("moonsc").import_tags()

-- Test that _ioprocessors stays bound till the session ends.
-- This means that it cannot be assigned to 

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1", expr="_ioprocessors" },
      _data{ id="var2" },
   },

   _state{ id="s0",
      _transition{ cond="var1~=nil", target="s1" }, 
      _transition{ cond="true", target="fail" },
   },
   
   _state{ id="s1",
      _onentry{
         _assign{ location="_ioprocessors", expr="'otherName'" },
         _raise{ event="foo" },
      },
      _transition{ event="error.execution", target="s2" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s2",
      _onentry{ _assign{ location="var2", expr="_ioprocessors" }},
      _transition{ cond="var1==var2", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
   }

