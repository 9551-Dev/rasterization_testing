local make_triangle = require("triangle")

local block_size = 10
local border_thickness = 2

local function draw_block(x,y,color)
    love.graphics.setColor(color[1],color[2],color[3])
    for block_x=(x-1)*block_size,(x-1)*block_size+block_size do
        for block_y=(y-1)*block_size,(y-1)*block_size+block_size do
            love.graphics.points(block_x+border_thickness-1,block_y+border_thickness-1)
        end
    end
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.setPointSize(border_thickness)
    for block_x=(x-1)*block_size,(x-1)*block_size+block_size,border_thickness do
        love.graphics.points(block_x+border_thickness-1,(y-1)*block_size+border_thickness-1)
    end
    for block_y=(y-1)*block_size-1,(y-1)*block_size+block_size-1 do
        love.graphics.points((x-1)*block_size+border_thickness-1,block_y+border_thickness)
        love.graphics.points((x-1)*block_size+block_size+border_thickness-1,block_y+border_thickness)
    end
    for block_x=(x-1)*block_size,(x-1)*block_size+block_size,border_thickness do
        love.graphics.points(block_x+border_thickness-1,(y-1)*block_size+block_size+border_thickness-1)
    end
    love.graphics.setPointSize(1)
end

local function screen_to_grid(x,y)
    return math.ceil(x/block_size),math.ceil(y/block_size)
end

local function set_grid(grid,x,y,val)
    if grid[y] and grid[y][x] then
        grid[y][x] = val
    end
end

local function fill_grid(grid,w,h)
    for y=1,h do
        local t = {}
        for x=1,w do
            t[x] = {0,0,0}
        end
        grid[y] = t
    end
end

local points   = {{1,1,1},{5,1,1},{1,5,1}}
local coloring = {{1,0,0},{0,1,0},{0,0,1}}

local selected = 1

function love.draw()
    local grid = {
        {{0,0,0},{0,0,0},{0,0,0}},
        {{0,0,0},{0,0,0},{0,0,0}},
        {{0,0,0},{0,0,0},{0,0,0}}
    }
    fill_grid(grid,50,50)

    make_triangle(points[1],points[2],points[3],nil,function(x,y,r,g,b)
        set_grid(grid,x,y,{r,g,b})
    end)

    local x,y = screen_to_grid(love.mouse.getPosition())
    set_grid(grid,x,y,{1,0,0})

    for y,l in ipairs(grid) do
        for x,c in ipairs(l) do
            draw_block(x,y,c)
        end
    end

    for k,v in pairs(points) do
        local color = coloring[k]
        love.graphics.setColor(color[1],color[2],color[3])
        love.graphics.circle("fill",v[1]*block_size-block_size/3,v[2]*block_size-block_size/3,10)
    end

    local w,h = love.graphics.getDimensions()
    local selected_color = coloring[selected]
    love.graphics.setColor(selected_color[1],selected_color[2],selected_color[3])
    love.graphics.print(("selected: %d"):format(selected),1,h-20)
end

function love.wheelmoved(dx,dy)
    local new_selected = selected + dy
    if new_selected < 1 then new_selected = #points end
    if new_selected > #points then new_selected = 1 end
    selected = new_selected
end

function love.mousepressed(x,y,button)
    local grid_x,grid_y = (x+block_size/3)/block_size,(y+block_size/3)/block_size
    points[selected][1] = grid_x
    points[selected][2] = grid_y
end