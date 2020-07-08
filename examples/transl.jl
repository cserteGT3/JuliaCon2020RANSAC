using JuliaCon2020RANSAC
using RANSAC
using StaticArrays
using FileIO

using RANSACVisualizer

fname = joinpath(@__DIR__, "examples", "models", "furcsa32k.obj")

m = load(fname)
pc = RANSACCloud(m.position, m.normals, 4)

defpars = ransacparameters([FittedSphere, FittedPlane, FittedCylinder, FittedTranslational])
defpars = ransacparameters([FittedSphere, FittedPlane, FittedCylinder])
planep = (ϵ = 0.2, α = deg2rad(4),)
spherep = (ϵ = 0.3, α = deg2rad(1),)
cylinderp = (ϵ = 0.4, α = deg2rad(7),)
conep = (ϵ = 0.2, α = deg2rad(1),)
#translp = (ϵ = 0.3, α = deg2rad(3), α_perpend = cosd(89.5), thinning_par=0.3/4, force_transl=false, thin_method=:slow, min_normal_num=0.99,)
translp = (ϵ = 0.2, α = deg2rad(1), α_perpend = cosd(89.5), thinning_par=0.3/4, force_transl=false, thin_method=:slow, min_normal_num=0.99,)

iterp = (minsubsetN=15, itermax=100, τ=1000, prob_det=0.99,)
params = ransacparameters(defpars, iteration=iterp, plane=planep, sphere=spherep, cylinder=cylinderp, cone=conep, translational=translp,)

extr, t = ransac(pc, params, true; reset_rand=true)

showshapes(pc, extr[2:end])
