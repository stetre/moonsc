require("moonsc").import_tags()

-- test that sendid is set in event if present in send, blank otherwise 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
      _data{ id="var2" },
   },
  
   _state{ id="s0",
      _onentry{
         _send{ delay="5s", event="timeout" },
         _send{ type="scxml", id="send1", event="s0Event" },  
      },
      _transition{ event="s0Event", target="s1", 
         _assign{ location="var1", expr="_event.sendid" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var1=='send1'", target="s2" },
      _transition{ target="fail" },
   },
 
   _state{ id="s2",
      _onentry{
         _send{ delay="5s", event="timeout" },
         _send{  event="s0Event2" },
      },
      _transition{ event="s0Event2", target="s3",
         _assign{ location="var2", expr="_event.sendid" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s3",
      _transition{ cond="var2==nil", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

