struct DimensionalityReduction{T} <: AbstractPipeline{T}
    table::Observable{T}
    value::Observable{T}
end

DimensionalityReduction(table::Observable{T}) where {T} =
    DimensionalityReduction{T}(table, Observable{T}(table[]))

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

function jsrender(session::Session, dimres::DimensionalityReduction)

    analysis_names = collect(map(string, keys(dimensionalityreductions)))

    wdg1 = map(session, dimres.table) do table
        colnames = collect(map(String, Tables.columnnames(table)))
        options = AutocompleteOptions("" => colnames)
        return Autocomplete(Observable(""), options)
    end

    wdg2 = map(session, dimres.table) do table
        options = AutocompleteOptions("+" => String[])
        for name in analysis_names
            if name in ("mds", "ica")
                options[name * " dims"] = [string(i) for i in 1:100]
            else
                options[name] = String[]
            end
        end
        return Autocomplete(Observable(""), options)
    end

    tryon(session, dimres.table) do table
        dimres.value[] = table
    end

    process_button = Button("Process", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))

    tryon(session, process_button.value) do _
        local table = dimres.table[]
        result = to_littledict(table)
        call = only(compute_calls(wdg1[].value[]))
        cols = Tables.getcolumn.(Ref(table), Symbol.(call.positional))
        X = reduce(vcat, transpose.(cols))
        kws = map(((k, v),) -> Symbol(k) => Tables.getcolumn(table, Symbol(v)), call.named)
        calls = compute_calls(wdg2[].value[])

        for call in calls
            name = only(call.fs)

            an = dimensionalityreductions[Symbol(only(call.fs))]
            positional, named = [], collect(Pair, kws)
            for (k, v) in call.named
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
        end

        dimres.value[] = result
    end

    tryon(session, clear_button.value) do _
        dimres.value[] = dimres.table[]
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

    return jsrender(session, with_tabular(ui, dimres.value))
end