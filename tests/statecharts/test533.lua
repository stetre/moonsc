require("moonsc").import_tags()

-- test that an internal transition whose source state is not compound does exit its source state 

return _scxml{ initial="s1",
   _datamodel{
      _data{ id="var1", expr="0" }, -- how often we have exited p 
      _data{ id="var2", expr="0" }, -- how often we have exited ps1 
      _data{ id="var3", expr="0" }, -- how often we have exited ps2 
      _data{ id="var4", expr="0" }, -- how often the transition for foo has been taken 
   }, 
    
   _state{ id="s1",
      _onentry{
         _raise{ event="foo" },
         _raise{ event="bar" },
      }, 
      _transition{ target="p" },
   }, 

   _parallel{ id="p",
      _onexit{ _assign{ location="var1", expr="var1+1" }}, 
      _transition{ event="foo", type="internal", target="ps1",
         _assign{ location="var4", expr="var4+1" },
      }, 
      -- make sure the transition on foo was actually taken  
      _transition{ event="bar", cond="var4==1", target="s2" },
      _transition{ event="bar", target="fail" },
      _state{ id="ps1", _onexit{ _assign{ location="var2", expr="var2+1" }}}, 
      _state{ id="ps2", _onexit{ _assign{ location="var3", expr="var3+1" }}}, 
   },
  
   _state{ id="s2",
      -- make sure that p was exited twice 
      _transition{ cond="var1==2", target="s3" },
      _transition{ target="fail" },
   }, 
 
   _state{ id="s3",
      -- make sure that ps1 was exited twice 
      _transition{ cond="var2==2", target="s4" },
      _transition{ target="fail" },
   }, 
  
   _state{ id="s4",
      -- make sure that ps2 was exited twice 
      _transition{ cond="var3==2", target="pass" },
      _transition{ target="fail" },
   }, 
  
   _final{id='pass'},
   _final{id='fail'},
}

