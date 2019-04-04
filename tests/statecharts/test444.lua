require("moonsc").import_tags()

--  test that _data{ creates a new lua variable. 

return _scxml{ datamodel="lua",
   _datamodel{
      _data{ id="var1", expr="1" },
   },
     
   _state{ id="s0",
      -- test that var1 can be used as a lua variable 
      -- @@ this is slightly different than the original ++var1==2, in that
      --    it doesn't increment var1 (the test still holds, though, methink)
      _transition{  cond="(var1+1)==2", target="pass" },
      _transition{  target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

