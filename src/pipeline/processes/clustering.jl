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
    inputs_call = only(card.inputs.parsed)
    method_call = only(card.method.parsed)
    outputs_call = only(card.outputs.parsed)
    name = only(outputs_call.positional)

    dist = Euclidean() # TODO: make configurable
    cols = Tables.getcolumn.(Ref(data), Symbol.(inputs_call.positional))
    X = reduce(vcat, transpose.(cols))
    kws = map(((k, v),) -> Symbol(k) => Tables.getcolumn(data, Symbol(v)), inputs_call.named)
    D = pairwise(dist, X, dims=2)
    name = only(outputs_call.positional)

    an = clusterings[Symbol(only(method_call.fs))]
    input = an === kmeans ? X : D
    positional, named = [], collect(Pair, kws)
    for (k, v) in method_call.named
        if an === kmeans && k == "classes"
            push!(positional, parse(Int, v))
        else
            push!(named, Symbol(k) => v)
        end
    end
    anres = an(input, positional...; named...)
    return LittleDict(Symbol(name) => map(nonnumeric, Clustering.assignments(anres)))
end
