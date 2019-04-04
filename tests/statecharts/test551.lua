require("moonsc").import_tags()

-- test that inline content can be used to assign a value to a var.  

-- Note that MoonSC does not directly support the <data>.text attribute, but needs
-- assistance from the application via the 'data callback'.

return _scxml{ initial="s0", binding="early",
   _state{ id="s0",
      _transition{ cond="var1~=nil", target="pass" },
      _transition{ target="fail" },
   },
   
   _state{ id="s1",
         _datamodel{ 
            _data{ id="var1", expr="{1,2,3}"},
      },
   },

   _final{id='pass'},
   _final{id='fail'},
}

