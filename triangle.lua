local function slope(x1, y1, x2, y2)
    return (y2 - y1) / (x2 - x1)
end

local function make_triangle(p1, p2, p3, tex, frag)
    if p1[2] > p3[2] then p1, p3 = p3, p1 end
    if p1[2] > p2[2] then p1, p2 = p2, p1 end
    if p2[2] > p3[2] then p2, p3 = p3, p2 end

    local split_alpha = (p2[2] - p1[2]) / (p3[2] - p1[2])
    local split_x = (1 - split_alpha) * p1[1] + split_alpha * p3[1]
    local split_y = (1 - split_alpha) * p1[2] + split_alpha * p3[2]
    local split_z = (1 - split_alpha) * p1[3] + split_alpha * p3[3]
    local split_u = (1 - split_alpha) * p1[4] + split_alpha * p3[4]
    local split_v = (1 - split_alpha) * p1[5] + split_alpha * p3[5]

    local left_point, right_point = p2, { split_x, split_y, split_z ,split_u, split_v}
    if left_point[1] > right_point[1] then
        left_point, right_point = right_point, left_point
    end

    local delta_left_top     = 1 / slope(p3[1], p3[2], left_point[1], left_point[2])
    local delta_right_top    = 1 / slope(p3[1], p3[2], right_point[1], right_point[2])
    local delta_left_bottom  = 1 / slope(p1[1], p1[2], left_point[1], left_point[2])
    local delta_right_bottom = 1 / slope(p1[1], p1[2], right_point[1], right_point[2])

    local subpixel_bottom = math.floor(p1[2] + 0.5) + 0.5 - p1[2]
    local subpixel_top    = math.floor(p2[2] + 0.5) + 0.5 - left_point[2]

    local delta_z_left,delta_z_right
    local delta_u_left,delta_u_right
    local delta_v_left,delta_v_right

    if delta_left_top then
        delta_z_left  = (p3[3] - left_point[3])  / (p3[2] - left_point[2])
        delta_z_right = (p3[3] - right_point[3]) / (p3[2] - right_point[2])

        delta_u_left  = (p3[4] - left_point[4])  / (p3[2] - left_point[2])
        delta_u_right = (p3[4] - right_point[4]) / (p3[2] - right_point[2])

        delta_v_left  = (p3[5] - left_point[5])  / (p3[2] - left_point[2])
        delta_v_right = (p3[5] - right_point[5]) / (p3[2] - right_point[2])


        local x_left,x_right = left_point[1] + delta_left_top * subpixel_top, right_point[1] + delta_right_top * subpixel_top
        local z_left,z_right = left_point[3] + delta_z_left   * subpixel_top, right_point[3] + delta_z_right   * subpixel_top
        local u_left,u_right = left_point[4] + delta_u_left   * subpixel_top, right_point[4] + delta_u_right   * subpixel_top
        local v_left,v_right = left_point[5] + delta_v_left   * subpixel_top, right_point[5] + delta_v_right   * subpixel_top

        for y = math.floor(p2[2] + 0.5), math.ceil(p3[2] - 0.5) do
            local delta_z = (z_right - z_left) / (x_right - x_left)
            local delta_u = (u_right - u_left) / (x_right - x_left)
            local delta_v = (v_right - v_left) / (x_right - x_left)
            local z       = z_left
            local u       = u_left
            local v       = v_left
            for x = math.ceil(x_left - 0.5), math.ceil(x_right - 0.5) - 1 do
                frag(x, y, u, v, z)
                z = z + delta_z
                u = u + delta_u
                v = v + delta_v
            end

            x_left, x_right = x_left + delta_left_top, x_right + delta_right_top
            z_left, z_right = z_left + delta_z_left,   z_right + delta_z_right
            u_left, u_right = u_left + delta_u_left,   u_right + delta_u_right
            v_left, v_right = v_left + delta_v_left,   v_right + delta_v_right
        end
    end

    if delta_left_bottom then
        delta_z_left  = (p1[3] - left_point[3])  / (p1[2] - left_point[2])
        delta_z_right = (p1[3] - right_point[3]) / (p1[2] - right_point[2])

        delta_u_left  = (p1[4] - left_point[4])  / (p1[2] - left_point[2])
        delta_u_right = (p1[4] - right_point[4]) / (p1[2] - right_point[2])

        delta_v_left  = (p1[5] - left_point[5])  / (p1[2] - left_point[2])
        delta_v_right = (p1[5] - right_point[5]) / (p1[2] - right_point[2])

        local x_left, x_right = p1[1] + delta_left_bottom * subpixel_bottom, p1[1] + delta_right_bottom * subpixel_bottom
        local z_left, z_right = p1[3] + delta_z_left      * subpixel_bottom, p1[3] + delta_z_right      * subpixel_bottom
        local u_left, u_right = p1[4] + delta_u_left      * subpixel_bottom, p1[4] + delta_u_right      * subpixel_bottom
        local v_left, v_right = p1[5] + delta_v_left      * subpixel_bottom, p1[5] + delta_v_right      * subpixel_bottom

        for y = math.floor(p1[2] + 0.5), math.floor(p2[2] + 0.5) - 1 do
            local delta_z = (z_right - z_left) / (x_right - x_left)
            local delta_u = (u_right - u_left) / (x_right - x_left)
            local delta_v = (v_right - v_left) / (x_right - x_left)
            local z       = z_left
            local u       = u_left
            local v       = v_left

            for x = math.ceil(x_left - 0.5), math.ceil(x_right - 0.5) - 1 do
                frag(x, y, u, v, z)
                z = z + delta_z
                u = u + delta_u
                v = v + delta_v
            end

            x_left, x_right = x_left + delta_left_bottom, x_right + delta_right_bottom
            z_left, z_right = z_left + delta_z_left,      z_right + delta_z_right
            u_left, u_right = u_left + delta_u_left,      u_right + delta_u_right
            v_left, v_right = v_left + delta_v_left,      v_right + delta_v_right
        end
    end
end

return make_triangle