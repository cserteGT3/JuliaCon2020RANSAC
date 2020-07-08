module JuliaCon2020RANSAC

import Remark
import RANSAC
using RANSAC: IterLow1

using Logging
using LinearAlgebra
using ExtractMacro
using UnionFind
using NearestNeighbors: KDTree, inrange
using StaticArrays: SVector



export  makeslides,
        openslides


const SLIDE_FOLDER = joinpath(dirname(@__DIR__), "slides")
const SLIDE_FILE = joinpath(SLIDE_FOLDER, "JuliaCon2020.md")

makeslides() = Remark.slideshow(SLIDE_FILE, SLIDE_FOLDER, options=Dict("ratio"=>"16:9"))
openslides() = Remark.open(SLIDE_FOLDER)

export  FittedTranslational,
        ExtractedTranslational

include("translational/measures.jl")
include("translational/profit.jl")
include("translational/translational.jl")

end # module
