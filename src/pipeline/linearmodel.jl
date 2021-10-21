struct LinearModel{T} <: AbstractPipeline{T}
    table::Observable{T}
    value::Observable{T}
end

LinearModel(table::Observable{T}) where {T} = LinearModel{T}(table, Observable{T}(table[]))

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

function jsrender(session::Session, lm::LinearModel)

    wdgs = LittleDict()

    wdgs["Inputs"] = Autocomplete(session, Observable(""), data_options(session, lm.table, keywords=["", "+ ", "* "]))

    wdgs["Output"] = Autocomplete(session, Observable(""), data_options(session, lm.table, keywords=[""]))

    method_options = [
        "noise" => vecmap(string, keys(noises)),
        "link" => vecmap(string, keys(links)),
    ]

    wdgs["Method"] = Autocomplete(session, Observable(""), method_options)

    default_names = ":prediction :error"

    wdgs["Rename"] = Autocomplete(session, Observable(default_names), ["" => ["prediction", "error"]])

    tryon(session, lm.table) do table
        lm.value[] = table
    end

    process_button = Button("Process", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))

    tryon(session, process_button.value) do _
        local table = lm.table[]
        result = to_littledict(table)

        # parse textbox value to formula
        responsevariable = nothing
        predictors = ConstantTerm(1)
        for call in compute_calls(wdgs["Inputs"].value[])
            predictors += combinations(map(Symbol, call.positional))
        end
        output_call = only(compute_calls(wdgs["Output"].value[]))
        responsevariable = Symbol(only(output_call.positional))

        response = Term(responsevariable)
        formula = response ~ predictors

        method_call = only(compute_calls(wdgs["Method"].value[]))
        rename_call = only(compute_calls(wdgs["Rename"].value[]))
        pred_name, err_name = rename_call.positional
        distribution, link = Normal(), nothing
        for (k, v) in method_call.named
            k == "noise" && (distribution = noises[Symbol(v)]())
            k == "link" && (link = links[Symbol(v)]())
        end
        model = glm(formula, table, distribution, something(link, canonicallink(distribution)))
        anres = disallowmissing(predict(model, table)) # FIXME: support missing data in AoG
        result[Symbol(pred_name)] = anres
        result[Symbol(err_name)] = result[responsevariable] - anres

        lm.value[] = result
    end

    tryon(session, clear_button.value) do _
        lm.value[] = lm.table[]
        for wdg in values(wdgs)
            wdg[].value[] = ""
        end
        wdgs["Rename"].value[] = default_names
    end

    widgets = Iterators.map(pairs(wdgs)) do (name, textbox)
        label = DOM.p(class="text-blue-800 text-xl font-semibold p-4 w-full text-left", name)
        class = name == foldl((_, k) -> k, keys(wdgs)) ? "" : "mb-4"
        return DOM.div(class=class, label, DOM.div(class="pl-4", textbox))
    end

    ui = DOM.div(widgets..., DOM.div(class="mt-12 mb-16 pl-4", process_button, clear_button))

    return jsrender(session, with_tabular(ui, lm.value))
end