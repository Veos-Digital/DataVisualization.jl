struct Pipelines
    pipelines::AbstractVector
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
    un = reduce(vcat, get_vertex_names.(pipelines.pipelines))
    uc = palette[eachindex(un)]
    scale = AlgebraOfGraphics.CategoricalScale(un, uc, palette, "Step")

    # FIXME: consider adding filtering as well
    nested_vertices = lift(output(last(pipelines.pipelines))) do _
        return get_vertices.(pipelines.pipelines)
    end
    g = @lift simpledigraph($nested_vertices)

    names = @lift mapreduce(get_vertex_names, append!, $nested_vertices)
    node_color = @lift AlgebraOfGraphics.rescale($names, scale)
    # nlabels = @lift string.(eachindex($names))
    fig = Figure(; backgroundcolor=colorant"#F3F4F6")
    # FIXME: figure out cleanest way to set a reasonable size
    pixelratio = get_pixelratio(session)
    sz = @lift(round(Int, 500 * $pixelratio))
    on(sz) do sz
        sx, sy = round(Int, sz * 1.5), round(Int, sz * 1.2)
        resize!(fig.scene, (sx, sy))
    end

    ax = Axis(fig[1, 1], width=sz, height=sz)
    # FIXME: pass observable directly
    on(g) do graph
        points = layout(graph)
        xlims = extrema(first, points)
        ylims = extrema(last, points)
        xlims!(ax, xlims[1] - 0.5,  xlims[2] + 0.5)
        ylims!(ax, ylims[1] - 0.5,  ylims[2] + 0.5)
    end
    notify!(g)
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
