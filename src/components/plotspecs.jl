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

const STYLES = (:color, :marker, :markersize, :linestyle, :col, :row, :layout, :side, :dodge)

struct PlotSpecs
    names::Vector{String}
    attributes::Observable{String}
    layers::Observable{String}
end

function PlotSpecs(df)
    names = [string(name) for name in Tables.columnnames(Tables.columns(df))]
    return PlotSpecs(names, Observable(""), Observable(""))
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

function jsrender(session::Session, specs::PlotSpecs)
    widgets = map([:attributes, :layers]) do name
        label = DOM.p(
            class="text-blue-800 text-xl font-semibold p-4 w-full text-left",
            uppercasefirst(string(name))
        )
        options = AutocompleteOptions()
        if name == :layers
            options["+"] = String[]
            for key in (keys(PLOT_TYPES)..., keys(ANALYSES)...)
                options[String(key)] = String[]
            end
        end
        options[""] = specs.names
        for style in STYLES
            options[String(style)] = specs.names
        end
        textbox = jsrender(session, Autocomplete(getproperty(specs, name), options))
        class = name == :layers ? "" : "mb-4"
        return DOM.div(class=class, label, DOM.div(class="pl-4", textbox))
    end
    return DOM.div(widgets...)
end
