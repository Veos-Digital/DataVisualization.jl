struct LinearModel <: AbstractProcessingStep
    table::Observable{SimpleTable}
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

# FIXME: remove `+` on first term
function LinearModel(table::Observable{SimpleTable})

    method_options = [
        "noise" => vecmap(string, keys(noises)),
        "link" => vecmap(string, keys(links)),
    ]

    default_names = ":prediction :error"

    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=["+ ", "* "]), ""),
        target=RichTextField("Target", data_options(table, keywords=[""]), ""),
        outputs=RichTextField("Outputs", ["" => ["prediction", "error"]], default_names),
        method=RichTextField("Method", method_options, ""),
    )

    card = ProcessingCard(:Predict; wdgs...)
    return LinearModel(table, card)
end

function (lm::LinearModel)(data)
    card = lm.card
    inputs_calls = card.inputs.parsed
    method_call = extract_call(card, :method)

    predictors = ConstantTerm(1)
    for call in inputs_calls
        predictors += combinations(map(Symbol, call.positional))
    end
    responsevariable = Symbol(extract_positional(card, :target))

    response = Term(responsevariable)
    formula = response ~ predictors

    pred_name, err_name = extract_positionals(card, :outputs, 2)
    distribution, link = Normal(), nothing
    for (k, v) in method_call.named
        k == "noise" && (distribution = noises[Symbol(v)]())
        k == "link" && (link = links[Symbol(v)]())
    end
    model = glm(formula, data, distribution, something(link, canonicallink(distribution)))
    anres = disallowmissing(predict(model, data)) # FIXME: support missing data in AoG
    return SimpleTable(
        Symbol(pred_name) => anres,
        Symbol(err_name) => Tables.getcolumn(data, responsevariable) - anres
    )
end
