require("moonsc").import_tags()

-- Test that each onexit handler is a separate block. 
-- The <send> of event1 will cause an error but
-- the increment to var1 should happen anyways

return _scxml{
   _datamodel{ _data{ id="var1", expr="1" }},
   _state{ id="s0",
      _onexit{ _send{ target="", event="event1" }}, -- illegal target
      _onexit{ _assign{ location="var1", expr="var1+1" }},
      _transition{ target="s1" },
   },
   _state{ id="s1", 
      _transition{ cond="var1==2", target="pass" },
      _transition{ target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

