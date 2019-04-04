require("moonsc").import_tags()

-- test that platform creates undound variable if we assign an illegal
-- value to it.  Thus  we can assign to it later in state s1.  


return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="notdefined()" }, -- @@illegal expr
   },
     
   _state{ id="s0",
      _onentry{ _raise{ event="foo" }},
      _transition{ event="error.execution", cond="var1==nil", target="s1" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s1",
      _onentry{ _assign{ location="var1", expr="1" }},
      _transition{  cond="var1==1", target="pass" },
      _transition{ target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

