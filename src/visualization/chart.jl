const PLOT_TYPES = (
    scatter=Scatter,
    lines=Lines,
    barplot=BarPlot,
    boxplot=BoxPlot,
    violin=Violin,
    heatmap=Heatmap,
    contour=Contour,
    contourf=Contourf,
    wireframe=Wireframe,
    surface=Surface,
)

const ANALYSES = (
    histogram=AlgebraOfGraphics.histogram,
    density=AlgebraOfGraphics.density,
    frequency=AlgebraOfGraphics.frequency,
    expectation=AlgebraOfGraphics.expectation,
    linear=AlgebraOfGraphics.linear,
    smooth=AlgebraOfGraphics.smooth,
)

const STYLES = (:color, :marker, :markersize, :linestyle, :col, :row, :layout, :side, :dodge, :stack)

struct PlotSpecs
    names::Observable{Vector{String}}
    attributes::Observable{String}
    layers::Observable{String}
end

function PlotSpecs(df::Observable)
    return PlotSpecs(lift(colnames, df), Observable(""), Observable(""))
end

is_set(p::PlotSpecs) = !isempty(p.attributes[]) || !isempty(p.layers[])

function to_visual(sym)
    plt = get(PLOT_TYPES, sym, nothing)
    isnothing(plt) || return visual(plt)
    an = get(ANALYSES, sym, nothing)
    isnothing(an) || return an()
    msg = "plot or analysis not available"
    throw(ArgumentError(msg))
end

to_symbolpair((a, b)) = Symbol(a) => Symbol(b)

function to_algebraic(str::AbstractString)
    calls = compute_calls(str)
    layers = map(calls) do call
        visual = mapreduce(to_visual∘Symbol, *, call.fs, init=mapping())
        args = map(Symbol, call.positional)
        attrs = map(to_symbolpair, call.named)
        return visual * mapping(args...; attrs...)
    end
    return Layers(layers)
end

to_algebraic(v::Union{Tuple, AbstractArray}) = mapreduce(to_algebraic, *, v, init=mapping())

to_algebraic(specs::PlotSpecs) = to_algebraic(map(getindex, (specs.attributes, specs.layers)))

function layers_options()
    options = vecmap(((keys(PLOT_TYPES)..., keys(ANALYSES)...))) do key
        string(key) => String[]
    end
    pushfirst!(options, "+" => String[])
    return options
end

function style_options(names)
    options = vecmap(style -> string(style) => names, STYLES)
    pushfirst!(options, "" => names)
    return options
end

function specs_options(session::Session, specs::PlotSpecs; name)
    return map(session, specs.names; result=Observable{AutocompleteOptions}()) do names
        options = name == :layers ? [layers_options(); style_options(names)] : style_options(names)
        return to_autocomplete_options(options)
    end
end

struct Chart <: AbstractVisualization
    table::Observable{SimpleTable}
    plotspecs::PlotSpecs
end

Chart(table::Observable{SimpleTable}) = Chart(table, PlotSpecs(table))
Chart(pipelines::AbstractVector) = Chart(output(last(pipelines)))

to_algebraic(chart::Chart) = data(chart.table[]) * to_algebraic(chart.plotspecs)

defaultplot() = Figure(; backgroundcolor=colorant"#F3F4F6")

function on_pixelratio(f, session; once=false)
    pixelratio = Observable(1.0)
    flag = false
    on(pixelratio) do pr
        once && flag && return
        f(pr)
        flag = true
    end
    evaljs(session, js"$(UtilitiesJS).trackPixelRatio($(pixelratio))")
    return
end

function jsrender(session::Session, chart::Chart)

    specs_widgets = map([:attributes, :layers]) do name
        label = DOM.p(
            class="text-blue-800 text-xl font-semibold p-4 w-full text-left",
            uppercasefirst(string(name))
        )
        options = specs_options(session, chart.plotspecs; name)
        textbox = jsrender(session, Autocomplete(getproperty(chart.plotspecs, name), options))
        return DOM.div(label, DOM.div(class="pl-4", textbox))
    end

    plot = Observable{Figure}(defaultplot())

    width, height = Observable(350), Observable(350)
    on_pixelratio(session) do pr
        width[] = round(Int, 350pr)
        height[] = round(Int, 350pr)
    end

    reset_plot!(_) = plot[] = defaultplot()
    function update_plot!(_)
        is_set(chart.plotspecs) || return
        plt = to_algebraic(chart)
        axis = (width=width[], height=height[])
        fg = draw(plt; axis)
        plot[] = fg.figure
    end

    plot_button = Button("Plot", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))
    ui = scrollable_component(
        DOM.div(class="grid grid-cols-2 gap-8", specs_widgets),
        DOM.div(class="mt-8 pl-4", plot_button, clear_button),
        DOM.div(class="mt-12 pl-4", plot)
    )

    tryon(update_plot!, session, plot_button.value)
    tryon(update_plot!, session, chart.plotspecs.names) # gets updated when table changes
    tryon(reset_plot!, session, clear_button.value)

    return jsrender(session, ui)
end
