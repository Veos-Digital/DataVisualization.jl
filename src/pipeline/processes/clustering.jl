struct Cluster{T}
    table::Observable{T}
    card::ProcessingCard
end

# TODO: add indirection layer with distance support, as in dimensionality reduction?
const clusterings = (
    kmeans=kmeans,
    mcl=mcl,
    affinityprop=affinityprop,
)

function Cluster(table::Observable{T}) where {T}
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
        method=RichTextField("Method", analysis_options, ""),
        rename=RichTextField("Rename", ["" => ["cluster"]], default_names)
    )

    card = ProcessingCard(:Cluster; wdgs...)
    return Cluster(table, card)
end

jsrender(session, cluster::Cluster) = jsrender(session, cluster.card)

function compute(cluster::Cluster, data)
    dist = Euclidean() # TODO: make configurable
    result = to_littledict(data)
    inputs_call = only(cluster.card.inputs.parsed)
    cols = Tables.getcolumn.(Ref(data), Symbol.(inputs_call.positional))
    X = reduce(vcat, transpose.(cols))
    kws = map(((k, v),) -> Symbol(k) => Tables.getcolumn(data, Symbol(v)), inputs_call.named)
    D = pairwise(dist, X, dims=2)

    method_call = only(cluster.card.method.parsed)
    rename_call = only(cluster.card.method.rename)
    name = only(rename_call.positional)

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
    result[Symbol(name)] = map(nonnumeric, Clustering.assignments(anres))
    return result
end
