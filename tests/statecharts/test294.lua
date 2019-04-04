require("moonsc").import_tags()

-- Test that a param inside donedata ends up in the data field
-- of the done event and that content inside donedata sets the
-- full value of the event.data field 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },  
     
   _state{ id="s0", initial="s01",
      _transition{ event="done.state.s0",
         cond="_event.data and _event.data.par1==1", target="s1" },
      _transition{ event="done.state.s0", target="fail" },
      _state{ id="s01",
         _transition{ target="s02" },
      },
      _final{ id="s02", _donedata{ _param{ name="par1", expr="1" }},
      },
   },
 
   _state{ id="s1", initial="s11",
      _transition{ event="done.state.s1", 
         cond="_event.data and _event.data.content=='foo'", target="pass"},
      _transition{ event="done.state.s1", target="fail" },
      _state{ id="s11",
         _transition{ target="s12" },
      },
      _final{ id="s12", _donedata{ _content{ text="foo" }}},
   },

   _final{id='pass'},
   _final{id='fail'},
}

