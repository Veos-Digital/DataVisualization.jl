module DataVisualization

using Observables
using Observables: to_value, AbstractObservable
using JSServe
using JSServe: evaljs, onjs, onload, Table, Server
import Tables, CSV
import JSServe: jsrender
using Sockets
using StructArrays: uniquesorted, finduniquesorted, components, StructArray
using Makie: plot!, RGB, Axis, Scene, Figure, Makie
using Makie: Scatter, Lines, BarPlot, BoxPlot, Violin, propertynames
using Makie.Colors
using WGLMakie
using AlgebraOfGraphics
using AlgebraOfGraphics: density, Layers
using Statistics: mean, std, Statistics
using StatsBase: histrange, fit, quantile, StatsBase
using MultivariateStats: PCA,
                         PPCA,
                         FactorAnalysis,
                         ICA,
                         classical_mds,
                         transform
using Graphs: SimpleDiGraph, add_edge!, inneighbors, ne, topological_sort_by_dfs
using LayeredLayouts, GraphMakie
using Distances: Euclidean, pairwise
using REPL: levenshtein
using Clustering
using GLM, StatsModels
using Missings: disallowmissing

import RelocatableFolders: @path

export UI
export set_aog_theme!, update_theme!

WGLMakie.activate!()

const dependency_folder = @path joinpath(dirname(@__DIR__), "js_dependencies")
dependency_path(fn) = joinpath(dependency_folder, fn)

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

const ace = JSServe.Dependency(
    :ace,
    [
        dependency_path("ace.js"),
        dependency_path("ext-language_tools.js"),
        dependency_path("mode-julia.js"),
    ]
)

const AllDeps = (UtilitiesJS, agGrid, ace)

abstract type AbstractPipeline end
abstract type AbstractVisualization end

output(p::AbstractPipeline) = p.value

include("types.jl")
include("utils.jl")
include("vertices.jl")
include("components/filepicker.jl")
include("components/checkboxes.jl")
include("components/editor.jl")
include("components/rangeselector.jl")
include("components/togglers.jl")
include("components/tabs.jl")
include("components/tabular.jl")
include("components/optionlist.jl")
include("components/autocomplete.jl")
include("components/filters.jl")
include("components/editablelist.jl")
include("components/processing_card.jl")
include("pipeline/processes/clustering.jl")
include("pipeline/processes/dimensionalityreduction.jl")
include("pipeline/processes/linearmodel.jl")
include("pipeline/processes/wildcard.jl")
include("pipeline/load.jl")
include("pipeline/filter.jl")
include("pipeline/preprocess.jl")
include("pipeline/process.jl")
include("visualization/chart.jl")
include("visualization/pipelines.jl")
include("visualization/spreadsheet.jl")
include("app.jl")

end
