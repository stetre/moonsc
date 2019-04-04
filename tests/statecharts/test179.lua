require("moonsc").import_tags()

-- we test that <content> can be used to populate body of a message 

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="event1", _content{ text="123" }}},
      _transition{ event="event1",
            cond="_event.data and _event.data.content=='123'", target="pass" },
      _transition{ event="*", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

