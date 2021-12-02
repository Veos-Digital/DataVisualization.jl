const PIPELINE_TABS = (; Load, Filter, Process)
const VISUALIZATION_TABS = (; Spreadsheet, Chart)

struct UI
    pipelinetabs::Dict{String, Vector}
    visualizationtabs::Dict{String, Vector}
end

function Base.show(io::IO, ui::UI)
    p, v = ui.pipelinetabs["keys"], ui.visualizationtabs["keys"]
    print(io, "UI with pipelines $(p) and visualizations $(v)")
end

function concatenate(tabs, names, value)
    keys, values = String[], Any[]
    for name in names
        push!(keys, string(name))
        tab = tabs[name](value)
        push!(values, tab)
        value = something(output(tab), value)
    end
    return Dict("keys" => keys, "values" => values), value
end

"""
    UI(table; pipelinetabs=(:Load, :Filter, :Process), visualizationtabs=(:Spreadsheet, :Chart))

Generate a `UI` with a given table as starting value. `pipelinetabs` denote the list of
pipeline tabs to include in the user interface. Each tab can take one of the following types:
`:Load, :Filter, :Process`.
Repetitions are allowed, for example setting
`tabs=(:Load, :Filter, :Process, :Filter)` would generate a `UI` that
allowes filtering both before and after processing the data.
`visualizationtabs` includes the list of visualization tabs to be included in the UI.
Possible values are `:Spreadsheet` and `Chart`.
"""
function UI(table; pipelinetabs=keys(PIPELINE_TABS), visualizationtabs=keys(VISUALIZATION_TABS))
    obs = Observable(to_littledict(table))
    pipelines, value = concatenate(PIPELINE_TABS, pipelinetabs, obs)
    visualizations, _ = concatenate(VISUALIZATION_TABS, visualizationtabs, value)
    return UI(pipelines, visualizations)
end

function jsrender(session::Session, ui::UI)
    evaljs(session, js"document.body.classList.add('bg-gray-100');")
    pipelinetabs, visualizationtabs = Tabs(ui.pipelinetabs), Tabs(ui.visualizationtabs)
    layout = DOM.div(
            class="grid grid-cols-3 h-full",
            DOM.div(class="col-span-1 pl-8", pipelinetabs),
            DOM.div(class="col-span-2 pl-12 pr-16", visualizationtabs)
        )
    return jsrender(session, layout)
end

"""
    app(table; pipelinetabs=(:Load, :Filter, :Process), visualizationtabs=(:Spreadsheet, :Chart))

Generate a [`UI`](@ref) with a given `table` and lists of pipeline and visualization tabs.
Launch the output as a local app.
"""
function app(table; pipelinetabs=keys(PIPELINE_TABS), visualizationtabs=keys(VISUALIZATION_TABS))
    return App() do
        return DOM.div(AllCSS..., UI(table; pipelinetabs, visualizationtabs))
    end
end

"""
    serve(table;
          pipelinetabs=(:Load, :Filter, :Process),
          visualizationtabs=(:Spreadsheet, :Chart),
          url=Sockets.localhost, port=8081)

Generate a [`UI`](@ref) with a given `table` and lists of pipeline and visualization tabs.
Serve the output at the given `url` and `port`.
Return a `JSServe.Server` object.
"""
function serve(table; url=Sockets.localhost, port=8081, verbose=true,
               pipelinetabs=keys(PIPELINE_TABS), visualizationtabs=keys(VISUALIZATION_TABS))
    return Server(app(table; pipelinetabs, visualizationtabs), string(url), port; verbose)
end