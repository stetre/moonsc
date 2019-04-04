require("moonsc").import_tags()

-- Test that eventexpr works and sets the name field of the resulting event 

return _scxml{ initial="s0", name="machineName",  
    _datamodel{
      _data{ id="var1", expr="'foo'" },
      _data{ id="var2" },
   },
     
   _state{ id="s0",
      _onentry{ _send{ eventexpr="var1" }},
      _transition{ event="foo", target="s1",
         _assign{ location="var2", expr="_event.name" },
      },
      _transition{ event="*", target="fail"  },
   },
   
   _state{ id="s1",
      _transition{ cond="var1==var2", target="pass" },
      _transition{ target="fail" },
   },
      
   _final{id='pass'},
   _final{id='fail'},
}

