struct DimensionalityReduction{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

function project(an, data, args...; kwargs...)
    anres = fit(an, data, args...; kwargs...)
    return transform(anres, data)
end

struct MDS end

function project(::Type{MDS}, data, args...; distance=Euclidean(), kwargs...)
    return classical_mds(pairwise(distance, data, dims=2), args...; kwargs...)
end

const dimensionalityreductions = (
    pca=PCA,
    ppca=PPCA,
    factoranalysis=FactorAnalysis,
    ica=ICA,
    mds=MDS,
)

function DimensionalityReduction(table::Observable)

    analysis_names = collect(map(string, keys(dimensionalityreductions)))

    analysis_options = vecmap(analysis_names) do name
        if name in ("mds", "ica")
            name * " dims" => [string(i) for i in 1:100]
        else
            name => String[]
        end
    end
    pushfirst!(analysis_options, "+" => String[])

    default_names = ":projection"

    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=[""]), ""),
        method=RichTextField("Method", analysis_options, ""),
        rename=RichTextField("Rename", ["" => ["projection"]], default_names)
    )

    card = ProcessingCard(:Project; wdgs...)
    return DimensionalityReduction(table, card)
end

function (dimres::DimensionalityReduction)(data)
    card = dimres.card
    inputs_call = only(card.inputs.parsed)
    method_call = only(card.method.parsed)
    rename_call = only(card.method.rename)
    name = only(rename_call.positional)

    result = to_littledict(data)
    cols = Tables.getcolumn.(Ref(data), Symbol.(inputs_call.positional))
    X = reduce(vcat, transpose.(cols))
    kws = map(((k, v),) -> Symbol(k) => Tables.getcolumn(data, Symbol(v)), inputs_call.named)

    an = dimensionalityreductions[Symbol(only(method_call.fs))]
    positional, named = [], collect(Pair, kws)
    for (k, v) in method_call.named
        if an in (ICA, MDS) && k == "dims"
            push!(positional, parse(Int, v))
        else
            push!(named, Symbol(k) => v)
        end
    end
    projected_data = project(an, X, positional...; named...)
    for (i, col) in enumerate(eachrow(projected_data))
        result[Symbol(join([name, i], '_'))] = col
    end
    return result
end
