-- This system handels rendering objects in the simplest way possible.
return {
    filter = function(e)
        return e.visible or false
    end,

    process = function(e)
        if e.draw then
            e:draw()
        end
    end
}