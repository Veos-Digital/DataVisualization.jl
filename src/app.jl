const available_tabs = (
    Load = Load,
    Filter = Filter,
    Process = Process,
    Visualize = Visualize
)

struct UI{T}
    pipelines::Vector{Pair{Symbol, AbstractPipeline{T}}}
end

const default_tabs = (:Load, :Filter, :Process, :Visualize)

"""
    UI(table, tabs=(:Load, :Filter, :Process, :Visualize))

Generate a `UI` with a given table as starting value. `tabs` denote the list of
tabs to include in the user interface. Each tab can take one of the following types:
`:Load, :Filter, :Process, :Visualize`.
Repetitions are allowed, for example setting
`tabs=(:Load, :Filter, :Process, :Filter, :Visualize)` would generate a `UI` that
allowes filtering both before and after processing the data.
"""
function UI(table, tabs=default_tabs)
    ld = to_littledict(table)
    obs = Observable(ld)
    pipelines = Pair{Symbol, AbstractPipeline{typeof(ld)}}[]
    value = obs
    for tab in tabs
        pipeline = available_tabs[tab](value)
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
    evaljs(session, js"document.body.classList.add('bg-gray-100');")
    return jsrender(session, tabs)
end

"""
    app(table, tabs=(:Load, :Filter, :Process, :Visualize))

Generate a [`UI`](@ref) with a given `table` and list of `tabs`.
Launch the output as a local app.
"""
function app(table, tabs=default_tabs)
    return App() do
        return DOM.div(AllCSS..., UI(table, tabs))
    end
end

"""
    serve(table, tabs=(:Load, :Filter, :Process, :Visualize);
          url=Sockets.localhost, port=8081)

Generate a [`UI`](@ref) with a given `table` and list of `tabs`.
Serve the output at the given `url` and `port`.
Return a `JSServe.Server` object.
"""
function serve(table, tabs=default_tabs; url=Sockets.localhost, port=8081)
    return Server(app(table, tabs), string(url), port)
end