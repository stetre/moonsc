require("moonsc").import_tags()

-- test that src content can be used to assign a value to a var.
-- Edit test552.txt to have a value that's legal for the datamodel in question 

-- Note that MoonSC does not directly support the <data>.src attribute, but needs
-- assistance from the application via the 'data callback'.

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", src="file:statecharts/test552.txt" },
   },
    
   _state{ id="s0",
      _transition{ cond="var1~=nil", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

