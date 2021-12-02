struct Option{T}
    key::String
    value::T
    selected::Observable{Bool}
end

Option(key::String, value, selected::Bool=true) = Option(key::String, value, Observable(selected))

struct Checkboxes{T}
    options::Vector{Option{T}}
    isoriginal::Observable{Bool}
end

function Checkboxes(options)
    obs = (option.selected for option in options)
    isoriginal = map((args...) -> all(args), obs...)
    return Checkboxes(options, isoriginal)
end

function reset!(wdg::Checkboxes)
    for option in wdg.options
        option.selected[] = true
    end
end

function jsrender(session::Session, wdg::Checkboxes)
    list = map(wdg.options) do option
        k, v, s = option.key, option.value, option.selected
        update = js"JSServe.update_obs($s, this.checked)"
        return DOM.label(
            DOM.input(
                class="form-checkbox",
                type="checkbox",
                checked=s,
                value=v,
                onclick=update,
            ),
            DOM.span(class="ml-2", k),
            class="inline-flex items-center"
        )
    end
    layout = DOM.div(class="grid grid-cols-1 md:grid-cols-2 gap-4", list...)
    return jsrender(session, layout)
end
