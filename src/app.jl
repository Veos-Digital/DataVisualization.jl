const availablepipelines = (
    Load = Load,
    Filter = Filter,
    Predict = LinearModel,
    Cluster = Cluster,
    Project = DimensionalityReduction,
    Visualize = Visualize
)

struct UI{T}
    pipelines::Vector{Pair{Symbol, AbstractPipeline{T}}}
end

function UI(table, tabs = (:Load, :Filter, :Predict, :Cluster, :Project, :Visualize))
    ld = to_littledict(table)
    obs = Observable(ld)
    pipelines = Pair{Symbol, AbstractPipeline{typeof(ld)}}[]
    value = obs
    for tab in tabs
        pipeline = availablepipelines[tab](value)
        push!(pipelines, tab => pipeline)
        value = output(pipeline)
    end
    return UI(pipelines)
end

function jsrender(session::Session, ui::UI)
    pipelines = map(ui.pipelines) do (name, pipeline)
        return Option(String(name), DOM.div(pipeline), Observable(true))
    end
    tabs = Tabs(pipelines)
    return jsrender(session, DOM.div(class="bg-gray-100", tabs))
end
