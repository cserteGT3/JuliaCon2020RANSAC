# Please follow the longer description in the documentation:
# https://csertegt3.github.io/RANSAC.jl/stable/example/

using FileIO
m = load("fandisk_input.obj");

using RANSACVisualizer
showgeometry(m.position, m.normals)

using RANSAC
pc = RANSACCloud(m.position, m.normals, 8)
p = ransacparameters()
newparams = (ϵ=0.05, α=deg2rad(10),)
p = ransacparameters(p, sphere=newparams, cone=newparams,
    plane=newparams, cylinder=newparams, iteration=(τ=50, itermax=100_000,))

extr, _ = ransac(pc, p, true)

showbytype(pc, extr; show_axis = false)
