local function slope(x1,y1,x2,y2)
    return (y2-y1)/(x2-x1)
end

local CEIL,FLOOR,MAX,MIN,ABS,SQRT,NEXT = math.ceil,math.floor,math.max,math.min,math.abs,math.sqrt,next

local interpolate_uv = require("core.3D.math.interpolate_uv")

local barycentric_coordinates = require("core.3D.geometry.bary_coords")
local interpolate_vertex_init = require("core.3D.geometry.interpolate_vertex")

local memory_manager = require("core.mem_manager")

local empty_table   = {}
local FRAGMENT_DATA = {}

return {build=function(BUS)
    BUS.log("  - Inicialized triangle rasterizer",BUS.log.info)

    local graphics_bus = BUS.graphics
    local mem_handle   = memory_manager.get(BUS)

    local interpolate_vertex = interpolate_vertex_init.init(BUS)

    return {triangle=function(t_data,fs,object,p1,p2,p3,tex,pixel_size,frag,stv1,stv2,stv3)
        local w,h = graphics_bus.w/pixel_size,graphics_bus.h/pixel_size

        if p1[2] > p3[2] then p1,p3 = p3,p1 end
        if p1[2] > p2[2] then p1,p2 = p2,p1 end
        if p2[2] > p3[2] then p2,p3 = p3,p2 end

        FRAGMENT_DATA.color   = object.color
        FRAGMENT_DATA.texture = (tex or empty_table).pixels
        FRAGMENT_DATA.tex     = tex
        FRAGMENT_DATA.v1      = stv1
        FRAGMENT_DATA.v2      = stv2
        FRAGMENT_DATA.v3      = stv3

        local FRAGMENT_INSTANTIATION = object.instantiate_fragment

        local split_alpha = (p2[2]-p1[2])/(p3[2]-p1[2])
        local split_point = interpolate_vertex(p1,p3,split_alpha)

        local left_point,right_point = p2,split_point
        if left_point[1] > right_point[1] then
            left_point,right_point = right_point,left_point
        end

        local delta_left_top  = 1/slope(p1[1],p1[2],left_point[1], left_point[2])
        local delta_right_top = 1/slope(p1[1],p1[2],right_point[1],right_point[2])

        local delta_left_bottom  = 1/slope(p3[1],p3[2],left_point[1], left_point[2])
        local delta_right_bottom = 1/slope(p3[1],p3[2],right_point[1],right_point[2])

        local x_left,x_right = p1[1],p1[1]

        local point_a,point_b,point_c = p1,left_point,right_point

        local v0u,v0v,v1u,v1v,v2u,v2v = point_a[5],point_a[6],point_b[5],point_b[6],point_c[5],point_c[6]

        local current_index     = 0
        local fragmented_data_1 = {}
        local fragmented_data_2 = {}
        local fragmented_data_3 = {}
        local fragment_naming   = {}
        local f1,f2,f3 = point_a.frag,point_b.frag,point_c.frag
        for k,v in NEXT,f1 do
            if f2[k] and f3[k] then
                current_index = current_index + 1

                fragmented_data_1[current_index] = v
                fragmented_data_2[current_index] = f2[k]
                fragmented_data_3[current_index] = f3[k]

                fragment_naming[current_index] = k
            end
        end
        local has_fragment = current_index > 0
        for y=MAX(FLOOR(p1[2]+0.5),1),MIN(FLOOR(left_point[2]+0.5)-1,h) do
            for x=MAX(CEIL(x_left-0.5),1),MIN(CEIL(x_right-0.5),w) do
                local bary_a,bary_b,bary_c = barycentric_coordinates(x,y,point_a,point_b,point_c)

                local pixel_z = point_a[3]*bary_a+point_b[3]*bary_b+point_c[3]*bary_c
                local pixel_w = point_a[4]*bary_a+point_b[4]*bary_b+point_c[4]*bary_c

                local z_correct = 1/pixel_z

                local PIXEL_DATA_STORAGE = FRAGMENT_INSTANTIATION and mem_handle.get_table(3) or t_data
                FRAGMENT_DATA.x = x
                FRAGMENT_DATA.y = y
                FRAGMENT_DATA.z_correct = z_correct

                local frag_data
                if has_fragment then frag_data = mem_handle.get_table(2) end
                for i=1,current_index do
                    local data_1,data_2,data_3 = fragmented_data_1[i],fragmented_data_2[i],fragmented_data_3[i]
                    
                    local interpolated_fragment = data_1*bary_a+data_2*bary_b+data_3*bary_c
                    frag_data[fragment_naming[i]] = interpolated_fragment*z_correct
                end
                if frag_data then FRAGMENT_DATA.data = frag_data end

                if tex then
                    local current_u,current_v = interpolate_uv(bary_a,bary_b,bary_c,v0u,v0v,v1u,v1v,v2u,v2v)
                    FRAGMENT_DATA.tx,FRAGMENT_DATA.ty = current_u,current_v
            
                    local bary_aright,bary_bright,bary_cright = barycentric_coordinates(x+1,y,  point_a,point_b,point_c)
                    local bary_adown,bary_bdown,bary_cdown    = barycentric_coordinates(x,  y+1,point_a,point_b,point_c)

                    local u_right,v_right = interpolate_uv(bary_aright,bary_bright,bary_cright,v0u,v0v,v1u,v1v,v2u,v2v)
                    local u_down ,v_down  = interpolate_uv(bary_adown,bary_bdown,bary_cdown,v0u,v0v,v1u,v1v,v2u,v2v)

                    local L = MAX(
                        ABS(current_u-u_right)*tex.w,ABS(current_v-v_right)*tex.h,
                        ABS(current_v-v_down) *tex.h,ABS(current_u-u_down) *tex.w
                    )

                    FRAGMENT_DATA.mipmap_level = L
                else
                    FRAGMENT_DATA.mipmap_level = 1
                    FRAGMENT_DATA.tx,FRAGMENT_DATA.ty = 0,0
                end

                frag(x,y,pixel_w,
                    fs(FRAGMENT_DATA,PIXEL_DATA_STORAGE)
                )
            end
        
            x_left,x_right = x_left+delta_left_top,x_right+delta_right_top
        end


        x_left,x_right = left_point[1],right_point[1]
        point_a,point_b,point_c = left_point,right_point,p3

        local v0u,v0v,v1u,v1v,v2u,v2v = point_a[5],point_a[6],point_b[5],point_b[6],point_c[5],point_c[6]

        local current_index     = 0
        local fragmented_data_1 = {}
        local fragmented_data_2 = {}
        local fragmented_data_3 = {}
        local fragment_naming   = {}
        local f1,f2,f3 = point_a.frag,point_b.frag,point_c.frag
        for k,v in NEXT,f1 do
            if f2[k] and f3[k] then
                current_index = current_index + 1

                fragmented_data_1[current_index] = v
                fragmented_data_2[current_index] = f2[k]
                fragmented_data_3[current_index] = f3[k]

                fragment_naming[current_index] = k
            end
        end
        local has_fragment = current_index > 0


        for y=MAX(FLOOR(left_point[2]+0.5),1),MIN(CEIL(p3[2]-0.5)-1,h) do
            for x=MAX(CEIL(x_left-0.5),1),MIN(CEIL(x_right-0.5),w) do
                local bary_a,bary_b,bary_c = barycentric_coordinates(x,y,point_a,point_b,point_c)

                local pixel_z = point_a[3]*bary_a+point_b[3]*bary_b+point_c[3]*bary_c
                local pixel_w = point_a[4]*bary_a+point_b[4]*bary_b+point_c[4]*bary_c

                local z_correct = 1/pixel_z

                local PIXEL_DATA_STORAGE = FRAGMENT_INSTANTIATION and mem_handle.get_table(3) or t_data
                FRAGMENT_DATA.x = x
                FRAGMENT_DATA.y = y
                FRAGMENT_DATA.z_correct = z_correct

                local frag_data
                if has_fragment then frag_data = mem_handle.get_table(2) end
                for i=1,current_index do
                    local data_1,data_2,data_3 = fragmented_data_1[i],fragmented_data_2[i],fragmented_data_3[i]
                    
                    local interpolated_fragment = data_1*bary_a+data_2*bary_b+data_3*bary_c
                    frag_data[fragment_naming[i]] = interpolated_fragment*z_correct
                end
                if frag_data then FRAGMENT_DATA.data = frag_data end

                if tex then
                    local current_u,current_v = interpolate_uv(bary_a,bary_b,bary_c,v0u,v0v,v1u,v1v,v2u,v2v)
                    FRAGMENT_DATA.tx,FRAGMENT_DATA.ty = current_u,current_v
            
                    local bary_aright,bary_bright,bary_cright = barycentric_coordinates(x+1,y,  point_a,point_b,point_c)
                    local bary_adown,bary_bdown,bary_cdown    = barycentric_coordinates(x,  y+1,point_a,point_b,point_c)

                    local u_right,v_right = interpolate_uv(bary_aright,bary_bright,bary_cright,v0u,v0v,v1u,v1v,v2u,v2v)
                    local u_down ,v_down  = interpolate_uv(bary_adown,bary_bdown,bary_cdown,v0u,v0v,v1u,v1v,v2u,v2v)

                    local L = MAX(
                        ABS(current_u-u_right)*tex.w,ABS(current_v-v_right)*tex.h,
                        ABS(current_v-v_down) *tex.h,ABS(current_u-u_down) *tex.w
                    )

                    FRAGMENT_DATA.mipmap_level = L
                else
                    FRAGMENT_DATA.mipmap_level = 1
                    FRAGMENT_DATA.tx,FRAGMENT_DATA.ty = 0,0
                end

                frag(x,y,pixel_w,
                    fs(FRAGMENT_DATA,PIXEL_DATA_STORAGE)
                )
            end

            x_left,x_right = x_left+delta_left_bottom,x_right+delta_right_bottom
        end
    end}
end}