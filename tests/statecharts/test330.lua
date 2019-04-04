require("moonsc").import_tags()

-- check that the required fields are present in both internal and external events 

return _scxml{ initial="s0", name="machineName",
   _state{ id="s0",
      _onentry{ _raise{ event="foo" }},
      _transition{ event="foo", cond="_event~=nil and _event.name=='foo'", target="s1"  },
      _transition{ event="*", target="fail"  },
   },
   
   _state{ id="s1",
      _onentry{ _send{ event="bar" }},
      _transition{ event="bar", cond="_event~=nil and _event.name=='bar'", target="pass"  },
      _transition{ event="*", target="fail"  },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

