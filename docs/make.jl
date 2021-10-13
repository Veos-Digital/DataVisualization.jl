using Documenter, DataVisualization

let dir = joinpath(@__DIR__, "src", "tabs")
    for fn in readdir(joinpath(dir, "src"))
        open(joinpath(dir, fn), "w") do io
            for line in eachline(joinpath(dir, "src", fn), keep=true)
                m = match(r"{{([a-z]*)}}", line)
                if isnothing(m)
                    write(io, line)
                else
                    component = m[1]
                    path = joinpath(dir, "components", m[1] * ".md")
                    write(io, read(path))
                end
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