using Documenter, DataVisualization

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
        "API" => "API.md",
    ],
    strict=true,
)

deploydocs(;
    repo="github.com/Veos-Digital/DataVisualization.jl",
    push_preview=true,
)