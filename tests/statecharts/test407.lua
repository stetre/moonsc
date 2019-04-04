require("moonsc").import_tags()

-- A simple test that onexit handlers work.
-- var1 should be incremented when we leave s0

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
   _state{ id="s0",
      _onexit{ _assign{ location="var1", expr="var1+1" }},
      _transition{ target="s1" },
   },
   _state{ id="s1",
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   },
   _final{id='pass'},
   _final{id='fail'},
}


