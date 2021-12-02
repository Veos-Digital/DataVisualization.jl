const PipelineTabs = (; Load, Filter, Process)
const VisualizationTabs = (; SpreadSheet, Chart)

struct UI{P, V}
    pipelinetabs::P
    visualizationtabs::V
end

function Base.show(io::IO, ui::UI)
    p, v = keys(ui.pipelinetabs), keys(ui.visualizationtabs)
    print(io, "UI with pipelines $(p) and visualizations $(v)")
end

concatenate(names, value) = NamedTuple{names}(_concatenate(names, value))

function _concatenate((p, ps...)::Tuple, value)
    pipeline = PipelineTabs[p](value)
    return (pipeline, _concatenate(ps, output(pipeline))...)
end

_concatenate(::Tuple{}, value) = ()

"""
    UI(table, tabs=(:Load, :Filter, :Process))

Generate a `UI` with a given table as starting value. `tabs` denote the list of
tabs to include in the user interface. Each tab can take one of the following types:
`:Load, :Filter, :Process`.
Repetitions are allowed, for example setting
`tabs=(:Load, :Filter, :Process, :Filter)` would generate a `UI` that
allowes filtering both before and after processing the data.
"""
function UI(table; pipelinetabs=keys(PipelineTabs), visualizationtabs=keys(VisualizationTabs))
    pipelines = concatenate(pipelinetabs, Observable(to_littledict(table)))
    value = output(last(pipelines))
    visualizations = mapkeys(key -> VisualizationTabs[key](value), visualizationtabs)
    return UI(pipelines, visualizations)
end

function jsrender(session::Session, ui::UI)
    pipelinetabs, visualizationtabs = Tabs(ui.pipelinetabs), Tabs(ui.visualizationtabs)
    return jsrender(session, pipelinetabs)
end

"""
    app(table, tabs=(:Load, :Filter, :Process))

Generate a [`UI`](@ref) with a given `table` and list of `tabs`.
Launch the output as a local app.
"""
function app(table; pipelinetabs=keys(PipelineTabs), visualizationtabs=keys(VisualizationTabs))
    return App() do
        return DOM.div(AllCSS..., UI(table; pipelinetabs, visualizationtabs))
    end
end

"""
    serve(table, tabs=(:Load, :Filter, :Process, :Visualize);
          url=Sockets.localhost, port=8081)

Generate a [`UI`](@ref) with a given `table` and list of `tabs`.
Serve the output at the given `url` and `port`.
Return a `JSServe.Server` object.
"""
function serve(table; url=Sockets.localhost, port=8081,
               pipelinetabs=keys(PipelineTabs), visualizationtabs=keys(VisualizationTabs))
    return Server(app(table; pipelinetabs, visualizationtabs), string(url), port)
end