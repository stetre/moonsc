require("moonsc").import_tags()

-- Test that values passed in from parent process override
-- default values specified in the child, test276sub1.scxml.
-- The child returns event1 if var1 has value 1, event0 if
-- it has default value 0.  

return _scxml{ initial="s0",
   _state{ id="s0",
      _invoke{ type="scxml", src="file:statecharts/test276sub1.lua",
         _param{ name="var1", expr="1" },
      },
      _transition{ event="event1", target="pass" },
      _transition{ event="event0", target="fail" },
    },

   _final{id='pass'},
   _final{id='fail'},
}

