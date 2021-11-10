const available_processing_steps = (
    Predict = LinearModel,
    Cluster = Cluster,
    Project = DimensionalityReduction,
)

struct Process{T} <: AbstractPipeline{T}
    table::Observable{T}
    list::DraggableList{AbstractProcessingStep{T}}
    value::Observable{T}
end

function Process(table::Observable{T}, steps::Observable{Vector{AbstractProcessingStep{T}}}, value::Observable{T}) where T
    return Process(table, DraggableList(steps), value)
end

default_needs_update(step) = step.card.state[] != :done
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
            mergewith!(result, step(result)) do _, _
                throw(ArgumentError("Overwriting table is not allowed"))
            end
        end
        # TODO: add `:errored` state if the above fails
        step.card.state[] = :done
    end
    return result
end

function add_callbacks!(step::AbstractProcessingStep, process::Process)
    table, value, steps = process.table, process.value, process.list.steps
    card = step.card
    # May be safer to have separate `Observable`s controlling this
    on(card.state) do state
        if state != :done
            value[] = compute_pipeline(table[], value[], steps[])
            # TODO: contemplate error case
            card.state[] = :done
        end
    end
    on(card.destroy) do val
        _steps = steps[]
        if val
            id = objectid(step)
            idx = findfirst(==(id)∘objectid, _steps)
            isnothing(idx) || (steps[] = remove_item(_steps, idx))
            # TODO: clear card before destroying!
        end
    end
end

function Process(table::Observable{T}, keys=(:Predict, :Cluster, :Project)) where {T}
    value = Observable(table[])
    steps = Observable(AbstractProcessingStep{T}[getproperty(available_processing_steps, key)(value) for key in keys])
    process = Process(table, steps, value)
    for step in steps[]
        add_callbacks!(step, process)
    end
    on(table) do data
        _steps = steps[]
        # TODO: contemplate error case
        value[] = compute_pipeline(always_true, data, value[], _steps)
        for step in _steps
            step.card.state[] = :done
        end
    end
    return process
end

function jsrender(session::Session, process::Process)
    ui = DOM.div(
        process.list;
        scrollablecomponent...
    )
    return jsrender(session, with_tabular(ui, process.value, padwidgets=0))
end