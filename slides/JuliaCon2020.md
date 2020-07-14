class: middle, center

count: false

# Efficient RANSAC in efficient Julia
---

# Introduction

.left[
[Tamás Cserteg](https://www.sztaki.hu/en/tamas-cserteg)]

--

.left[
Research Laboratory on Engineering & Management Intelligence

Institute for Computer Science and Control (SZTAKI) - Budapest, Hungary

GitHub:  cserteGT3
]

---

# Agenda

1. Algorithm introduction
2. RANSAC.jl demo
3. Extensibility demo
4. Future plans

---
# Digital shape reconstruction

.center[<img src="https://www.laserdesign.com/wp-content/uploads/2014/10/ct-process.png" width="450">]

.left[.footnote[[Image source](https://www.laserdesign.com/wp-content/uploads/2014/10/ct-process.png)]]

---

# Efficient RANSAC

- input: point cloud with surface normals
- output: detected shapes and corresponding vertices

--

## Iteration

1. sampling
2. fitting
3. scoring
4. extraction (refitting)

---

# Demo

```julia
using FileIO
m = load("../fandisk_input.obj");
using RANSACVisualizer
showgeometry(m.position, m.normals)
```

.center[<img src="https://csertegt3.github.io/RANSAC.jl/dev/img/showgeometry.png" width="400">]

---

# Demo

```julia
using RANSAC
pc = RANSACCloud(m.position, m.normals, 8)
p = ransacparameters()
newparams = (ϵ=0.05, α=deg2rad(10),)
p = ransacparameters(p, sphere=newparams, cone=newparams,
    plane=newparams, cylinder=newparams, iteration=(τ=50, itermax=100_000,))
p
```

Result:

```julia
(iteration = (drawN = 3, minsubsetN = 15, prob_det = 0.9,
shape_types = UnionAll[FittedPlane, FittedCone, FittedCylinder, FittedSphere],
τ = 50, itermax = 100000, extract_s = :nofminset, terminate_s = :nofminset),
common = (collin_threshold = 0.2, parallelthrdeg = 1.0),
plane = (ϵ = 0.05, α = 0.17453292519943295),
cone = (ϵ = 0.05, α = 0.17453292519943295, minconeopang = 0.03490658503988659),
cylinder = (ϵ = 0.05, α = 0.17453292519943295),
sphere = (ϵ = 0.05, α = 0.17453292519943295, sphere_par = 0.02))
```

---

# Demo

```julia
extr, _ = ransac(pc, p, true, reset_rand=true)
```

Result:

```julia
23-element Array{ExtractedShape,1}:
 Cand: (plane), 2205 ps
 Cand: (cylinder, R: 1.101515), 738 ps
 Cand: (cylinder, R: 2.2075706), 625 ps
 ⋮
 Cand: (sphere, R: 15.193572), 34 ps
 Cand: (cone, ω: 0.64627165), 60 ps
 Cand: (sphere, R: 1.9352517), 27 ps
```

---

# Demo