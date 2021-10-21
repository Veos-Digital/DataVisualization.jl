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
    return map(session, specs.names) do names
        return name == :layers ? [layers_options(); style_options(names)] : style_options(names)
    end
end

function jsrender(session::Session, specs::PlotSpecs)
    widgets = map([:attributes, :layers]) do name
        label = DOM.p(
            class="text-blue-800 text-xl font-semibold p-4 w-full text-left",
            uppercasefirst(string(name))
        )
        options = specs_options(session, specs; name)
        textbox = jsrender(session, Autocomplete(getproperty(specs, name), options))
        class = name == :layers ? "" : "mb-4"
        return DOM.div(class=class, label, DOM.div(class="pl-4", textbox))
    end
    return DOM.div(widgets...)
end
