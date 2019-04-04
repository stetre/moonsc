require("moonsc").import_tags()

-- test that event.data can be populated using either namelist and <param>
-- or <content>, and that correct values are used 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'foo'" },
      _data{ id="var2" },
      _data{ id="var3" },
   },
  
   _state{ id="s0",
      _onentry{
         _send{ delay="5s", event="timeout" },
         _send{ event="event1", type="scxml", namelist="var1", _param{ name="param1", expr="'bar'" }},
      },
      _transition{ event="event1", target="s1",
         -- _log{ expr="_event.data.var1" },
         -- _log{ expr="_event.data.param1" },
         _assign{ location="var2", expr="_event.data.var1" },
         _assign{ location="var3", expr="_event.data.param1" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var2=='foo'", target="s2" },
      _transition{ target="fail" },
   },

   _state{ id="s2",
      _transition{ cond="var3=='bar'", target="s3" },
      _transition{ target="fail" },
   },

   _state{ id="s3",
      _onentry{
         _send{ delay="5s", event="timeout" },
         _send{ event="event2", _content{ text="baz" }}, -- beware that "'baz'" ~= "baz" !!
      },
      _transition{ event="event2", cond="_event.data.content=='baz'", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

