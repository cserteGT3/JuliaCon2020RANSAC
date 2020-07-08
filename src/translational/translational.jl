# Method:
# 1. van-e közös merőleges? nincs -> break
# 2. összes pont levetítése erre a síkra (egyik pont és a közös normális)
# 3. legkisebb és legnagyobb távolság megnézése
# 4. AABB
# 5. ha az AABB területe nagyon kicsi -> break
# 6. legnagyobb összefüggő terület
# 7. kontúr kiszedése: kell-e, hogy zárt görbe legyen? - szerintem kell -> 2 végpont összekötése
# 8. kör/egyenes illesztése
# 9. visszaellenőrzés?

abstract type AbstractTranslationalSurface <: RANSAC.FittedShape end

struct FittedTranslational <: AbstractTranslationalSurface
    coordframe
    contourindexes
    subsetnum::Int
end

struct ExtractedTranslational <: AbstractTranslationalSurface
    coordframe
    contour
    # center of gravity
    center
    # normal of the contour is parallel to the direction
    # towards the center of the contour?
    # == should flip the computed normals to direct outwards?
    # this is used in e.g. CSGBuilding
    # true means, that the computed normals must be turned to direct outside
    outwards::Int
    # should the computed normal be flipped to match the measured points
    # this is used in this package to ensure that in/outwards is correct
    # true means that computed normals must be turned to match the measured points
    flipnormal::Int
    # for visualization
    ft::FittedTranslational
end

function RANSAC.defaultshapeparameters(::Type{FittedTranslational})
    #ϵ = 0.3
    #α = deg2rad(5)
    # max deviaton of the normal being perpendicular to the translation direction
    #α_perpend = cosd(89)
    # maximum number of contours on a plane
    #TODO: delete this
    #max_group_num::Int = 3
    # maximum number of iterations of tryíng
    # to find < max_group_num number for contour patches
    #TODO: delete this
    #max_contour_it::Int = 5
    #thinning_par = 2.0
    # minimum % of the normals must be the same
    #min_normal_num = 0.9
    # extract translational surface even though normals are not ok
    #force_transl::Bool = false
    # thinning method: :slow/:fast/:deldir
    #thin_method::Symbol = :slow
    # how close must they be to consider them as the same point?
    #samep = Float64(eps(Float32))
    # check side parameter
    #checksidepar = 0.04
    # "disabled by default"
    #max_end_d = 10000.0

    tr = (ϵ = 0.3, α = deg2rad(5), α_perpend = cosd(89),
        diagthr = 0.1, max_group_num= 3, max_contour_it= 5, thinning_par = 2.0,
        min_normal_num = 0.9, force_transl = false, thin_method= :slow,
        samep = Float64(eps(Float32)), checksidepar = 0.04, max_end_d = 10000.0,)
    return (translational=tr,)
end

RANSAC.defaultshapeparameters(::Type{ExtractedTranslational}) = RANSAC.defaultshapeparameters(FittedTranslational)

Base.show(io::IO, x::FittedTranslational) = print(io, """FittedTranslational""")
Base.show(io::IO, x::ExtractedTranslational) = print(io, """ExtractedTranslational""")

Base.show(io::IO, ::MIME"text/plain", x::FittedTranslational) =
    print(io, """FittedTranslational""")

Base.show(io::IO, ::MIME"text/plain", x::ExtractedTranslational) =
    print(io, """ExtractedTranslational""")

RANSAC.strt(x::AbstractTranslationalSurface) = "translational"

RANSACVisualizer.getcolour(s::AbstractTranslationalSurface) = get(colorschemes[:seaborn_bright], 0.4)

function transldir(p, n, params)
    # 1. van-e közös merőleges? nincs -> break
    #@unpack α_perpend = params
    @extract params : myp=translational
    @extract myp : α_perpend
    is = [[1,2, 3], [2,3, 1], [3,1, 2]]
    ds = [abs(dot(n[i[1]], n[i[2]])) for i in is]
    sel_i = is[argmin(ds)]
    direction = normalize(cross(n[sel_i[1]], n[sel_i[2]]))
    isapprox(norm(direction), 1) || return (false, direction)
    abs(dot(direction, n[sel_i[3]])) < α_perpend && return (true, direction)
    return (false, direction)
end

