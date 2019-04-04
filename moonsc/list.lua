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

local function List(element, list1) -- ordered set (fifo list)
   local first, last, count = 0, -1, 0
   local present = {} -- reverse table
-- local name

   local list = setmetatable({}, {
      __index = {
         -- set_name = function(n) name = n end, -- for debug

         count = function(list) return count end, -- same as #list (see __len)

         isempty = function(list) return count == 0 end,
 
         ismember = function(list, element)
            return present[element] or false
         end,

         add = function(list, element) -- push
            -- Appends an element to the list, but only if the element
            -- is not already in.
            if present[element] then return end
            last = last+1
            list[last] = element
            present[element] = true
            count = count + 1
         end,

         delete = function(list, element)
            -- Marks element as deleted, without actually removing it.
            -- The element may be at any position in the list, and will
            -- be actually removed when encountered in a pop() call.
            if present[element] then
               present[element] = nil
               count = count - 1
            end
         end,

         pop = function(list)
            -- Deletes and returns the first element, if any
            if count == 0 then return nil end
            local element = list[first]
            list[first] = nil
            first = first + 1
            if first > last then first = 0 last = -1 end
            if present[element] then
               present[element] = nil
               count = count - 1
               return element
            end
            -- the element was deleted so try the next one, if any
            return list:pop()
         end,  

         head = function(list)
            -- Returns the element at the head of the list, without removing it
            if count==0 then return nil end
            local i = first
            while true do
               local element = list[i]
               if present[element] then return element end
               i = i + 1
            end
         end,

         --[[
         clone = function(list)
            -- Returns a copy of the list
            local copy = List()
            for _, element in pairs(list) do copy:add(element) end
            return copy
         end,
         --]]

         append = function(list, list1)
            -- Appends the elements of list1 to list (does not create a new list).
            for _, element in pairs(list1) do list:add(element) end
         end,

         filter = function(list, predicate)
            -- Returns a new list with only the elements that satisfy the predicate
            -- (a function 'boolean = predicate(element)' )
            local newlist = List()
            for _, element in pairs(list) do
               if predicate(element) then newlist:add(element) end
            end
            return newlist
         end,

         --[[
         some = function(list, predicate)
            -- Returns true if some element in the list satisfies the predicate.
            -- Returns false for an empty list.
            for _, element in pairs(list) do
               if predicate(element) then return true end
            end
            return false
         end,

         every = function(list, predicate)
            -- Returns true if every element in the list satisfies the predicate. 
            -- Returns true for an empty list.
            for _, element in pairs(list) do
               if not predicate(element) then return false end
            end
            return true
         end,
         --]]

         intersects = function(list, list1)
            -- Returns true if list and list1 have at least one member in common
            local a, b = list, list1
            if #a > #b then a, b = b, a end -- iterate over the smaller one
            for _, element in pairs(a) do
               if b:ismember(element) then return true end
            end
            return false
         end,

         sort = function(list, comp)
            -- Creates and returns a new list where the elements are sorted
            -- according to the comp function.
            local tmp = {}
            for _, el in pairs(list) do tmp[#tmp+1] = el end
            table.sort(tmp, comp)
            local newlist = List()
            for _, el in ipairs(tmp) do newlist:add(el) end
            return newlist
         end,

      }, -- __index

      __len = function(list) return count end, -- the # operator

      __pairs = function(list)
         -- Iterator for ordered traversal.
         local function iterator(list, i)
            local element = list[i]
            if element then
               if present[element] then return i+1, element
               else return iterator(list, i+1)
               end
            end
         end
         return iterator, list, first
      end,
   })

   -- Initialize the list with the given elements, if any
   if element then list:add(element) end
   if list1 then list:append(list1) end
   return list
end

return List 

