-- A bare bones state system
local state = {
    state = false,
    loadedStateName = "",
    state_list = {}
}

-- state_module: Path to a state module file
-- name: Name of the state, Used in state:load
function state:define_state(state_module, name)
    self.state_list[name] = state_module
end

-- state: state name as defined with define_state
-- data: Anything you want to pass to the state in the states load function
function state:load(state_name, data)
    self.state = nil
    collectgarbage("collect")
    if self.state_list[state_name] then
        self.loadedStateName = state_name
        self.state = fs.load(self.state_list[state_name])()
        if type(self.state.load) == "function" then
            self.state:load(data)
        end
    else
        error(string.format("STATE: State '%s' does not exist!", state_name))
    end
end 

function state:unload()
    self.state = nil
end

function state:get_state()
    return self.state
end

--The following are callback functions
function state:update(dt)
    if type(self.state.update) == "function" then
        self.state:update(dt)
    end
end

function state:draw()
    if type(self.state.draw) == "function" then
        self.state:draw()
    end
end

function state:keypressed(key)
    if type(self.state.keypressed) == "function" then
        self.state:keypressed(key)
    end
end

function state:keyreleased(key)
    if type(self.state.keyreleased) == "function" then
        self.state:keyreleased(key)
    end
end

function state:mousepressed(x, y, key)
    if type(self.state.mousepressed) == "function" then
        self.state:mousepressed(x, y, key)
    end
end

function state:mousereleased(x, y, key)
    if type(self.state.mousereleased) == "function" then
        self.state:mousereleased(x, y, key)
    end
end

function state:wheelmoved(x, y)
    if type(self.state.wheelmoved) == "function" then
        self.state:wheelmoved(x, y)
    end
end

function state:quit()
    if type(self.state.quit) == "function" then
        self.state:quit()
    end
end

function state:textinput(t)
    if type(self.state.textinput) == "function" then
        self.state:textinput(t)
    end
end

return state