"""
    project2sketchplane(pcr, indexes, transl_frame, params)

Project points defined by `indexes` (`pcr.vertices[indexes]`) to the plane defined by `transl_frame`.
All the points should be enabled.
Only those points are considered, whose normal is perpendicular to the plane.
"""
function project2sketchplane(pcr, indexes, transl_frame, params)
    #@unpack α_perpend = params
    @extract params : myp=translational
    @extract myp : α_perpend
    xv = transl_frame[1]
    yv = transl_frame[2]
    z = transl_frame[3]
    # enabled points and normals
    p = @view pcr.vertices[indexes]
    n = @view pcr.normals[indexes]

    projected = Array{SVector{2,Float64},1}(undef, 0)
    inds = Int[]
    for i in eachindex(p)
        # point is not part of the translational surface
        abs(dot(z, n[i])) > α_perpend && continue
        nv1 = dot(xv, p[i])
        nv2 = dot(yv, p[i])
        nvv = SVector{2, Float64}(nv1, nv2)
        push!(projected, nvv)
        push!(inds, indexes[i])
    end
    return projected, inds
end

"""
    project2sketchplane(points, transl_frame)

Just project the points to the plane.
"""
function project2sketchplane(points, transl_frame)
    xv = transl_frame[1]
    yv = transl_frame[2]
    projd = [SVector{2,Float64}(dot(xv, p), dot(yv, p)) for p in points]
    return projd
end

"""
    segmentpatches(points, ϵ_inrange)

Return connected patches of a pointcloud
"""
function segmentpatches(points, ϵ_inrange)
    btree = KDTree(points)
    uf = UnionFinder(size(points,1))

    for i in eachindex(points)
        inr = inrange(btree, points[i], ϵ_inrange)
        for j in eachindex(inr)
            # the point itself is always in range
            i == inr[j] && continue
            union!(uf, i, inr[j])
        end
    end
    return CompressedFinder(uf)
end

"""
    filtermultipoint!(points, indexes, params)

Filter out points that are close (params.samep) to each other.
Duplicates are removed inplace from the `points` and also their index from `indexes`.
"""
function filtermultipoint!(points, indexes, params)
    #@unpack samep = params
    @extract params : myp=translational
    @extract myp : samep
    btree = KDTree(points)
    trm = Int[]

    for i in eachindex(points)
        inr = inrange(btree, points[i], samep)
        for j in eachindex(inr)
            # i - current index
            # inr[j] - index of a point that is < eps at i
            # i itself is also in inr
            inr[j] <= i && continue
            push!(trm, inr[j])
        end
    end
    sort!(trm)
    unique!(trm)
    @logmsg IterLow1 "Deleted $(length(trm)) duplicates"
    deleteat!(indexes, trm)
    deleteat!(points, trm)
    return indexes
end

"""
    normaldirs(segments, points, normals, center, params)

Compute the normal directions.
This is based on the points, which are closer than `ϵ`.
Return a boolean first that indicates that the normals direct to the "same direction".
"""
function normaldirs(segments, points, normals, center, params)
    @assert size(points) == size(normals)
    function fff(msg)
        if ! (msg === nothing)
            @logmsg IterLow1 msg
        end
        return (false, false, false)
    end
    #@unpack ϵ, min_normal_num = params
    @extract params : myp=translational
    @extract myp : ϵ min_normal_num
    #calcs = [dist2segment(p, segments) for p in points]
    calcs = [dn2contour(p, segments) for p in points]
    compats = [abs(calcs[i][1]) < ϵ for i in eachindex(calcs)]
    compatsize = count(compats)
    compatsize == 0 && return fff("Compat size is 0.")
    # later working with points[compats]
    psize = size(points,1)
    flipnormal = Vector{Bool}(undef, psize)
    outwards = Vector{Bool}(undef, psize)
    for i in 1:psize
        # continue if not compatible
        compats[i] || continue
        # this is the fitted normal
        #contour_n = segmentnormal(segments, calcs[i][2])
        contour_n = calcs[i][2]
        #tocenter = normalize(center-midpoint(segments, calcs[i][3]))
        tocenter = normalize(center-segments[calcs[i][3]])

        # normal of the contour is parallel to the direction
        # towards the center of the contour?
        # == should flip the computed normals to direct outwards?
        # this is used in e.g. CSGBuilding
        outwards[i] = dot(contour_n, tocenter) < 0.0 ? false : true

        # should the computed normal be flipped to match the measured points
        # this is used in this package to ensure that in/outwards is correct
        flipnormal[i] = dot(contour_n, normals[i]) < 0.0 ? true : false
    end
    thisoutw = @view outwards[compats]
    outwr = count(thisoutw)/compatsize
    # can't agree on outwards
    (outwr > min_normal_num) || (outwr <= 1-min_normal_num) || return fff("Bad outwards.")

    # can't agree on flipnormals
    thisflip = @view flipnormal[compats]
    flipr = count(thisflip)/compatsize
    (flipr > min_normal_num) || (flipr <= 1-min_normal_num) || return fff("Bad flipsign.")
    # this means, that the computed normals must be turned to direct outside
    outwb = outwr > min_normal_num ? -1 : 1

    # this means that computed normals must be turned to match the measured points
    flipn = flipr > min_normal_num ? -1 : 1

    return (true, outwb, flipn)
