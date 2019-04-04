require("moonsc").import_tags()

-- Test that a history state never ends up part of the configuration

return _scxml{ initial="p1",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
   _parallel{ id="p1",
      _onentry{ _send{ delay="2s", event="timeout" }},
   
      _state{ id="s0",
         _transition{ cond="In('sh1')", target="fail" },
         _transition{ event="timeout", target="fail" },
      },

      _state{ id="s1",
         _initial{ _transition{ target="sh1" }}, 
         _history{ id="sh1", _transition{ target="s11" }}, 
         _state{ id="s11",
            _transition{ cond="In('sh1')", target="fail" },
            _transition{ target="s12" },
      },
        
      _state{ id="s12" },
         _transition{ cond="In('sh1')", target="fail" },
         _transition{ cond="var1==0", target="sh1" },
         _transition{ cond="var1==1", target="pass" },
         _onexit{ _assign{ location="var1", expr="var1+1" }}, 
      }, 
   }, 
 
   _final{id='pass'},
   _final{id='fail'},
}

