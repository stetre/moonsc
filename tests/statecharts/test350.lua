require("moonsc").import_tags()

-- Test that target value is used to decide what session to deliver
-- the event to.  A session should be able to send an event to itself
-- using its own session ID as the target 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'#_scxml_'" },
      _data{ id="var2", expr="_sessionid" }, 
   },
  
   _state{ id="s0",
      _onentry{
         _send{ delay="5s", event="timeout" },
         _send{ type="scxml", targetexpr="var1..var2", event="s0Event" },
      },
      _transition{ event="s0Event", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

