require("moonsc").import_tags()

-- Reference a non-existent data model location in param in
-- donedata and see that the right error is raised 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },  
     
   _state{ id="s0", initial="s01",
      _onentry{
        _send{ event="timeout", delay="1s" },
      },
      _transition{ event="error.execution", target="pass" },
      _transition{ event="*", target="fail" },
      _state{ id="s01",
         _transition{ target="s02" },
      },
      _final{ id="s02",
         _donedata{ _param{ name="par3", location="notdefined()" },
   },
},
 },

   _final{id='pass'},
   _final{id='fail'},
}

