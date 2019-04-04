require("moonsc").import_tags()

 -- in the ECMA data model, test that processor creates correct structure in
 -- _event.data when receiving KVPs in an event 

return _scxml{ initial="s0", datamodel="lua",
   _state{ id="s0",
      _onentry{
         _send{ event="foo", _param{ name="aParam", expr="1" }},
      },
      _transition{ event="foo", cond="_event.data.aParam == 1", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

