local make_triangle = require("triangle")

local block_size = 10
local border_thickness = 2

local function draw_block(x,y,color)
    love.graphics.setColor(color[1],color[2],color[3],color[4])
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

    love.graphics.setColor(1,0,0)
    love.graphics.points(x*block_size-block_size/2+border_thickness-1,y*block_size-block_size/2+border_thickness-1)

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

local function make_uv(u,v)
    return (u+1)/3,(v+1)/4
end

local function unmake_uv(u,v)
    local ox,oy = 1/3,1/4

    local range_x = 3/1
    local range_y = 4/2

    return (u-ox)*range_x,(v-oy)*range_y
end

local function uv_range(u,v)
    if u > 1 or u < 0 or v > 1 or v < 0 then
        error("invalid UV")
    end
end

local points   = {{85/10,147/10,1,make_uv(0,0)},{85/10,52/10,0,make_uv(1,0)},{180/10,147/10,1,make_uv(0,2)},{40,5,1,make_uv(1,2)}}
local coloring = {{1,0,0},{0,1,0},{0,0,1},{0,1,1}}

--local points   = {{5,1,1},{1,10,0.8},{10,15,0.5}}
--local coloring = {{1,0,0},{0,1,0},{0,0,1}}

local selected = 1

local image,image_w,image_h
function love.load()
    image = love.image.newImageData("test_cube.png")
    image_w,image_h = image:getDimensions()
end

local function draw_lines()
    love.graphics.line(points[1][1]*block_size,points[1][2]*block_size,points[2][1]*block_size,points[2][2]*block_size)
    love.graphics.line(points[2][1]*block_size,points[2][2]*block_size,points[3][1]*block_size,points[3][2]*block_size)
    love.graphics.line(points[3][1]*block_size,points[3][2]*block_size,points[1][1]*block_size,points[1][2]*block_size)

    love.graphics.line(points[2][1]*block_size,points[2][2]*block_size,points[3][1]*block_size,points[3][2]*block_size)
    love.graphics.line(points[3][1]*block_size,points[3][2]*block_size,points[4][1]*block_size,points[4][2]*block_size)
    love.graphics.line(points[4][1]*block_size,points[4][2]*block_size,points[2][1]*block_size,points[2][2]*block_size)
end

function love.draw()
    local grid = {
        {{0,0,0},{0,0,0},{0,0,0}},
        {{0,0,0},{0,0,0},{0,0,0}},
        {{0,0,0},{0,0,0},{0,0,0}}
    }
    fill_grid(grid,50,50)

    make_triangle(points[1],points[2],points[3],nil,function(x,y,u,v)
        local tex_x,tex_y = math.ceil(u*(image_w-1)-0.5)%image_w,math.ceil(v*(image_h-1)-0.5)%(image_h-1)
        local r,g,b,a = image:getPixel(tex_x,tex_y)

        --local u,v = unmake_uv(u,v)
        --uv_range(u,v)

        set_grid(grid,x+1,y+1,{r,g,b})
    end)
    make_triangle(points[2],points[3],points[4],nil,function(x,y,u,v)
        local tex_x,tex_y = math.ceil(u*(image_w-1)-0.5)%image_w,math.ceil(v*(image_h-1)-0.5)%(image_h-1)
        local r,g,b,a = image:getPixel(tex_x,tex_y)

        --local u,v = unmake_uv(u,v)
        --uv_range(u,v)

        set_grid(grid,x+1,y+1,{r,g,b})
    end)

    local x,y = screen_to_grid(love.mouse.getPosition())
    set_grid(grid,x,y,{1,0,0,0.2})

    for y,l in ipairs(grid) do
        for x,c in ipairs(l) do
            draw_block(x,y,c)
        end
    end

    for k,v in pairs(points) do
        local color = coloring[k]
        love.graphics.setColor(color[1],color[2],color[3])
        love.graphics.circle("fill",v[1]*block_size,v[2]*block_size,10)
    end

    local w,h = love.graphics.getDimensions()
    local selected_color = coloring[selected]

    love.graphics.setColor(selected_color[1],selected_color[2],selected_color[3])
    love.graphics.print(("selected: %d"):format(selected),6,h-20)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(0.5,0.5,0.5,0.5)
    draw_lines()
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,1,1,0.1)
    draw_lines()
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