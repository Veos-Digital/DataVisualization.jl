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

    wdgs = LittleDict()

    wdgs["Inputs"] = map(session, dimres.table) do table
        colnames = collect(map(String, Tables.columnnames(table)))
        options = AutocompleteOptions("" => colnames)
        return Autocomplete(Observable(""), options)
    end

    wdgs["Method"] = map(session, dimres.table) do table
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

    default_names = ":projection"

    wdgs["Rename"] = map(session, dimres.table) do table
        options = AutocompleteOptions("" => ["projection"])
        return Autocomplete(Observable(default_names), options)
    end

    tryon(session, dimres.table) do table
        dimres.value[] = table
    end

    process_button = Button("Process", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))

    tryon(session, process_button.value) do _
        local table = dimres.table[]
        result = to_littledict(table)
        inputs_call = only(compute_calls(wdgs["Inputs"][].value[]))
        cols = Tables.getcolumn.(Ref(table), Symbol.(inputs_call.positional))
        X = reduce(vcat, transpose.(cols))
        kws = map(((k, v),) -> Symbol(k) => Tables.getcolumn(table, Symbol(v)), inputs_call.named)
        method_call = only(compute_calls(wdgs["Method"][].value[]))
        rename_call = only(compute_calls(wdgs["Rename"][].value[]))

        name = only(rename_call.positional)

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

        dimres.value[] = result
    end

    tryon(session, clear_button.value) do _
        dimres.value[] = dimres.table[]
        for wdg in values(wdgs)
            wdg[].value[] = ""
        end
        wdgs["Rename"][].value[] = default_names
    end

    widgets = Iterators.map(pairs(wdgs)) do (name, textbox)
        label = DOM.p(class="text-blue-800 text-xl font-semibold p-4 w-full text-left", name)
        class = name == foldl((_, k) -> k, keys(wdgs)) ? "" : "mb-4"
        return DOM.div(class=class, label, DOM.div(class="pl-4", textbox))
    end

    ui = DOM.div(widgets..., DOM.div(class="mt-12 mb-16 pl-4", process_button, clear_button))

    return jsrender(session, with_tabular(ui, dimres.value))
end