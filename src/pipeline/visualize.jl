struct Visualize{T} <: AbstractPipeline{T}
    table::Observable{T}
    plotspecs::PlotSpecs
end

Visualize(table::Observable{T}) where {T} = Visualize{T}(table, PlotSpecs(table))

output(v::Visualize) = v.table # output equals input for `Visualize`

to_algebraic(v::Visualize) = data(v.table[]) * to_algebraic(v.plotspecs)

defaultplot() = Figure(; backgroundcolor=colorant"#F3F4F6")

function jsrender(session::Session, v::Visualize)

    plot = Observable{Figure}(defaultplot())

    pixelratio = Observable(1.0)
    evaljs(session, js"$(UtilitiesJS).trackPixelRatio($(pixelratio))")

    reset_plot!(_) = plot[] = defaultplot()
    function update_plot!(_)
        is_set(v.plotspecs) || return
        plt = to_algebraic(v)
        pr = pixelratio[]
        axis = (width=round(Int, 350pr), height=round(Int, 350pr))
        fg = draw(plt; axis)
        plot[] = fg.figure
    end

    plot_button = Button("Plot", class=buttonclass(true))
    clear_button = Button("Clear", class=buttonclass(false))
    plotui = DOM.div(
        v.plotspecs,
        DOM.div(class="mt-12 pl-4", plot_button, clear_button),
        class="pr-16"
    )

    tryon(update_plot!, session, plot_button.value)
    tryon(update_plot!, session, v.plotspecs.names) # gets updated when table changes
    tryon(reset_plot!, session, clear_button.value)

    layout = DOM.div(
        class="grid grid-cols-3",
        DOM.div(class="col-span-1", plotui),
        DOM.div(class="col-span-2 pl-16", plot)
    )
    return jsrender(session, layout)
end
