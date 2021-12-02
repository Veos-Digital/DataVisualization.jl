struct LinearModel{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

const noises = (normal=Normal, binomial=Binomial, gamma=Gamma, inversegaussian=InverseGaussian, poisson=Poisson)

const links = (
    cauchit=CauchitLink,
    cloglog=CloglogLink,
    idenitity=IdentityLink,
    inverse=InverseLink,
    inversesquare=InverseSquareLink,
    logit=LogitLink,
    log=LogLink,
    negativebinomial=NegativeBinomialLink,
    probit=ProbitLink,
    sqrt=SqrtLink,
)

interactionterm(v) = isempty(v) ? ConstantTerm(1) : mapfoldl(term, &, v)

# currently intercept is always added (with initial empty term), consider how to remove it
function combinations(v::AbstractVector{T}) where {T}
    subsets = [T[]]
    for el in v
        singleton = [el]
        for idx in eachindex(subsets)
            push!(subsets, vcat(subsets[idx], singleton))
        end
    end
    return mapfoldl(interactionterm, +, subsets)
end

function LinearModel(table::Observable)

    method_options = [
        "noise" => vecmap(string, keys(noises)),
        "link" => vecmap(string, keys(links)),
    ]

    default_names = ":prediction :error"

    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=["+ ", "* "]), ""),
        output=RichTextField("Outputs", data_options(table, keywords=[""]), ""),
        method=RichTextField("Method", method_options, ""),
        rename=RichTextField("Rename", ["" => ["prediction", "error"]], default_names)
    )

    card = ProcessingCard(:Predict; wdgs...)
    return LinearModel(table, card)
end

function (lm::LinearModel)(data)
    card = lm.card
    inputs_calls = card.inputs.parsed
    output_call = only(card.output.parsed)
    method_call = only(card.method.parsed)
    rename_call = only(card.rename.parsed)

    predictors = ConstantTerm(1)
    for call in inputs_calls
        predictors += combinations(map(Symbol, call.positional))
    end
    responsevariable = Symbol(only(output_call.positional))

    response = Term(responsevariable)
    formula = response ~ predictors

    pred_name, err_name = rename_call.positional
    distribution, link = Normal(), nothing
    for (k, v) in method_call.named
        k == "noise" && (distribution = noises[Symbol(v)]())
        k == "link" && (link = links[Symbol(v)]())
    end
    model = glm(formula, data, distribution, something(link, canonicallink(distribution)))
    anres = disallowmissing(predict(model, data)) # FIXME: support missing data in AoG
    return LittleDict(Symbol(pred_name) => anres, Symbol(err_name) => data[responsevariable] - anres)
end
