struct Pipelines
    pipelines::AbstractVector
end

function layout(g::SimpleDiGraph)
    xs, ys, _ = solve_positions(Zarate(), g)
    return Point.(ys, -xs)
end

function jsrender(session::Session, pipelines::Pipelines)
    arrow_size = 25
    edge_width = 5
    node_size = 45
    legend_node_size = 20
    colgap = 150

    # set general legend
    palette = vcat(RGB(colorant"black"), Makie.current_default_theme().palette.color[])
    un = reduce(vcat, get_vertex_names.(pipelines.pipelines))
    uc = palette[eachindex(un)]
    scale = AlgebraOfGraphics.CategoricalScale(un, uc, palette, "Step")

    nested_vertices = lift(output(last(pipelines.pipelines))) do _
        return get_vertices.(pipelines.pipelines)
    end
    g = @lift simpledigraph($nested_vertices)

    names = @lift mapreduce(get_vertex_names, append!, $nested_vertices)
    node_color = @lift AlgebraOfGraphics.rescale($names, scale)
    # work around https://github.com/JuliaPlots/GraphMakie.jl/issues/42 
    edge_color = @lift ne($g) > 0 ? :black : :transparent
    backgroundcolor = colorant"#F3F4F6"
    width, height = Observable(350), Observable(350)
    fig = Figure(; backgroundcolor)
    ax = Axis(fig[1, 1]; width, height, backgroundcolor)

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
        edge_width, edge_color,
        node_size, node_color,
        layout
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
