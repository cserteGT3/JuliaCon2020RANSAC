# JuliaCon2020RANSAC.jl

<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg) -->
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
<!--
[![Build Status](https://travis-ci.com/cserteGT3/JuliaCon2020RANSAC.jl.svg?branch=master)](https://travis-ci.com/cserteGT3/JuliaCon2020RANSAC.jl)
[![codecov.io](http://codecov.io/github/cserteGT3/JuliaCon2020RANSAC.jl/coverage.svg?branch=master)](http://codecov.io/github/cserteGT3/JuliaCon2020RANSAC.jl?branch=master)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://cserteGT3.github.io/JuliaCon2020RANSAC.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://cserteGT3.github.io/JuliaCon2020RANSAC.jl/dev)
-->

This repository contains some code and the presentation for my Lightning Talk at [JuliaCon 2020](https://juliacon.org/2020/).
[Here](https://pretalx.com/juliacon2020/talk/XQ9YQK/) you can find the description of the talk.
The talk is about the Efficient RANSAC algorithm and it's Julia implementation.
You can read more in the [documentation](https://csertegt3.github.io/RANSAC.jl/stable/) of the [`RANSAC.jl`](https://github.com/cserteGT3/RANSAC.jl) package.

## Get the package

You can add this package as a Julia package, then you can compile the presentation if you wish:

```julia
] add https://github.com/cserteGT3/JuliaCon2020RANSAC
using JuliaCon2020RANSAC
makeslides()
openslides()
```

You can also find the compiled presentation in the `slides/build` folder.

## Test the examples

You can also find a few examples in the `examples/` folder, I suggest to try them out.
(The folder contains a project file too, to easily instantiate the environment.)
