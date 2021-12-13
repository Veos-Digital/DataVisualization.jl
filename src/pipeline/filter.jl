struct Filter <: AbstractPipeline
    table::Observable{SimpleTable}
    filters::Observable{Filters}
    value::Observable{SimpleTable}
end

function get_vertices(f::Filter)
    isoriginal = all(f.filters[].options) do option
        return option.value.isoriginal[]
    end
    if isoriginal
        return Vertex[]
    else
        names = collect(Tables.columnnames(f.table[]))
        return [Vertex(:Filter, names, names)]
    end
end

get_vertex_names(::Filter) = [:Filter]

function Filter(table::Observable{SimpleTable})
    filters = Observable(Filters(table[]))
    value = Observable(selected_data(filters[], table[]))
    return Filter(table, filters, value)
end

selected_data(f::Filter) = selected_data(f.filters[], f.table[])

function jsrender(session::Session, f::Filter)

    tryon(session, f.table) do table
        f.filters[] = Filters(table)
        f.value[] = selected_data(f)
    end

    filter_button = Button("Filter", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))
    ui = scrollable_component(
        f.filters,
        DOM.div(class="mt-12 pl-4", filter_button, clear_button)
    )

    tryon(session, filter_button.value) do _
        f.value[] = selected_data(f)
    end
    tryon(session, clear_button.value) do _
        f.filters[] = Filters(f.table[])
        f.value[] = selected_data(f)
    end

    return jsrender(session, ui)
end