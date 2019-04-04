require("moonsc").import_tags()

-- test the origintype is 'scxml'
-- Note that MoonSC does not recognize 'http://www.w3.org/TR/scxml/#SCXMLEventProcessor',
-- but only the shortcut value 'scxml'.

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
 
   _state{ id="s0",
      _onentry{
         _send{ delay="5s", event="timeout" },
         _send{ type="scxml", event="s0Event" },  
      },
      _transition{ event="s0Event", target="s1",
         _assign{ location="var1", expr="_event.origintype" },
      },
      _transition{ event="*", target="fail"},
   },

   _state{ id="s1",
      _transition{ cond="var1=='scxml'", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

