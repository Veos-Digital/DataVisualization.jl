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

function Process(table::Observable{T}, components=(:Predict, :Cluster, :Project)) where {T}
    steps = AbstractProcessingStep{T}[]
    cards = [step.card for step in steps]
    value = Observable(table[])
    for component in components
        step = getproperty(available_processing_steps, component)(value)
        push!(steps, step)
    end

    for (idx, card) in enumerate(cards)
        for button in (card.process_button, card.clear_button)
            map!(value, button.value) do _
                N = length(steps)
                g = SimpleDiGraph(N)
                columns_input = columns_in.(card)
                columns_output = columns_out.(card)
                for i in 1:N, j in 1:N
                    if !isdisjoint(columns_input[j], columns_output[i])
                        add_edge!(g, i, j)
                    end
                end
                return compute_on_graph(g, table[], steps, idx)
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