end

"""
    checksides(points, multipl)

`multipl=0.02` for example.
"""
function checksides(points, params)
    #@unpack checksidepar = params
    @extract params : myp=translational
    @extract myp : checksidepar

    obb = RANSAC.findOBB_(points)
    sl1 = norm(obb[1]-obb[2])
    sl2 = norm(obb[1]-obb[3])
    sl3 = norm(obb[1]-obb[5])
    sls = [sl1, sl2, sl3]
    for i in 1:3
        for j in 1:3
            i == j && continue
            sls[i] < checksidepar*sls[j] && return (false, sls)
        end
    end
    return (true, sls)
end

function retnot(msg)
    if ! (msg === nothing)
        @logmsg IterLow1 msg
    end
    return nothing
end

function RANSAC.fit(::Type{FittedTranslational}, p, n, pcr, params)
    #@unpack α_perpend, diagthr, max_group_num = params
    #@unpack max_contour_it, thinning_par, ϵ, τ = params

    @extract params.iteration : τ
    @extract params : myp=translational
    @extract myp : α_perpend diagthr max_group_num
    @extract myp : max_contour_it thinning_par ϵ
    # Method:
    # 1. van-e közös merőleges? nincs -> break
    ok, dir = transldir(p, n, params)
    ok || return retnot("No translational direction.")
    # 2. összes pont levetítése erre a síkra (egyik pont és a közös normális)
    o = p[1]
    xv = n[1]
    zv = dir
    yv = normalize(cross(zv, xv))
    coordframe = [xv, yv, zv]

    #TODO: okosabb kéne ide
    # these are the enabled points from the first subset
    ien = pcr.isenabled
    subsnum = 1
    sbs = pcr.subsets[subsnum]
    # index in isenabled with the subset, to get those who are enabled in the subset
    # then use it to index into the subset
    used_i = @view sbs[ien[sbs]]
    projected, proj_ind = project2sketchplane(pcr, used_i, coordframe, params)
    size(projected, 1) < 2 && return retnot("No compatible points to transl. direction.")

    #=
    aabb = findAABB(projected)
    sidelength = aabb[2]-aabb[1]
    sidelength[1] < 0.02*sidelength[2] && return retnot("Bad: sidelength[1] < 0.01*sidelength[2]")
    sidelength[2] < 0.02*sidelength[1] && return retnot("Bad: sidelength[2] < 0.01*sidelength[1]")
    =#
    # 5. filter out points that are close to each other
    # for both the indexes and both the points
    #filtermultipoint!(projected, proj_ind, params)

    # 6. összefüggő kontúrok
    #thr = ϵ
    #maxit = max_contour_it

    spatchs = segmentpatches(projected, ϵ)
    #@infiltrate
    #=
    while spatchs.groups > max_group_num
        maxit < 1 && return retnot("Can't make max_group_num contours in max_contour_it. N of contours: $(spatchs.groups)")
        maxit -= 1
        thr = 1.01*thr
        spatchs = segmentpatches(projected, thr)
        #spatchs.groups <= max_group_num && break
    end
    =#
    # hereby spatchs should contain maximum max_group_num of patches
    fitresults = Array{FittedTranslational,1}(undef, 0)
    @logmsg IterLow1 "Nof groups: $(spatchs.groups)"
    for i in 1:spatchs.groups
        # i if part of the i-th group
        cur_group = findall(x->x==i, spatchs.ids)
        # at least 3 points please...
        size(cur_group,1) < 3 && continue
        patch_indexes = proj_ind[cur_group]
        # only extract contours that contain at least the minimumsize number of points
        size(patch_indexes, 1) < τ && continue
        #original:
        #size(patch_indexes, 1) < τ/size(pcr.subsets,1) && continue
        #@logmsg IterLow1 "Nof contour points: $(length(patch_indexes))"

        #=
        ppp = @view projected[cur_group]
        aabb = findAABB(ppp)
        sidelength = aabb[2]-aabb[1]
        sidelength[1] < 0.02*sidelength[2] && continue
        sidelength[2] < 0.02*sidelength[1] && continue
        cent = centroid(ppp)
        mavc = aabb[2]-cent
        mavc[1] < 0.02*mavc[2] && continue
        mavc[2] < 0.02*mavc[1] && continue
        # discard diagonal too
        =#

        # 4. OOBB
        # don't extract planes
        #TODO: azt kéne inkább nézni, hogy az egyik oldal nagyon kicsi a másikhoz képest=sík
        # if one of the side's length is <<< then the other -> nothing
        ppp = @view pcr.vertices[patch_indexes]
        goodside, sidel = checksides(ppp, params)
        if !goodside
            @logmsg IterLow1 "One side of OOBB is small: $sidel"
            continue
        end
        ft = FittedTranslational(coordframe, patch_indexes, subsnum)
        push!(fitresults, ft)
    end
    return fitresults
