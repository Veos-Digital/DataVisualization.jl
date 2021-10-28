const available_processing_steps = (
    Predict = LinearModel,
    Cluster = Cluster,
    Project = DimensionalityReduction,
)

struct Process{T} <: AbstractPipeline{T}
    table::Observable{T}
    steps::Observable{Vector{AbstractProcessingStep{T}}}
    value::Observable{T}
end

compute_pipeline(input, cache, steps, idx::Integer) = compute_pipeline(input, cache, steps, idx:idx)

function compute_pipeline(input, cache, steps, idxs::AbstractVector{<:Integer}=eachindex(steps)) where {T}
    cards = [step.card for step in steps]
    columns_input = columns_in.(cards)
    columns_output = columns_out.(cards)
    N = length(steps)
    g = SimpleDiGraph(N)
    for i in 1:N, j in 1:N
        if !isdisjoint(columns_input[j], columns_output[i])
            add_edge!(g, i, j)
        end
    end
    needs_updating = fill(false, N)
    needs_updating[idxs] .= true
    sorted = topological_sort_by_dfs(g)
    result = to_littledict(input)
    for node in sorted
        for neighbor in inneighbors(g, node)
            needs_updating[node] |= needs_updating[neighbor]
        end
        # avoid running on empty cards
        isempty(columns_input[node]) && continue
        # if updating is needed, recompute, otherwise use old values
        iter = needs_updating[node] ? steps[node](result) : [key => cache[key] for key in columns_output[node]]
        for (key, val) in iter
            haskey(result, key) && throw(ArgumentError("Overwriting table is not allowed"))
            result[key] = val
        end
    end
    return result
end

function Process(table::Observable{T}, keys=(:Predict, :Cluster, :Project)) where {T}
    value = Observable(table[])
    steps = AbstractProcessingStep{T}[getproperty(available_processing_steps, key)(value) for key in keys]
    for (idx, step) in enumerate(steps)
        for button in (step.card.process_button, step.card.clear_button)
            on(button.value) do _
                value[] = compute_pipeline(table[], value[], steps, idx)
            end
        end
    end
    return Process(table, Observable(steps), value)
end

function jsrender(session::Session, process::Process)
    ui = map(session, process.steps) do steps
        return DOM.div(
            steps;
            scrollablecomponent...
        )
    end
    return jsrender(session, with_tabular(ui, process.value, padwidgets=0))
end