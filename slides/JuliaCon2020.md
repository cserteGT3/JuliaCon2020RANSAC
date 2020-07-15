class: center, bottom

count: false

.top[# Efficient RANSAC in efficient Julia]

.bottom[.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/juliacon2020-banner.png" width="850">]]

???
Welcome Everyone,
I am Tamás Cserteg from SZTAKI, Hungary and in this Lightning Talk I will introduce the RANSAC.jl package that implements the efficient RANSAC algorithm.
---

# Introduction

.left[
[Tamás Cserteg](https://www.sztaki.hu/en/tamas-cserteg)



Research Laboratory on Engineering & Management Intelligence

Institute for Computer Science and Control (SZTAKI) - Budapest, Hungary

GitHub:  cserteGT3
]

???
To the best of my knowledge, general implementations have been published only in C++ so far, so maybe this is the first one written completely in a different language.

--

### Agenda

1. Algorithm introduction
2. `RANSAC.jl` & `RANSACVisualier.jl` demo
3. Extensibility demo
4. Future plans

.footnote[Talk materials: [github.com/cserteGT3/JuliaCon2020RANSAC](https://github.com/cserteGT3/JuliaCon2020RANSAC)]

???
Here you can also see the agenda, and I would like to point out, that every material is available at my github repo.

---
# Digital shape reconstruction

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/General-RE-framework.png" width="550">]

.left[.footnote[[Image source](https://www.researchgate.net/publication/321116176_Reverse_engineering_modeling_methods_and_tools_a_survey)]]

???
So the topic that we are dealing with is digital shape reconstruction.

The whole process looks like the following: we have an object and we would like to reconstruct a digital model of it.

We take measurements with an appropriate device, which in most cases returns a point cloud or a mesh.

This is already a digital representation, but we want to describe its structure in a higher level.

---

# Efficient RANSAC

### Goal

Recognize primitive shapes: planes, spheres, cylinders, cones, tori

???
One way to acquire a such representation is to identify primitive shapes in the point cloud, such as planes, spheres, etc.

The efficient RANSAC algorithm offers a fast solution for this problem.
--

### Algorithm

- Input: point cloud with surface normals
- Output: detected shapes and corresponding vertices

???
Input of the algorithm is a point cloud with surface normals and the output is a set of primitive shapes with the corresponding points.

It is common in the above listed primitive shapes, that they can be defined by at most 3 point-normal pairs.

So our iterative algorithm looks like the following:

--

### Iteration

1. Sampling
2. Fitting
3. Scoring
4. Extraction (refitting)

???
In every iteration, we sample 3 point-normal pairs and try to fit all the primitives to those pairs. We discard the invalid candidates and collect the valid ones.

We rank the candidates based on a scoring function that counts the number of compatible points. Compatibility means here that the point is approximated by the shape candidate with a given threshold.

We continually evaluate the scores and extract the best one if the probability that no better candidates are in the list is high enough.

The to be extracted shape is refitted to filter out present noise.

We keep iterating until we conclude that with the given probability, no more candidates can be found in the point cloud.

---

# Demo

???
Now lets see, how can we use this with the RANSAC package. 
--

```julia
using FileIO
m = load("fandisk_input.obj");
using RANSACVisualizer
showgeometry(m.position, m.normals)
```

.center[<img src="https://csertegt3.github.io/RANSAC.jl/stable/img/showgeometry.png" width="400">]

.left[.footnote[[Demo source](https://csertegt3.github.io/RANSAC.jl/stable/example/)]]

???
First we need a mesh, that we load with MeshIO.jl.

The RANSACVisualizer package contains a couple convenience functions to visualize inputs and outputs with the help of Makie.jl.

Here we can inspect the vertices and normals.

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
???
Then we construct a ransac cloud that wraps the point cloud and other variables as well.

Then we construct the parameters and override those that we wish.
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

???
Then we run the algorithm.

In this case we found 24 primitives.

---

# Demo

```julia
showbytype(pc, extr; show_axis = false)
```

.center[<img src="https://csertegt3.github.io/RANSAC.jl/stable/img/bytype.png" width="400">]

???
With the help of RANSACVisualizer you can also plot the resulted shapes, here they are coloured by their type.

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

???
You can also save the results to JSON strings for further processing.

---

# Extensibility

???
In the second half of the talk, I’d like to show, how to extend the list of primitive shapes, because this is a major advantage over the C++ implementations.

--

- `MyShape <: FittedShape`
- `fit()`
- `score()`
- `refit()`

???
Basically, to define a primitive shape, one must define a new type and three functions.

The 3 functions obviously implement the stages of the iteration.
--
- `defaultshapeparameters()`

???
One must also implement the default shape parameters function to supply the parameters.

---

# Extensibility demo

### Parameters

???
As in any scientific computing task, we need parameters, thresholds, etc. to fine tune the algorithm.

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

???
My first choice was the Parameters.jl package, but I couldn’t find a way to extend it if new parameters are introduced for a new primitive.

Therefore I went for nested NamedTuples, as they can be easily extended and altered and the  @unpack macro can be used on them as well.

As you can see here ransacparameters() return a NamedTuple, and as you can see one can alter the value of a parameter, for example here we change the detection probability.

You can also easily extend it with new parameters, if you introduce a new shape as you can see in the last line.

---

# Extensibility demo

### Translational surface

???
But why do we want to add a new primitive?

Because then the package can be used for scientific experiments.

For example in my master’s thesis I investigated if we could use translational surfaces as a new primitive, because they are widely used in Computer Aided Design.

--

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/m5_combined.png" width="600">]

???
The code wouldn’t fit to the slides, but I can show you some of my results.

Here you can see an object whose outer surface is defined by an extruded contourline.

---

# Extensibility demo

### Translational surface

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/transl_comparison2.png" width="700">]

???
If we run the RANSAC algorithm on it, we get the followings:

On the left side I didn’t use the new translational primitive, and you can see that we couldn’t recognize this wave shape in the front of the object.

---
count: false

# Extensibility demo

### Translational surface

.center[<img src="https://github.com/cserteGT3/JuliaCon2020RANSAC/raw/master/slides/images/transl_comparison.png" width="700">]

???
However using the new primitive, the whole object can be described, and we also need less primitives.

---

# Future plans

- Torus primitive
- Proper API in `RANSACVisualizer.jl`
- Performance optmizations
- Multi-threading
- Investigate further RANSAC variants (GlobFit, multiBaySAC, etc.)

???
And finally a few words of what I am planning for the future:

The torus primitive is still not implemented, and a proper API is needed for the RANSACVisualizer package

I need to make couple changes to further optimise speed including multi-threading, if possible.

Long term plan is to investigate further RANSAC variants if they could be incorporated into this package.

---

# Summary

- Easy to use primitive recognition in 3D point clouds
- Flexbile tool for production and research
- Written in pure Julia

???
To conclude: with the efficient RANSAC algorithm one can easily recognize primitive shapes in 3d point clouds.

The RANSAC.jl package is a flexible tool for production and also for scientific exploration.

And it is written in pure Julia.

---

class: middle, center

count: false

# Thank you for your attention!

???
Thank you for your attention!
