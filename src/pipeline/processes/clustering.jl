struct Cluster <: AbstractProcessingStep
    table::Observable{SimpleTable}
    card::ProcessingCard
end

# TODO: add indirection layer with distance support, as in dimensionality reduction?
const clusterings = (
    kmeans=kmeans,
    mcl=mcl,
    affinityprop=affinityprop,
)

function Cluster(table::Observable{SimpleTable})
    analysis_names = collect(map(string, keys(clusterings)))

    analysis_options = vecmap(analysis_names) do name
        if name == "kmeans"
            name * " classes" => [string(i) for i in 1:100]
        else
            name => String[]
        end
    end

    default_names = ":cluster"

    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=["", "weights"]), ""),
        outputs=RichTextField("Outputs", ["" => ["cluster"]], default_names),
        method=RichTextField("Method", analysis_options, ""),
    )

    card = ProcessingCard(:Cluster; wdgs...)
    return Cluster(table, card)
end

function (cluster::Cluster)(data)
    card = cluster.card
    args, kwargs = extract_all_arguments(card.inputs)
    name = extract_positional_argument(card.outputs)

    dist = Euclidean() # TODO: make configurable
    cols = Tables.getcolumn.(Ref(data), Symbol.(args))
    X = reduce(vcat, transpose.(cols))
    D = pairwise(dist, X, dims=2)

    f = extract_function(card.method)
    an = clusterings[Symbol(f)]
    input = an === kmeans ? X : D
    positional, named = [], Pair{Symbol, Any}[Symbol(k) => Tables.getcolumn(data, Symbol(v)) for (k, v) in kwargs]
    for (k, v) in extract_named_arguments(card.method)
        if an === kmeans && k == "classes"
            push!(positional, parse(Int, v))
        else
            push!(named, Symbol(k) => v)
        end
    end
    anres = an(input, positional...; named...)
    return SimpleTable(Symbol(name) => map(nonnumeric, Clustering.assignments(anres)))
end
