using Documenter, DataVisualization

let
    tabs_dir = joinpath(@__DIR__, "src", "tabs")
    generated_dir = joinpath(@__DIR__, "src", "generated")
    components_dir = joinpath(@__DIR__, "src", "components")
    for fn in readdir(tabs_dir)
        open(joinpath(generated_dir, fn), "w") do io
            for line in eachline(joinpath(tabs_dir, fn))
                m = match(r"{{([a-z]*)}}", line)
                if isnothing(m)
                    write(io, line)
                else
                    component = m[1]
                    path = joinpath(components_dir, m[1] * ".md")
                    write(io, read(path))
                end
            end
        end
end

makedocs(;
    modules=[DataVisualization],
    authors="Pietro Vertechi <pietro.vertechi@veos.digital>",
    repo="https://github.com/Veos-Digital/DataVisualization.jl/blob/{commit}{path}#{line}",
    sitename="Data Visualization",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
    ),
    pages=Any[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Tabs" => [
            "Load" => "tabs/load.md",
            "Filter" => "tabs/filter.md",
            "Predict" => "tabs/predict.md",
            "Cluster" => "tabs/cluster.md",
            "Project" => "tabs/project.md",
            "Visualize" => "tabs/visualize.md",
        ],
        "API" => "API.md",
    ],
    strict=true,
)

deploydocs(;
    repo="github.com/Veos-Digital/DataVisualization.jl",
    push_preview=true,
    devbranch="main",
)