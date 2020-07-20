class: center, bottom

count: false

.top[# Efficient RANSAC in efficient Julia]

.bottom[.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/juliacon2020-banner.png" width="850">]]

---

# Introduction

.left[
[Tamás Cserteg](https://www.sztaki.hu/en/tamas-cserteg)



Research Laboratory on Engineering & Management Intelligence

Institute for Computer Science and Control (SZTAKI) - Budapest, Hungary

GitHub:  cserteGT3
]

--

### Agenda

1. Algorithm introduction
2. `RANSAC.jl` & `RANSACVisualier.jl` demo
3. Extensibility demo
4. Future plans

.footnote[Talk materials: [github.com/cserteGT3/JuliaCon2020RANSAC](https://github.com/cserteGT3/JuliaCon2020RANSAC)]

---
# Digital shape reconstruction

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/General-RE-framework.png" width="550">]

.left[.footnote[[Image source](https://www.researchgate.net/publication/321116176_Reverse_engineering_modeling_methods_and_tools_a_survey)]]

---

# Efficient RANSAC

### Goal

Recognize primitive shapes: planes, spheres, cylinders, cones, tori

--

### Algorithm

- Input: point cloud with surface normals
- Output: detected shapes and corresponding vertices

--

### Iteration

1. Sampling
2. Fitting
3. Scoring
4. Extraction (refitting)

---

# Demo

--

```julia
using FileIO
m = load("fandisk_input.obj");
using RANSACVisualizer
showgeometry(m.position, m.normals)
```

.center[<img src="https://csertegt3.github.io/RANSAC.jl/stable/img/showgeometry.png" width="400">]

.left[.footnote[[Demo source](https://csertegt3.github.io/RANSAC.jl/stable/example/)]]

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
common = (collin_threshold = 0.2, parallelthrdeg = 1),
plane = (ϵ = 0.05, α = 0.175),
cone = (ϵ = 0.05, α = 0.175, minconeopang = 0.0349),
cylinder = (ϵ = 0.05, α = 0.175),
sphere = (ϵ = 0.05, α = 0.175, sphere_par = 0.02))
```

---

# Demo

```julia
extr, _ = ransac(pc, p, true)
```

Result:

```julia
24-element Array{ExtractedShape,1}:
 Cand: (plane), 2205 ps
 Cand: (cylinder, R: 1.102), 738 ps
 Cand: (cylinder, R: 2.208), 625 ps
 ⋮
 Cand: (sphere, R: 15.194), 34 ps
 Cand: (cone, ω: 0.646), 60 ps
 Cand: (sphere, R: 1.935), 27 ps
```

---

# Demo

```julia
showbytype(pc, extr; show_axis = false)
```

.center[<img src="https://csertegt3.github.io/RANSAC.jl/stable/img/bytype.png" width="400">]

---

# Demo

```julia
exportJSON(stdout, extr, 2)
```

Result:

```json
{
  "primitives": [
    {
      "point": [
        1.953041,
        -2.0e-6,
        -13.371634
      ],
      "normal": [
        -0.0,
        1.0,
        -0.0
      ],
      "type": "plane"
    },
    ⋮
    ]
}
```

---

# Extensibility

--

- `MyShape <: FittedShape`
- `fit()`
- `score()`
- `refit()`

--
- `defaultshapeparameters()`

---

# Extensibility demo

### Parameters

--

```julia
julia> using RANSAC, UnPack

julia> p = ransacparameters([FittedPlane])
(iteration = (drawN = 3, minsubsetN = 15, prob_det = 0.9, shape_types = UnionAll[FittedPlane], τ = 900,
itermax = 1000, extract_s = :nofminset, terminate_s = :nofminset),
common = (collin_threshold = 0.2, parallelthrdeg = 1), plane = (ϵ = 0.3, α = 0.0873))

julia> p = ransacparameters(p, iteration=(prob_det=0.99,))
(iteration = (drawN = 3, minsubsetN = 15, prob_det = 0.99, shape_types = UnionAll[FittedPlane], τ = 900,
itermax = 1000, extract_s = :nofminset, terminate_s = :nofminset),
common = (collin_threshold = 0.2, parallelthrdeg = 1), plane = (ϵ = 0.3, α = 0.0873))

julia> p = ransacparameters(p, newshape=(ϵ=0.01, param1="typeA", param2=42,))
(iteration = (drawN = 3, minsubsetN = 15, prob_det = 0.99, shape_types = UnionAll[FittedPlane], τ = 900,
itermax = 1000, extract_s = :nofminset, terminate_s = :nofminset),
common = (collin_threshold = 0.2, parallelthrdeg = 1), plane = (ϵ = 0.3, α = 0.0873),
newshape = (ϵ = 0.01, param1 = "typeA", param2 = 42))

julia> @unpack newshape = p;

julia> newshape
(ϵ = 0.01, param1 = "typeA", param2 = 42)
```

---

# Extensibility demo

### Translational surface

--

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/m5_combined.png" width="600">]

---

# Extensibility demo

### Translational surface

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/transl_comparison2.png" width="700">]

---
count: false

# Extensibility demo

### Translational surface

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/transl_comparison.png" width="700">]

---

# Future plans

- Torus primitive
- Proper API in `RANSACVisualizer.jl`
- Performance optmizations
- Multi-threading
- Investigate further RANSAC variants (GlobFit, multiBaySAC, etc.)

---

# Summary

- Easy to use primitive recognition in 3D point clouds
- Flexbile tool for production and research
- Written in pure Julia

---

class: middle, center

count: false

# Thank you for your attention!
