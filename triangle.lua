local function make_triangle(p1,p2,p3,tex,frag)
    if p1[2] > p3[2] then p1,p3 = p3,p1 end
    if p1[2] > p2[2] then p1,p2 = p2,p1 end
    if p2[2] > p3[2] then p2,p3 = p3,p2 end

    local split_alpha (p2[2]-p1[2])/(p3[2]-p1[2])
    local split_x = (1-split_alpha)*p1[1] + split_alpha*p3[1]

end

return make_triangle