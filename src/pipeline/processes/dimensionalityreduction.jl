struct DimensionalityReduction <: AbstractProcessingStep
    table::Observable{SimpleTable}
    card::ProcessingCard
end

function columns_out(step::DimensionalityReduction)
    card = step.card
    isempty(columns_in(card)) && return Symbol[]
    name = extract_positional_argument(card.outputs; strict=false)
    kwargs = extract_named_arguments(card.method; strict=false)
    dims = 0
    if all(!isnothing, (name, kwargs))
        for (k, v) in kwargs
            k == "dims" && (dims = parse(Int, v))
        end
    end
    return Symbol.(name, '_', 1:dims)
end

# Add custom type to represent multi-dimensional scaling
struct MDS end

# Unify interface on how to pass dims
_fit(::Type{PCA}, X; dims, kwargs...) = fit(PCA, X; maxoutdim=dims, pratio=1, kwargs...)
_fit(::Type{PPCA}, X; dims, kwargs...) = fit(PPCA, X; maxoutdim=dims, kwargs...)
_fit(::Type{FactorAnalysis}, X; dims, kwargs...) = fit(FactorAnalysis, X; maxoutdim=dims, kwargs...)
_fit(::Type{ICA}, X; dims, kwargs...) = fit(ICA, X, dims; kwargs...)

function test_dims(output; dims)
    _dims = size(output, 1)
    (_dims < dims) && error("Could only find $_dims dimensions. $dims were requested.")
    (_dims > dims) && error("Found too many dimensions.") # Should never happen
    return output
end

function project(an, data; dims, kwargs...)
    anres = _fit(an, data; dims, kwargs...)
    output = transform(anres, data)
    return test_dims(output; dims)
end

function project(::Type{MDS}, data; dims, distance=Euclidean(), kwargs...)
    output = classical_mds(pairwise(distance, data, dims=2), dims; kwargs...)
    return test_dims(output; dims)
end

const dimensionalityreductions = (
    pca=PCA,
    ppca=PPCA,
    factoranalysis=FactorAnalysis,
    ica=ICA,
    mds=MDS,
)

function DimensionalityReduction(table::Observable{SimpleTable})

    analysis_names = collect(map(string, keys(dimensionalityreductions)))

    analysis_options = vecmap(analysis_names) do name
        return name * " dims" => [string(i) for i in 1:100]
    end
    pushfirst!(analysis_options, "+" => String[])

    default_names = ":projection"

    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=[""]), ""),
        outputs=RichTextField("Outputs", ["" => ["projection"]], default_names),
        method=RichTextField("Method", analysis_options, ""),
    )

    card = ProcessingCard(:Project; wdgs...)
    return DimensionalityReduction(table, card)
end

function (dimres::DimensionalityReduction)(data)
    card = dimres.card
    args, kwargs = extract_all_arguments(card.inputs)
    name = extract_positional_argument(card.outputs)

    cols = Tables.getcolumn.(Ref(data), Symbol.(args))
    X = reduce(vcat, transpose.(cols))
    options = Pair{Symbol, Any}[Symbol(k) => Tables.getcolumn(data, Symbol(v)) for (k, v) in kwargs]
    for (k, v) in extract_named_arguments(card.method)
        if k == "dims"
            push!(options, :dims => parse(Int, v))
        else
            push!(options, Symbol(k) => v)
        end
    end

    f = extract_function(card.method)
    an = dimensionalityreductions[Symbol(f)]
    projected_data = project(an, X; options...)
    rows = eachrow(projected_data)
    return SimpleTable(
        Symbol.(name, '_', eachindex(rows)),
        collect(AbstractVector, rows)
    )
end
