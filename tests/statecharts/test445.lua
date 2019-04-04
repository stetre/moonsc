require("moonsc").import_tags()

-- Test that lua objects defined by _data{ have value undefined
-- if _data{ does not assign a value 

return _scxml{ datamodel="lua",
   _datamodel{
      _data{ id="var1" },
   },
     
   _state{ id="s0",
      _transition{ cond="var1==nil", target="pass" },
     _transition{  target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

