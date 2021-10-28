struct Filter{T} <: AbstractPipeline{T}
    table::Observable{T}
    filters::Observable{Filters}
    value::Observable{T}
end

function Filter(table::Observable{T}) where {T}
    filters = Observable(Filters(table[]))
    value = Observable{T}(selected_data(filters[], table[]))
    return Filter{T}(table, filters, value)
end

selected_data(f::Filter) = selected_data(f.filters[], f.table[])

function jsrender(session::Session, f::Filter)

    tryon(session, f.table) do table
        f.filters[] = Filters(table)
        f.value[] = selected_data(f)
    end

    filter_button = Button("Filter", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))
    ui = DOM.div(
        f.filters,
        DOM.div(class="mt-12 pl-4", filter_button, clear_button);
        scrollablecomponent...
    )

    tryon(session, filter_button.value) do _
        f.value[] = selected_data(f)
    end
    tryon(session, clear_button.value) do _
        f.filters[] = Filters(f.table[])
        f.value[] = selected_data(f)
    end

    return jsrender(session, with_tabular(ui, f.value; padwidgets=0))
end