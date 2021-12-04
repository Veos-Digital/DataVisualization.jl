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
    # font = AlgebraOfGraphics.firasans("Medium")
    # textsize = 28
    arrow_size = 25
    edge_width = 3
    node_size = 45
    legend_node_size = 20
    colgap = 150
    # set general legend
    palette = vcat(RGB(colorant"black"), Makie.current_default_theme().palette.color[])
    un = vcat(:Data, collect(keys(PROCESSING_STEPS)))
    uc = palette[eachindex(un)]
    scale = AlgebraOfGraphics.CategoricalScale(un, uc, palette, "Step")

    # FIXME: remove hack and add data node in black
    # FIXME: use `map(f, session, obs)` method instead
    vertices = @lift vcat(Vertex(:Data, Symbol[], Symbol[]), Vertex.($(pipelines.steps)))
    g = @lift simpledigraph($vertices)
    names = @lift map(vertex -> vertex.name, $vertices)
    node_color = @lift AlgebraOfGraphics.rescale($names, scale)
    # nlabels = @lift string.(eachindex($vertices))
    fig = Figure(; backgroundcolor=colorant"#F3F4F6")
    ax = Axis(fig[1, 1])
    # FIXME: should also update when values of cards change, maybe use output for this?
    # In retrospect, maybe only update on value
    graphplot!(ax, g;
        arrow_show=true, arrow_size, 
        edge_width, node_color,
        # nlabels, nlabels_align=(:center, :center), FIXME: support interactivity here
        # nlabels_attr=(; font, textsize, color=:white),
        node_size, layout
    )
    hidedecorations!(ax)
    hidespines!(ax)
    Legend(
        fig[1, 2],
        [MarkerElement(; color, marker=:circle, markersize=legend_node_size) for color in scale.plot],
        string.(scale.data), scale.label
    )
    colgap!(fig.layout, colgap)
    return jsrender(session, scrollable_component(fig))
end
