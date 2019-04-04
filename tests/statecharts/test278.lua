require("moonsc").import_tags()

-- test that a variable can be accessed from a state
-- that is outside its lexical scope

return _scxml{ initial="s0", datamodel="lua",
   _state{ id="s0",
      _transition{ cond="var1==1", target="pass" },
      _transition{  target="fail" },
   },
   
   _state{ id="s1",
      _datamodel{
         _data{ id="var1", expr="1" },
      },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

