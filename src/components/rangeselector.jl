struct RangeSelector{T <: AbstractRange, ET}
    range::T
    selected::NTuple{2, Observable{ET}}
    isoriginal::Observable{Bool}
end

function RangeSelector(range::AbstractRange)
    min, max = extrema(range)
    selected = map(Observable, (min, max))
    isoriginal = map(selected...) do smin, smax
        return smin ≤ min && smax ≥ max
    end
    return RangeSelector(range, selected, isoriginal)
end

function reset!(wdg::RangeSelector)
    foreach(wdg.selected, extrema(wdg.range)) do obs, val
        obs[] = val
    end
end

function jsrender(session::Session, rg::RangeSelector)
    range = rg.range
    # FIXME: report to JSServe that passing observable to value does not work
    inputs = map(rg.selected) do obs
        input = DOM.input(
            type="number",
            min=minimum(range),
            max=maximum(range),
            step=step(range),
            oninput=js"""
                var val = parseFloat(this.value);
                if (!isNaN(val)) {
                    JSServe.update_obs($obs, val);
                }
            """ |> string
        )
        onload(session, input, js"""
            function (div) {
                div.value = $(obs[]);
            }
        """)
        onjs(session, obs, js"""
            function (val) {
                $(input).value = val;
            }
        """)
        return input
    end
    return DOM.form(class="flex justify-between", inputs...)
end
