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

-------------------------------------------------------------------------------
--*** DO NOT require() THIS MODULE (it is loaded automatically by MoonSC) ***--
-------------------------------------------------------------------------------

do
local moonsc = moonsc -- the C module loads this before calling us
local internal = {} -- internal functions shared across lua modules

local function copy_table(t)
   local tt = {}; for k, v in pairs(t) do tt[k] = v end; return tt
end

local ENV_TEMPLATE -- template for the dedicated environment

local set_env_template = function(env)
   ENV_TEMPLATE = copy_table(env)
   ENV_TEMPLATE.moonsc = nil -- remove the moonsc table
end

moonsc.set_env_template = set_env_template -- give the user access to it
internal.new_env = function() return copy_table(ENV_TEMPLATE) end

-- Initialize the default template:
set_env_template(_ENV)

-- Require the submodules:
local sessions = require("moonsc.sessions")
local algorithm = require("moonsc.algorithm")
local elements = require("moonsc.elements")
local utils = require("moonsc.utils")

-- Add their public functions to the moonsc table and internal functions
-- to the internal table:
sessions.open(moonsc, internal)
algorithm.open(moonsc, internal)
elements.open(moonsc, internal)
utils.open(moonsc, internal)

-- Second pass, where the modules are guaranteed to find the internal
-- functions they need that are defined elsewhere:
sessions.init(internal)
algorithm.init(internal)
elements.init(internal)
utils.init(internal)

end

