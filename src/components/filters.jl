struct Filters
    options::Vector{Option}
    Filters(options::AbstractVector{<:Option}) = new(convert(Vector{Option}, options))
end

function Filters(df)
    cols = Tables.columns(df)
    selectors = Option[]
    for name in Tables.columnnames(cols)
        v = Tables.getcolumn(cols, name)
        selector = if iscontinuous(v)
            range = histrange(v, 50)
            Option(string(name), RangeSelector(range), Observable(false))
        else
            unique = uniquesorted(v) # TODO: optimize for strings
            options = [Option(string(val), val, Observable(true)) for val in unique]
            Option(string(name), Checkboxes(options), Observable(false))
        end
        push!(selectors, selector)
    end
    return Filters(selectors)
end

function filter_column!(previous::AbstractVector{Bool}, v::AbstractVector, cb::Checkboxes)
    accepted_options = Set(option.value for option in cb.options if option.selected[])
    previous .&= in(accepted_options).(v)
    return previous
end

function filter_column!(previous::AbstractVector{Bool}, v::AbstractVector, rg::RangeSelector)
    min, max = map(getindex, rg.selected)
    @. previous &= min ≤ v ≤ max
    return previous
end

filter_column!(::Nothing, v::AbstractVector, rg) = filter_column!(fill(true, length(v)), v,  rg)

function selected_data(f::Filters, table)
    data, options = Tables.columns(table), f.options

    selected = foldl(options, init=nothing) do acc, option
        colname = Symbol(option.key)
        wdg = option.value
        column = Tables.getcolumn(data, colname)
        return filter_column!(acc, column, wdg)
    end
    return mapcols!(t -> t[selected], SimpleTable(data))
end

jsrender(session::Session, filters::Filters) = jsrender(session, Togglers(filters.options))