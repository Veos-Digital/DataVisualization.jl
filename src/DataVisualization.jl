module DataVisualization

using Observables
using JSServe
using JSServe: evaljs, onjs, onload, Table, Server
import Tables, CSV
import JSServe: jsrender
using Sockets
using StructArrays: uniquesorted, finduniquesorted, components, StructArray
using Observables: to_value
using Makie: plot!, RGB, Axis, Scene, Figure, Makie
using Makie: Scatter, Lines, BarPlot, BoxPlot, Violin, propertynames
using Makie.Colors
using WGLMakie
using AlgebraOfGraphics
using AlgebraOfGraphics: density, Layers
using StatsBase: histrange, fit
using MultivariateStats: PCA,
                         PPCA,
                         FactorAnalysis,
                         ICA,
                         classical_mds,
                         transform
using OrderedCollections
using Graphs: SimpleDiGraph, add_edge!, inneighbors, topological_sort_by_dfs
using Distances: Euclidean, pairwise
using Clustering
using GLM, StatsModels
using Missings: disallowmissing

export UI
export set_aog_theme!, update_theme!

WGLMakie.activate!()

dependency_path(fn) = joinpath(@__DIR__, "..", "js_dependencies", fn)

const FormsCSS = JSServe.Asset(dependency_path("forms.min.css"))
const TailwindCSS = JSServe.Asset(dependency_path("tailwind.min.css"))
const AllCSS = (TailwindCSS, FormsCSS)

const UtilitiesJS = JSServe.Dependency(
    :utilities,
    [dependency_path("utilities.js")]
)

const agGrid = JSServe.Dependency(
    :agGrid,
    [
        dependency_path("ag-grid-community.min.noStyle.js"),
        dependency_path("ag-grid.css"),
        dependency_path("ag-grid-custom-theme.css"),
    ]
)

abstract type AbstractPipeline{T} end
abstract type AbstractVisualization{T} end

output(p::AbstractPipeline) = p.value

include("utils.jl")
include("components/filepicker.jl")
include("components/checkboxes.jl")
include("components/rangeselector.jl")
include("components/togglers.jl")
include("components/tabs.jl")
include("components/tabular.jl")
include("components/optionlist.jl")
include("components/autocomplete.jl")
include("components/filters.jl")
include("components/editablelist.jl")
include("components/processing_card.jl")
include("pipeline/processes/linearmodel.jl")
include("pipeline/processes/clustering.jl")
include("pipeline/processes/dimensionalityreduction.jl")
include("pipeline/load.jl")
include("pipeline/filter.jl")
include("pipeline/process.jl")
include("visualization/chart.jl")
include("visualization/spreadsheet.jl")
include("app.jl")

end
