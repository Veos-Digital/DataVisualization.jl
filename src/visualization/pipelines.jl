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
    edge_width = 5
    node_size = 45
    legend_node_size = 20
    colgap = 150
    # set general legend
    palette = Makie.current_default_theme().palette.color[]
    un = reduce(vcat, get_vertex_names.(pipelines.pipelines))
    uc = palette[eachindex(un)]
    push!(un, :Output)
    push!(uc, RGB(colorant"black"))
    scale = AlgebraOfGraphics.CategoricalScale(un, uc, palette, "Step")

    # FIXME: consider adding filtering as well
    # FIXME: dot is not removed when removing card, but it should be
    nested_vertices = lift(output(last(pipelines.pipelines))) do value
        local nested_vertices = get_vertices.(pipelines.pipelines)
        colnames = collect(Tables.columnnames(value))
        push!(nested_vertices, [Vertex(:Output, colnames, colnames)])
        return nested_vertices
    end
    g = @lift simpledigraph($nested_vertices)

    names = @lift mapreduce(get_vertex_names, append!, $nested_vertices)
    node_color = @lift AlgebraOfGraphics.rescale($names, scale)
    # nlabels = @lift string.(eachindex($names))
    backgroundcolor = colorant"#F3F4F6"
    width, height = Observable(350), Observable(350)
    fig = Figure(; backgroundcolor)
    ax = Axis(fig[1, 1]; width, height, backgroundcolor)

    # TODO: pass observable directly?
    on(g) do graph
        points = layout(graph)
        xlims = extrema(first, points)
        ylims = extrema(last, points)
        xlims!(ax, xlims[1] - 0.25,  xlims[2] + 0.25)
        ylims!(ax, ylims[1] - 0.25,  ylims[2] + 0.25)
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
    on_pixelratio(session, once=true) do pr
        width[] = round(Int, 350pr)
        height[] = round(Int, 350pr)
        AlgebraOfGraphics.resizetocontent!(fig)
    end

    return jsrender(session, scrollable_component(fig))
end
