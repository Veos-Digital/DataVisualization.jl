struct Chart{T} <: AbstractVisualization{T}
    table::Observable{T}
    plotspecs::PlotSpecs
end

Chart(table::Observable{T}) where {T} = Chart{T}(table, PlotSpecs(table))

to_algebraic(chart::Chart) = data(chart.table[]) * to_algebraic(chart.plotspecs)

defaultplot() = Figure(; backgroundcolor=colorant"#F3F4F6")

function jsrender(session::Session, chart::Chart)

    plot = Observable{Figure}(defaultplot())

    pixelratio = Observable(1.0)
    evaljs(session, js"$(UtilitiesJS).trackPixelRatio($(pixelratio))")

    reset_plot!(_) = plot[] = defaultplot()
    function update_plot!(_)
        is_set(chart.plotspecs) || return
        plt = to_algebraic(chart)
        pr = pixelratio[]
        axis = (width=round(Int, 350pr), height=round(Int, 350pr))
        fg = draw(plt; axis)
        plot[] = fg.figure
    end

    plot_button = Button("Plot", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))
    plotui = DOM.div(
        chart.plotspecs,
        DOM.div(class="mt-12 pl-4", plot_button, clear_button),
        class="pr-16"
    )

    tryon(update_plot!, session, plot_button.value)
    tryon(update_plot!, session, chart.plotspecs.names) # gets updated when table changes
    tryon(reset_plot!, session, clear_button.value)

    layout = DOM.div(
        class="grid grid-cols-3",
        DOM.div(class="col-span-1", plotui),
        DOM.div(class="col-span-2 pl-16", plot)
    )
    return jsrender(session, layout)
end
