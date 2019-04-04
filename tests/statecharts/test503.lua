require("moonsc").import_tags()

-- test that a targetless transition does not exit and reenter its source state 

return _scxml{ initial="s1",
   _datamodel{
      _data{ id="var1", expr="0" }, -- how often we have exited s2 
      _data{ id="var2", expr="0" }, -- how often the targetless transition in s2 has been executed 
   }, 
    
   _state{ id="s1",
      _onentry{
         _raise{ event="foo" },
         _raise{ event="bar" },
      }, 
      _transition{ target="s2" },
   }, 
  
   _state{ id="s2",
      _onexit{ _assign{ location="var1", expr="var1+1" }}, 
         _transition{ event="foo", _assign{ location="var2", expr="var2+1" }}, 
         -- make sure the transition on foo was actually taken
         _transition{ event="bar", cond="var2==1", target="s3" },
         _transition{ event="bar", target="fail" },
   }, 
  
   _state{ id="s3",
      -- make sure that s2 was exited only once 
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

