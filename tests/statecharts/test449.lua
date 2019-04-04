require("moonsc").import_tags()

--  test that lua objects are converted to booleans inside cond 

return _scxml{ datamodel="lua",
   _state{ id="s0",
      _transition{  cond="'foo'", target="pass" },
      _transition{  target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

