struct DimensionalityReduction{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

# Add custom type to represent multi-dimensional scaling
struct MDS end

# Unify interface on how to pass dims
_fit(::Type{PCA}, X; dims, kwargs...) = fit(PCA, X; maxoutdim=dims, pratio=1, kwargs...)
_fit(::Type{PPCA}, X; dims, kwargs...) = fit(PPCA, X; maxoutdim=dims, kwargs...)
_fit(::Type{FactorAnalysis}, X; dims, kwargs...) = fit(FactorAnalysis, X; maxoutdim=dims, kwargs...)
_fit(::Type{ICA}, X; dims, kwargs...) = fit(ICA, X, dims; kwargs...)

function project(an, data; dims, kwargs...)
    anres = _fit(an, data; dims, kwargs...)
    return transform(anres, data)
end

function project(::Type{MDS}, data; dims, distance=Euclidean(), kwargs...)
    return classical_mds(pairwise(distance, data, dims=2), dims; kwargs...)
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
        return name * " dims" => [string(i) for i in 1:100]
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

# TODO: force user to specify `dims`

function (dimres::DimensionalityReduction)(data)
    card = dimres.card
    inputs_call = only(card.inputs.parsed)
    method_call = only(card.method.parsed)
    rename_call = only(card.rename.parsed)
    name = only(rename_call.positional)

    cols = Tables.getcolumn.(Ref(data), Symbol.(inputs_call.positional))
    X = reduce(vcat, transpose.(cols))
    options = Pair{Symbol, Any}[Symbol(k) => Tables.getcolumn(data, Symbol(v)) for (k, v) in inputs_call.named]
    for (k, v) in method_call.named
        if k == "dims"
            push!(options, :dims => parse(Int, v))
        else
            push!(options, Symbol(k) => v)
        end
    end

    an = dimensionalityreductions[Symbol(only(method_call.fs))]
    projected_data = project(an, X; options...)
    rows = eachrow(projected_data)
    return LittleDict(Symbol(join([name, i], '_')) => row for (i, row) in enumerate(rows))
end
