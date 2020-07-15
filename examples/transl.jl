using JuliaCon2020RANSAC
using RANSAC
using StaticArrays
using FileIO

using RANSACVisualizer
using Makie

fname = joinpath(@__DIR__, "models", "furcsa32k.obj")

m = load(fname)
pc = RANSACCloud(m.position, m.normals, 4)

## Without translational
defpars = ransacparameters([FittedSphere, FittedPlane, FittedCylinder])
planep = (ϵ = 0.2, α = deg2rad(4),)
spherep = (ϵ = 0.3, α = deg2rad(1),)
cylinderp = (ϵ = 0.4, α = deg2rad(7),)
conep = (ϵ = 0.2, α = deg2rad(1),)
iterp = (minsubsetN=15, itermax=10000, τ=1200, prob_det=0.99,)
params = ransacparameters(defpars, iteration=iterp, plane=planep, sphere=spherep, cylinder=cylinderp, cone=conep,)

extr2, t = ransac(pc, params, true; reset_rand=true)
showshapes(pc, extr2, show_axis = false)
sc = showbytype(pc, extr2, show_axis = false, resolution=(1920,1080))
sc.center = false
save("no_transl.png", sc)

## With translational
defpars = ransacparameters([FittedSphere, FittedPlane, FittedCylinder, FittedTranslational])
translp = (ϵ = 0.3, α = deg2rad(3), α_perpend = cosd(89.5), thinning_par=0.3/4, force_transl=false, thin_method=:slow, min_normal_num=0.99,)

params = ransacparameters(defpars, iteration=iterp, plane=planep, sphere=spherep, cylinder=cylinderp, cone=conep, translational=translp,)

extr, t = ransac(pc, params, true; reset_rand=true)

showshapes(pc, extr)
sc2 = showbytype(pc, extr, show_axis = false, resolution=(1920,1080))
sc2.center = false
save("transl.png", sc2)
