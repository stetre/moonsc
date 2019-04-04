require("moonsc").import_tags()

-- we can't test that _any_ lua is valid inside _script{, so we
-- just run a simple one and check that it can update the data model. 

return _scxml{ initial="s0", datamodel="lua",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
  
   _state{ id="s0",
      _onentry{ _script{ text=[[var1 = var1 + 1]] }},
      _transition{ cond="var1==1", target="pass" },
      _transition{  target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

