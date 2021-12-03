struct Pipelines
    steps::Observable{Vector{Any}}
end

function Pipelines(pipelines::AbstractVector)
    steps = lift(vcat, (x.list.steps for x in pipelines if x isa Process)...)
    return Pipelines(steps)
end

function layout(g::SimpleDiGraph)
    xs, ys, _ = solve_positions(Zarate(), g)
    return Point.(-ys, -xs)
end

function jsrender(session::Session, pipelines::Pipelines)
    plot = Observable{Figure}(defaultplot())
    font = AlgebraOfGraphics.firasans("Light")
    arrow_size = 25
    edge_size = 3
    node_size = 45
    on(session, pipelines.steps) do steps
        g = simpledigraph(steps)
        names = [string(step.card.name) for step in steps]
        palette = Makie.current_default_theme().palette.color[]
        # TODO: move scale outside to keep consistency
        scale = AlgebraOfGraphics.CategoricalScale(unique(names), palette, palette, nothing)
        colors = AlgebraOfGraphics.rescale(names, scale)
        f, ax, _ = graphplot(
            g, arrow_show=true, 
            arrow_size=arrow_size, edge_width=edge_size, node_color=colors,
            nlabels=names,
            nlabels_align=(:center, :center),
            nlabels_attr=(; font, textsize=16f0),
            node_size=node_size, layout=layout
        )
        hidedecorations!(ax)
        hidespines!(ax)
        plot[] = f
    end
    return jsrender(session, DOM.div(plot))
end
