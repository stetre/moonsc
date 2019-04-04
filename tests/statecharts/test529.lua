require("moonsc").import_tags()

-- Simple test that children work with <content>

-- Note that MoonSC does not directly support the <content>.text attribute,
-- but needs assistance from the application via the 'content callback'.

return _scxml{ initial="s0",
     
   _state{ id="s0", initial="s01",
      _transition{ event="done.state.s0",
            cond="_event.data and _event.data.content=='21'", target="pass" },
      _transition{ event="done.state.s0", target="fail" },
      _state{ id="s01", _transition{ target="s02" }},
      _final{ id="s02", _donedata{ _content{ text="21" }}},
   },

   _final{id='pass'},
   _final{id='fail'},
}

