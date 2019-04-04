require("moonsc").import_tags()

-- Test that we can use any lua expression as a value expression. 
-- In this case, we just test that we can assign a function to a
-- variable and then call it.  

return _scxml{ datamodel="lua",
   _datamodel{
      _data{ id="var1", expr="function(invar) return invar + 1 end" },
   },
   _state{ id="s0",
      _onentry{ _raise{ event="event1" }},
      -- test that we can call the function   
      _transition{ event="event1", cond="var1(2)==3", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

