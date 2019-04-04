require("moonsc").import_tags()

-- Test that the value in _event.name matches the event name
-- used to match against transitions


return _scxml{
   _state{ id="s0",
      _onentry{ _raise{ event="foo" }},
      _transition{ event="foo", cond="_event.name=='foo'", target="pass" },
      _transition{ event="foo", target="fail" },
   },
   _final{id='pass'},
   _final{id='fail'},
}

