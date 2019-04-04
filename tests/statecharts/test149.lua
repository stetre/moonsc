require("moonsc").import_tags()

-- Test that neither if clause executes, so that bat is the only event raised.

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
  
   _state{ id="s0",
      _onentry{
         _if{ cond="false",
            _raise{ event="foo" },
            _assign{ location="var1", expr="var1+1" },
         _elseif{ cond="false" },
            _raise{ event="bar" },
            _assign{ location="var1", expr="var1+1" },
         },
         _raise{ event="bat" },
      },
      _transition{ event="bat", cond="var1==0", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

