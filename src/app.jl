const PIPELINE_TABS = (; Load, Filter, Process)
const VISUALIZATION_TABS = (; Spreadsheet, Chart, Pipelines)

struct UI
    pipelinetabs::Dict{String, Vector}
    visualizationtabs::Dict{String, Vector}
end

function Base.show(io::IO, ui::UI)
    p, v = ui.pipelinetabs["keys"], ui.visualizationtabs["keys"]
    print(io, "UI with pipelines $(p) and visualizations $(v)")
end

extract_options(sym::Symbol) = sym, NamedTuple()
extract_options(p::Pair) = first(p), last(p)

function concatenate(tabs, names, value)
    keys, values = String[], Any[]
    for entry in names
        name, kwargs = extract_options(entry)
        push!(keys, string(name))
        tab = tabs[name](value; kwargs...)
        push!(values, tab)
        value = output(tab)
    end
    return Dict("keys" => keys, "values" => values)
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
    obs = Observable(to_littledict(table))
    pipelines = concatenate(PIPELINE_TABS, pipelinetabs, obs)
    visualizations = Dict{String, Vector}("keys" => String[], "values" => Any[])
    for entry in visualizationtabs
        name, kwargs = extract_options(entry)
        push!(visualizations["keys"], string(name))
        push!(visualizations["values"], VISUALIZATION_TABS[name](pipelines["values"]; kwargs...))
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