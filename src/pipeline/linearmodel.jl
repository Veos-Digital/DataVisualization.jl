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

    inputs_wdg = map(session, lm.table) do table
        colnames = collect(map(String, Tables.columnnames(table)))
        options = AutocompleteOptions("" => colnames, "* " => colnames, "+ " => colnames)
        return Autocomplete(Observable(""), options)
    end

    output_wdg = map(session, lm.table) do table
        colnames = collect(map(String, Tables.columnnames(table)))
        options = AutocompleteOptions("" => colnames)
        return Autocomplete(Observable(""), options)
    end

    method_wdg = map(session, lm.table) do table
        options = AutocompleteOptions(
            "noise" => [string(noise) for noise in keys(noises)],
            "link" => [string(link) for link in keys(links)]
        )
        return Autocomplete(Observable(""), options)
    end

    wdgs = LittleDict(
        "Inputs" => inputs_wdg,
        "Output" => output_wdg,
        "Method" => method_wdg,
    )

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
        for call in compute_calls(wdgs["Inputs"][].value[])
            predictors += combinations(map(Symbol, call.positional))
        end
        output_call = only(compute_calls(wdgs["Output"][].value[]))
        responsevariable = Symbol(only(output_call.positional))

        response = Term(responsevariable)
        formula = response ~ predictors

        calls = compute_calls(wdgs["Method"][].value[])
        for call in calls
            name = "prediction"
            distribution, link = Normal(), nothing
            for (k, v) in call.named
                k == "noise" && (distribution = noises[Symbol(v)]())
                k == "link" && (link = links[Symbol(v)]())
            end
            model = glm(formula, table, distribution, something(link, canonicallink(distribution)))
            anres = predict(model, table)
            result[Symbol(name)] = disallowmissing(anres) # FIXME: support missing data in AoG
        end

        lm.value[] = result
    end

    tryon(session, clear_button.value) do _
        lm.value[] = lm.table[]
        for wdg in values(wdgs)
            wdg.value[] = ""
        end
    end

    widgets = Iterators.map(pairs(wdgs)) do (name, textbox)
        label = DOM.p(class="text-blue-800 text-xl font-semibold p-4 w-full text-left", name)
        class = name == "Method" ? "" : "mb-4"
        return DOM.div(class=class, label, DOM.div(class="pl-4", textbox))
    end

    ui = DOM.div(widgets..., DOM.div(class="mt-12 mb-16 pl-4", process_button, clear_button))

    return jsrender(session, with_tabular(ui, lm.value))
end