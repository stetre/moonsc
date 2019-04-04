-- The MIT License (MIT)
--
-- Copyright (c) 2019 Stefano Trettel
--
-- Software repository: MoonSC, https://github.com/stetre/moonsc
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local function fifo()
   local self, first, last = {}, 0, -1
   return setmetatable(self, {
      __index = {

      push = function(self,val)
         last = last+1
         self[last] = val
      end,
--[[
      pushprio = function(self,val)
         first = first-1
         self[first] = val
      end,
--]]

      pop = function(self)
         if first > last then return nil end
         local val = self[first]
         self[first] = nil
         first = first + 1
         if first > last then first = 0 last = -1 end -- reset 
         return val
      end,  

--[[
      peek = function(self)
         if first > last then return nil end
         return self[first]
      end,

      moveto = function(self, dstfifo)
      -- pops all values and pushes them in dstfifo
         local val = self:pop()
         while val do
            dstfifo:push(val) 
            val = self:pop()
         end
      end,
--]]

      count = function(self)
         return last - first + 1
      end,

      isempty = function(self)
         return first > last
      end,
      
      }, -- __index

      __pairs = function(self)
         local function iterator(self, i)
            local v = self[i]
            if v then return i+1, v end
         end
         return iterator, self, first
      end,

      __len = function(list) return last - first + 1 end,

      __tostring = function(self)
         local s = {}
         local i = first
         while i <= last do
            s[#s+1] = self[i]
            i = i+1
         end
         return table.concat(s," ")
      end,

--    __gc = function(self) print("collected")  end,

   })
end

return fifo
