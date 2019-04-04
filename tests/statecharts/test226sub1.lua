require("moonsc").import_tags()

-- Sub-statechart
-- When invoked, if var1 has a value notify parent. Then terminate.

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
   _state{ id="s0",
      _transition{ cond="var1~=nil", target="final",
         _log{ expr="'var1='..tostring(var1)" },
         _send{ target="#_parent", event="varBound" },
      },
      _transition{ target="final" },
   },
   _final{ id="final" },
}

