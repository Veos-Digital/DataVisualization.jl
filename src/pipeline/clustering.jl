struct Cluster{T} <: AbstractPipeline{T}
    table::Observable{T}
    value::Observable{T}
end

Cluster(table::Observable{T}) where {T} = Cluster{T}(table, Observable{T}(table[]))

# TODO: add indirection layer with distance support, as in dimensionality reduction?
const clusterings = (
    kmeans=kmeans,
    mcl=mcl,
    affinityprop=affinityprop,
)

function jsrender(session::Session, cluster::Cluster)

    analysis_names = collect(map(string, keys(clusterings)))

    wdgs = LittleDict()

    wdgs["Inputs"] = map(session, cluster.table) do table
        colnames = collect(map(String, Tables.columnnames(table)))
        options = AutocompleteOptions("" => colnames, "weights" => colnames)
        return Autocomplete(Observable(""), options)
    end

    wdgs["Method"] = map(session, cluster.table) do table
        options = AutocompleteOptions()
        for name in analysis_names
            if name == "kmeans"
                options[name * " classes"] = [string(i) for i in 1:100]
            else
                options[name] = String[]
            end
        end
        return Autocomplete(Observable(""), options)
    end

    default_names = ":cluster"

    wdgs["Rename"] = map(session, cluster.table) do table
        options = AutocompleteOptions("" => ["cluster"])
        return Autocomplete(Observable(default_names), options)
    end

    tryon(session, cluster.table) do table
        cluster.value[] = table
    end

    process_button = Button("Process", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))

    dist = Euclidean() # TODO: make configurable

    tryon(session, process_button.value) do _
        local table = cluster.table[]
        result = to_littledict(table)
        input_call = only(compute_calls(wdgs["Inputs"][].value[]))
        cols = Tables.getcolumn.(Ref(table), Symbol.(input_call.positional))
        X = reduce(vcat, transpose.(cols))
        kws = map(((k, v),) -> Symbol(k) => Tables.getcolumn(table, Symbol(v)), input_call.named)
        D = pairwise(dist, X, dims=2)

        method_call = only(compute_calls(wdgs["Method"][].value[]))
        rename_call = only(compute_calls(wdgs["Rename"][].value[]))
        name = only(rename_call.positional)

        an = clusterings[Symbol(only(method_call.fs))]
        input = an === kmeans ? X : D
        positional, named = [], collect(Pair, kws)
        for (k, v) in method_call.named
            if an === kmeans && k == "classes"
                push!(positional, parse(Int, v))
            else
                push!(named, Symbol(k) => v)
            end
        end
        anres = an(input, positional...; named...)
        result[Symbol(name)] = map(nonnumeric, Clustering.assignments(anres))

        cluster.value[] = result
    end

    tryon(session, clear_button.value) do _
        cluster.value[] = cluster.table[]
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

    return jsrender(session, with_tabular(ui, cluster.value))
end