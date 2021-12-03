struct Pipelines
    steps::Observable{Vector{Any}}
end

function Pipelines(pipelines::AbstractVector)
    steps = lift(vcat, (x.list.steps for x in pipelines if x isa Process)...)
    return Pipelines(steps)
end

function layout(g::SimpleDiGraph)
    xs, ys, _ = solve_positions(Zarate(), g)
    return Point.(ys, -xs)
end

function jsrender(session::Session, pipelines::Pipelines)
    # FIXME: set elsewhere
    font = AlgebraOfGraphics.firasans("Medium")
    textsize = 28
    arrow_size = 25
    edge_width = 3
    node_size = 45
    legend_node_size = 20
    colgap = 150
    # set general legend
    palette = Makie.current_default_theme().palette.color[]
    un = collect(keys(PROCESSING_STEPS))
    uc = palette[eachindex(un)]
    scale = AlgebraOfGraphics.CategoricalScale(un, uc, palette, "Processing")
    plot = map(session, pipelines.steps, result=Observable{Figure}()) do steps
        g = simpledigraph(steps)
        names = [step.card.name for step in steps]
        node_color = AlgebraOfGraphics.rescale(names, scale)
        f = Figure(; backgroundcolor=colorant"#F3F4F6")
        ax = Axis(f[1, 1]; backgroundcolor=colorant"#F3F4F6")
        isempty(steps) || graphplot!(ax, g;
            arrow_show=true, arrow_size, 
            edge_width, node_color,
            nlabels=string.(eachindex(steps)),
            nlabels_align=(:center, :center),
            nlabels_attr=(; font, textsize, color=:white),
            node_size, layout
        )
        hidedecorations!(ax)
        hidespines!(ax)
        # TODO: incorporate graphplots in AlgebraOfGraphics
        Legend(
            f[1, 2],
            [MarkerElement(; color, marker=:circle, markersize=legend_node_size) for color in scale.plot],
            string.(scale.data), scale.label
        )
        colgap!(f.layout, colgap)
        return f
    end
    return jsrender(session, scrollable_component(plot))
end