end

## scoring

function RANSAC.scorecandidate(pc, candidate::FittedTranslational, subsetID, params)
    inpoints = candidate.contourindexes
    subsID = candidate.subsetnum
    score = RANSAC.estimatescore(length(pc.subsets[subsID]), pc.size, length(inpoints))
    return (score, inpoints)
end

## refit

function compatiblesTranslational(shape, points, normals, params)
    @extract params : myp=translational
    @extract myp : α  ϵ

    # project to plane
    ps = project2sketchplane(points, shape.coordframe)
    ns = project2sketchplane(normals, shape.coordframe)

    calcs = (dn2shape_contour(p, shape) for p in ps)

    #=
    #eps check
    c1 = [abs(calcs[i][1]) < ϵ for i in eachindex(points)]
    #alpha check
    c2 = Vector{Bool}(undef, size(points))
    for i in eachindex(c2)
        #comp_n = contournormal(shape, calcs[i][2])
        comp_n = calcs[i][2]
        c2[i] = RANSAC.isparallel(comp_n, ns[i], α)
    end
    =#
    zpn = zip(calcs, ns)
    c = [(abs(cc[1]) < ϵ) && RANSAC.isparallel(cc[2], ni, α) for (cc,ni) in zpn]
    return c
end

"""
    refit(s::FittedTranslational, pc, params)

Refit translational.
"""
function RANSAC.refit(s::FittedTranslational, pc, params)
    @extract params : myp=translational
    @extract myp : ϵ force_transl thin_method
    @extract myp : thinning_par max_end_d

    cf = s.coordframe
    cidxs = s.contourindexes
    # 1. project points & normals
    old_p = @view pc.vertices[cidxs]
    o_pp = project2sketchplane(old_p, cf)

    filtermultipoint!(o_pp, cidxs, params)
    # this uses the filtered cidxs
    old_n = @view pc.normals[cidxs]
    o_np = project2sketchplane(old_n, cf)

    @logmsg IterLow1 "Thinning"
    # 2. thinning
    if thin_method === :fast
        thinned, _ = thinning(o_pp, thinning_par)
    elseif thin_method === :slow
        thinned, _ = thinning_slow(o_pp, thinning_par)
    elseif thin_method === :vordel
        # use the VoronoiDelaunay package
        #thinned, _ = thinning_deldir(o_pp, thinning_par)
        error("not implemented yet!")
    else
        error("thin method: $(thin_method) is not implemented!")
    end
    closed = [SVector{2,Float64}(th) for th in thinned]
    if norm(closed[1]-closed[end]) > max_end_d
        return retnot("max_end_d: $(norm(closed[1]-closed[end]))")
    end
    c = centroid(closed)
    @logmsg IterLow1 "Normaldirs"
    # 3. normaldirs()
    isok, outw, flips = normaldirs(closed, o_pp, o_np, c, params)
    (isok || force_transl) || return retnot("Normals not ok in refit.")
    et = ExtractedTranslational(cf, closed, c, outw, flips, s)
    @logmsg IterLow1 "Compatibles"
    # 4. search for all enabled and compatibel points
    # TODO: use octree for that
    p = @view pc.vertices[pc.isenabled]
    n = @view pc.normals[pc.isenabled]
    cp = compatiblesTranslational(et, p, n, params)
    ip = ((1:pc.size)[pc.isenabled])[cp]
    return RANSAC.ExtractedShape(et, ip)
end
