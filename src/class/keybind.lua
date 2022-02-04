local keybind = {
    stack = {}
}

-- Shortcuts
local insert = table.insert
local remove = table.remove
local lk = love.keyboard

-- Checks if 2 tables contain the same keys
-- Order of keys doesn't matter.
local same = function(ta, tb)
    if ta == tb then return true end
    if #ta ~= #tb then return false end
    local same = 0
    for _,a in pairs(ta) do
        for _,b in pairs(tb) do
            if a == b then
                same = same + 1
                break
            end
        end
    end
    return same == #ta and true or false
end

-- Keeps track of keys currently down
local keys_down = {}

-- Creates a new keybinding
-- Event is the callback that should trigger this keybind. ("keypressed", "keyreleased", "keydown")
-- keys should be a table containing the keys to trigger the keybind. ({"escape"} or {"lshift", "escape"})
-- func is the function that's called by this keybind
-- ... are any arguments that should be passed to the function
function keybind:new(event, keys, func, ...)
    --if type(keys) == "string" then keys = {keys} end
    insert(self.stack, {
        event = event,
        keys = keys,
        func = func,
        args = {...}
    })
end

-- Trigger function, Event should be a string. Either "keypressed", "keyreleased" or "keydown"
function keybind:trigger(event, key)
    for i,v in ipairs(self.stack) do
        if v.event == event then
            if same(keys_down, v.keys) then
                v.func(unpack(v.args))
            end
        end
    end

end

-- These callbacks handle keeping track of keys_down
-- keypressed needs to be called BEFORE trigger
function keybind:keypressed(key)
    insert(keys_down, key)
end

-- keyreleased needs to be called AFTER trigger
function keybind:keyreleased(key)
    for i,v in ipairs(keys_down) do
        if not lk.isDown(v) then
            remove(keys_down, i)
        end
    end
end

return keybind
