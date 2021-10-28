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
    value = Observable(table[])
    for component in components
        step = getproperty(available_processing_steps, component)(value)
        push!(steps, step)
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