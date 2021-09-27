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

const defaulttabs = (:Load, :Filter, :Predict, :Cluster, :Project, :Visualize)

"""
    UI(table, tabs=(:Load, :Filter, :Predict, :Cluster, :Project, :Visualize))

Generate a `UI` with a given table as starting value. `tabs` denote the list of
tabs to include in the user interface. Each tab can take one of the following types:
`:Load, :Filter, :Predict, :Cluster, :Project, :Visualize`.
Repetitions are allowed, for example setting
`tabs=(:Load, :Filter, :Predict, :Filter, :Visualize)` would generate a `UI` that
allowes filtering both before and after fitting a linear model to the data.
"""
function UI(table, tabs=defaulttabs)
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

"""
    app(table, tabs=(:Load, :Filter, :Predict, :Cluster, :Project, :Visualize))

Generate a [`UI`](@ref) with a given `table` and list of `tabs`.
Launch the output as a local app.
"""
function app(table, tabs=defaulttabs)
    return App() do
        return DOM.div(AllCSS..., UI(table, tabs))
    end
end

"""
    serve(table, tabs=(:Load, :Filter, :Predict, :Cluster, :Project, :Visualize);
           url=Sockets.localhost, port=8081)

Generate a [`UI`](@ref) with a given `table` and list of `tabs`.
Serve the output at the given `url` and `port`.
Return a `JSServe.Server` object.
"""
function serve(table, tabs=defaulttabs; url=Sockets.localhost, port=8081)
    return Server(app(table, tabs), url, port)
end