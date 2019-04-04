require("moonsc").import_tags()

-- simple test that 'expr' works with <content>

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _transition{ event="done.state.s0",
            cond="_event.data and _event.data.content=='foo'", target="pass", },
      _transition{ event="done.state.s0", target="fail" },
      _state{ id="s01", _transition{ target="s02" }},
      _final{ id="s02", _donedata{ _content{ expr="'foo'" }}},
      --_final{ id="s02", _donedata{ _content{ expr="foo()" }}},
   },

   _final{id='pass'},
   _final{id='fail'},
}

