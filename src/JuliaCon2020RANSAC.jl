module JuliaCon2020RANSAC

import Remark


export  makeslides,
        openslides


const SLIDE_FOLDER = joinpath(dirname(@__DIR__), "slides")
const SLIDE_FILE = joinpath(SLIDE_FOLDER, "JuliaCon2020.md")

makeslides() = Remark.slideshow(SLIDE_FILE, SLIDE_FOLDER, options=Dict("ratio"=>"16:9"))
openslides() = Remark.open(SLIDE_FOLDER)


end # module
