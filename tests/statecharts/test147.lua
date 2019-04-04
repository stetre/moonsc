require("moonsc").import_tags()

-- Test that the first clause that evaluates to true - and
-- only that clause - is executed.
-- Only one event should be raised, and it should be bar

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
  
   _state{ id="s0",
      _onentry{
         _if{ cond="false",
            _raise{ event="foo" },
            _assign{ location="var1", expr="var1+1" },
         _elseif{ cond="true" },
            _raise{ event="bar" },
            _assign{ location="var1", expr="var1+1" },
         _else{},
            _raise{ event="baz" },
            _assign{ location="var1", expr="var1+1" },
         },
         _raise{ event="bat" },
      },
      _transition{ event="bar", cond="var1==1", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

