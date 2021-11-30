const available_processing_steps = (
    Predict = LinearModel,
    Cluster = Cluster,
    Project = DimensionalityReduction,
)

struct Process{T} <: AbstractPipeline{T}
    table::Observable{T}
    list::EditableList
    value::Observable{T}
end

function Process(table::Observable{T}) where {T}
    value = Observable(table[])
    steps = Observable(Any[])
    function thunkify(type)
        return function ()
            step = type(value)
            card = step.card
            on(card.run) do _
                if shouldrun(card.state[])
                    value[] = compute_pipeline(table[], value[], steps[])
                end
            end
            on(card.destroy) do val
                clear!(card)
                _steps = steps[]
                if val
                    id = objectid(step)
                    idx = findfirst(==(id)∘objectid, _steps)
                    isnothing(idx) || (steps[] = remove_item(_steps, idx))
                end
            end
            return step
        end
    end
    options = Observable(to_stringdict(map(thunkify, available_processing_steps)))
    process = Process(table, EditableList(options, steps), value)
    on(table) do data
        _steps = steps[]
        # TODO: contemplate error case
        value[] = compute_pipeline(always_true, data, value[], _steps)
        for step in _steps
            step.card.state[] = done
        end
    end
    return process
end

function jsrender(session::Session, process::Process)
    ui = scrollable_component(
        process.list;
        onmousedown=js"$(UtilitiesJS).updateSelection(this, event, $(process.list.selected));"
    )
    return jsrender(session, with_tabular(ui, process.value, padwidgets=0))
end

default_needs_update(step) = shouldrun(step.card.state[])
always_true(step) = true

nodes_to_compute(steps) = nodes_to_compute(default_needs_update, steps)

function nodes_to_compute(f, steps)
    columns_input = columns_in.(steps)
    columns_output = columns_out.(steps)
    N = length(steps)
    g = SimpleDiGraph(N)
    for i in 1:N, j in 1:N
        if !isdisjoint(columns_input[j], columns_output[i])
            add_edge!(g, i, j)
        end
    end
    sorted = topological_sort_by_dfs(g)
    needs_updating = map(f, steps)
    nodes = Int[]
    for node in sorted
        for neighbor in inneighbors(g, node)
            needs_updating[node] |= needs_updating[neighbor]
        end
        needs_updating[node] && push!(nodes, node)
    end
    return nodes
end

compute_pipeline(input, cache, steps) = compute_pipeline(default_needs_update, input, cache, steps)

function compute_pipeline(f, input, cache, steps)
    nodes =  nodes_to_compute(f, steps)
    result = to_littledict(input)
    for node in setdiff(1:length(steps), nodes)
        for key in columns_out(steps[node])
            haskey(result, key) && throw(ArgumentError("Overwriting table is not allowed"))
            result[key] = cache[key]
        end
    end
    for node in nodes
        step = steps[node]
        if !isempty(columns_in(step))
            try
                mergewith!(result, step(result)) do _, _
                    throw(ArgumentError("Overwriting table is not allowed"))
                end
                step.card.state[] = done
            catch e
                step.card.error[] = sprint(showerror, e)
                step.card.state[] = errored
            end
        else
            step.card.state[] = inactive
        end
    end
    return result
end
