## distance and normal computation of linesegments

"""
    midpoint(A, i)

Compute the midpoint of the i-th segment of a linesegment-list.
`A`: list of points.
"""
function midpoint(A, i)
    i == lastindex(A) && return (A[1]+A[end])/2
    return (A[i]+A[i+1])/2
end

"""
    nearestpoint(point, A)

Return the index of the nearest point from A to `point`.
`A`: list of points.
"""
function nearestpoint(point, A)
    di = norm(point-A[1])
    i = 1
    for j in eachindex(A)
        dj = norm(point-A[j])
        if dj < di
            di = dj
            i = j
        end
    end
    return di, i
end

"""
    twopointnormal(a)

Compute the normal of a segment. Inwards/outwards is not considered here.
The normal points towards "left".
`A`: list of points.
"""
function twopointnormal(a)
    dirv = normalize(a[2]-a[1])
    return normalize(convert(eltype(a), [-dirv[2], dirv[1]]))
end

"""
    segmentnormal(A, i)

Compute the normal of the i-th segment of a linesegment-list.
`A`: list of points.
"""
function segmentnormal(A, i)
    if i == lastindex(A)
        a = [A[end], A[1]]
        return twopointnormal(a)
    end
    b = @view A[i:i+1]
    return twopointnormal(b)
end

## not line but segment distances

"""
    segmentdistance(q, ab)

Distance from `q` to segment, which is just two points.
This distance is an absolute value.
(Distance to segment, not line!)
"""
function segmentdistance(q, ab)
    a = ab[1]
    b = ab[2]
    if isapprox(norm(b-a), 0)
        @warn "$ab is just a point, not a linesegment."
        return norm(q-a)
    end
    v = normalize(b-a)
    a2qv = dot(q-a,v)*v
    qv = a+a2qv
    dv = abs.(b-a)
    # indc = abs(bx-ax) > abs(by-ay) ? 1 : 2
    i = dv[1] > dv[2] ? 1 : 2
    t = (q[i]-a[i])/(b[i]-a[i])
    if t < 0
        return norm(q-a)
    elseif t > 1
        return norm(q-b)
    else
        return norm(q-qv)
    end
end

"""
    contourdistance(p, contour, i)

Distance of `p` from the `i`-th segment of `contour`.
Uses `segmentdistance`.
"""
function contourdistance(p, contour, i)
    if i == lastindex(contour)
        a = [contour[end], contour[1]]
        return segmentdistance(p, a)
    end
    b = @view contour[i:i+1]
    return segmentdistance(p, b)
end

# THIS SHOULD BE USED!!!!!!!!!!!!!!!!
"""
    dn2contour(point, contour)

Distance: distance from the nearest point of the contour point.
"""
function dn2contour(point, contour)
    d, i = nearestpoint(point, contour)
    i_1 = i==1 ? lastindex(contour) : i-1
    # original:
    #pn_ = (segmentnormal(contour, i_1)+segmentnormal(shape.contour, i))/2
    dss = [contourdistance(point, contour, is) for is in [i_1, i]]
    # 1. this leaves unwanted things
    #pn_ = segmentnormal(contour, [i_1, i][argmin(dss)])
    # 2.
    sdss = sum(dss)
    if isapprox(sdss, 0)
        # can't divide by 0
        pn_ = segmentnormal(contour, i)
    else
        pn_ = (dss[2]*segmentnormal(contour, i_1)+dss[1]*segmentnormal(contour, i))/sdss
    end
    return (d, pn_, i)
end

# THIS SHOULD BE USED!!!!!!!!!!!!!!!!
"""
    dn2shape_outw(point, shape)

Distance: distance from the nearest point of the shape.contour point.
Normal points always outwards. Use in CSG.
"""
function dn2shape_outw(point, shape)
    d, pn_, i = dn2contour(point, shape.contour)
    pn = shape.outwards * pn_
    dotp = dot(pn, point-shape.contour[i])
    signi = dotp < 0 ? -1 : 1
    return (signi*d, pn, i)
end

# THIS SHOULD BE USED!!!!!!!!!!!!!!!!
"""
    dn2shape_contour(point, shape)

Distance: distance from the nearest point of the shape.contour point.
Use in RANSAC.
"""
function dn2shape_contour(point, shape)
    d, pn_, i = dn2contour(point, shape.contour)
    pn = shape.flipnormal * pn_
    dotp = dot(pn, point-shape.contour[i])
    signi = dotp < 0 ? -1 : 1
    return (signi*d, pn, i)
end

function centroid(points)
    com = sum(points)
    return com/size(points, 1)
end