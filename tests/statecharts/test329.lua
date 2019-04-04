require("moonsc").import_tags()

-- test that none of the system variables can be modified 

return _scxml{ initial="s0", name="machineName",
   _datamodel{
     _data{ id="var1" },
     _data{ id="var2" },
     _data{ id="var3" },
     _data{ id="var4" },
  },
        
 _state{ id="s0",
   _onentry{
     -- get _event bound so we can use it in s1
     _raise{ event="foo" },
     _assign{ location="var1", expr="_sessionid" },
     _assign{ location="_sessionid", expr="" },
  },

   _transition{ event="foo", cond="var1==_sessionid", target="s1" },
   _transition{ event="*", target="fail" },
},
   
 _state{ id="s1",
  _onentry{
     _assign{ location="var2", expr="_event" },
     _assign{ location="_event", expr="27" },
  },
   _transition{ cond="var2==_event", target="s2" },
   _transition{  target="fail" },
}, 
   
_state{ id="s2",
  _onentry{
     _assign{ location="var3", expr="_name" },
     _assign{ location="_name", expr="27" },
  },
   _transition{ cond="var3==_name", target="s3" },
   _transition{ target="fail" },
},
   
_state{ id="s3",
  _onentry{
     _assign{ location="var4", expr="_ioprocessors" },
     _assign{ location="_ioprocessors", expr="27" },
  },
   _transition{ cond="var4==_ioprocessors", target="pass" },
   _transition{ target="fail" },
}, 
   
   _final{id='pass'},
   _final{id='fail'},
}

