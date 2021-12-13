const PROCESSING_STEPS = (
    Predict = LinearModel,
    Cluster = Cluster,
    Project = DimensionalityReduction,
    Wildcard = Wildcard,
)

struct Process <: AbstractPipeline
    table::Observable{SimpleTable}
    list::EditableList
    value::Observable{SimpleTable}
    options::Vector{Symbol}
end

get_vertices(p::Process) = Vertex.(p.list.steps[])
get_vertex_names(p::Process) = p.options

function Process(table::Observable{SimpleTable}, options::Vector{Symbol})
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
    _list_options = Iterators.map(options) do option
        local key = string(option)
        local value = thunkify(PROCESSING_STEPS[option])
        return SimpleDict("key" => key, "value" => value)
    end
    list_options = Observable(collect(Any, _list_options))
    process = Process(table, EditableList(list_options, steps), value, options)
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

function Process(table::Observable{SimpleTable}; options=[:Predict, :Cluster, :Project])
    return Process(table, vecmap(Symbol, options))
end

function jsrender(session::Session, process::Process)
    ui = scrollable_component(
        process.list;
        onmousedown=js"$(UtilitiesJS).updateSelection(this, event, $(process.list.selected));"
    )
    return jsrender(session, ui)
end

default_needs_update(step) = shouldrun(step.card.state[])
always_true(step) = true

Vertex(step::AbstractProcessingStep) = Vertex(step.card.name, columns_in(step), columns_out(step))

nodes_to_compute(steps) = nodes_to_compute(default_needs_update, steps)

function nodes_to_compute(f, steps)
    g = simpledigraph(Vertex.(steps))
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
    result = SimpleTable(input)
    # Add outputs of nodes that do not need to be recomputed
    for node in setdiff(1:length(steps), nodes)
        names = columns_out(steps[node])
        columns = AbstractVector[Tables.getcolumn(cache, name) for name in names]
        mergedisjointcols!(result, SimpleTable(names, columns))
    end
    # Recompute nodes, which were returned in topological order
    for node in nodes
        step = steps[node]
        if !isempty(columns_in(step))
            try
                mergedisjointcols!(result, step(result))
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
