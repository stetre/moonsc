require("moonsc").import_tags()

-- test that <content> child is evaluated when <invoke> is.
-- Var1 is initialized with an integer value, then set to an scxml script
-- in the onentry to s0. If <content> is evaluated at the right time, we
-- should get invoke.done, otherwise an error  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="1" },
   },
    
   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr=[["return {tag='scxml', {tag='final'}}"]]},
         _send{ event="timeout", delay="2s" },
      },
      _invoke{ type="scxml", _content{ expr="var1" }},
        
      _transition{ event="done.invoke", target="pass" },
      _transition{ event="*", target="fail" },
      },
    
   _final{id='pass'},
   _final{id='fail'},
}

