const PIPELINE_TABS = (; Load, Filter, Process)
const VISUALIZATION_TABS = (; Spreadsheet, Chart, Pipelines)

struct UI
    pipelinetabs::SimpleList
    visualizationtabs::SimpleList
end

function Base.show(io::IO, ui::UI)
    p, v = map(getkey, ui.pipelinetabs), map(getkey, ui.visualizationtabs)
    print(io, "UI with pipelines $(p) and visualizations $(v)")
end

extract_options(sym::Union{Symbol, AbstractString}) = Symbol(sym), NamedTuple()
extract_options((sym, kwargs)::Pair) = Symbol(sym), kwargs

function concatenate(tabs, names, value)
    pipelines = Any[]
    for entry in names
        name, kwargs = extract_options(entry)
        tab = tabs[name](value; kwargs...)
        push!(pipelines, SimpleDict("key" => string(name), "value" => tab))
        value = output(tab)
    end
    return pipelines
end

"""
    UI(table; pipelinetabs=(:Load, :Filter, :Process), visualizationtabs=(:Spreadsheet, :Chart, :Pipelines))

Generate a `UI` with a given table as starting value. `pipelinetabs` denote the list of
pipeline tabs to include in the user interface. Each tab can take one of the following types:
`:Load, :Filter, :Process`.
Repetitions are allowed, for example setting
`tabs=(:Load, :Filter, :Process, :Filter)` would generate a `UI` that
allowes filtering both before and after processing the data.
`visualizationtabs` includes the list of visualization tabs to be included in the UI.
Possible values are `:Spreadsheet`, `Chart` and `:Pipelines`.
"""
function UI(table; pipelinetabs=keys(PIPELINE_TABS), visualizationtabs=keys(VISUALIZATION_TABS))
    obs = Observable(SimpleTable(table))
    pipelines = concatenate(PIPELINE_TABS, pipelinetabs, obs)
    visualizations = Any[]
    for entry in visualizationtabs
        name, kwargs = extract_options(entry)
        visualization = SimpleDict(
            "key" => string(name),
            "value" => VISUALIZATION_TABS[name](getvalue.(pipelines); kwargs...)
        )
        push!(visualizations, visualization)
    end
    return UI(pipelines, visualizations)
end

function jsrender(session::Session, ui::UI)
    evaljs(session, js"document.body.classList.add('bg-gray-100');")
    # manually load all dependencies
    for dep in AllDeps
        JSServe.push!(session, dep)
    end
    pipelinetabs, visualizationtabs = Tabs(ui.pipelinetabs), Tabs(ui.visualizationtabs)
    layout = DOM.div(
            class="grid grid-cols-5 h-full",
            DOM.div(class="col-span-2 pl-8", pipelinetabs),
            DOM.div(class="col-span-3 pl-12 pr-8", visualizationtabs)
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