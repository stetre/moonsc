require("moonsc").import_tags()

-- Test that any error raised by an element of executable content
-- causes all subsequent elements to be skipped.
-- The send tag will raise an error so var1 should not be incremented. 
-- If it is fail, otherwise succeed

local function L(what) return _log{expr=what} end
local function T(n) return _log{expr="'@@"..n.."'"} end

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
  
   _state{ id="s0",
      _onentry{
         _send{ event="thisWillFail", target="" }, -- illegal target
         _assign{ location="var1", expr="var1+1" }, T(2)
      },
      _transition{ cond="var1==1", target="fail" , T(1)},
      _transition{ target="pass" },
   },

   _final{id='pass'},
   _final{id='fail'},
}


