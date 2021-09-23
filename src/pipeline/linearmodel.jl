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

    wdg1 = map(session, lm.table) do table
        colnames = collect(map(String, Tables.columnnames(table)))
        options = AutocompleteOptions("" => colnames, "with" => colnames, "output" => colnames)
        return Autocomplete(Observable(""), options)
    end

    wdg2 = map(session, lm.table) do table
        options = AutocompleteOptions(
            "+" => String[],
            "noise" => [string(noise) for noise in keys(noises)],
            "link" => [string(link) for link in keys(links)]
        )
        return Autocomplete(Observable(""), options)
    end

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
        predictor = Symbol[]
        for chunk in split(wdg1[].value[], ' ')
            isempty(chunk) && continue
            pre, post = split(chunk, ':')
            if pre == "with"
                push!(predictor, Symbol(post))
            else
                predictors += combinations(predictor)
                predictor = Symbol[]
                if pre == ""
                    push!(predictor, Symbol(post))
                elseif pre == "output"
                    responsevariable = Symbol(post)
                end
            end
        end
        predictors += combinations(predictor)
        if isnothing(responsevariable)
            msg = "output not provided"
            throw(ArgumentError(msg))
        end
        response = Term(responsevariable)
        formula = response ~ predictors

        calls = compute_calls(wdg2[].value[])
        for call in calls
            name = "$(responsevariable)_glm"
            distribution, link = Normal(), nothing
            for (k, v) in call.named
                name *= "_$k=$v"
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
        wdg1.value[] = ""
        wdg2.value[] = ""
    end

    widgets = map(enumerate((wdg1, wdg2))) do (i, textbox)
        name = i == 1 ? "Attributes" : "Methods"
        label = DOM.p(class="text-blue-800 text-xl font-semibold p-4 w-full text-left", name)
        class = i == 2 ? "" : "mb-4"
        return DOM.div(class=class, label, DOM.div(class="pl-4", textbox))
    end

    ui = DOM.div(widgets..., DOM.div(class="mt-12 mb-16 pl-4", process_button, clear_button))

    return jsrender(session, with_tabular(ui, lm.value))
end