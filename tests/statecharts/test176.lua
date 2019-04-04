require("moonsc").import_tags()

-- we test that <param> uses the current value of var1, not its initial value.
-- If the value of aParam in event1 is 2 so that var2 gets set to 2, success,i
-- otherwise failure  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="1" },
      _data{ id="var2"},
  },
  
   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr="2" },
         _send{ event="event1", _param{ name="aParam", expr="var1" }},
      },
      _transition{ event="event1", target="s1",
         _assign{ location="var2", expr="_event.data.aParam" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var2==2", target="pass" },
      _transition{ target="fail" },
  },
     
   _final{id='pass'},
   _final{id='fail'},
}

