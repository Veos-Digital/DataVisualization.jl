struct Option{T}
    key::String
    value::T
    selected::Observable{Bool}
end

Option(key::String, value, selected::Bool=true) = Option(key::String, value, Observable(selected))

# Pass `Dict("keys" => ..., "values" => ..., "selected" => ...)` as options
struct Checkboxes
    options::Dict{String, Vector}
end

isoriginal(cb::Checkboxes) = all(getindex, cb.options["selected"])

reset!(wdg::Checkboxes) = foreach(obs -> (obs[] = true), wdg.options["selected"])

function jsrender(session::Session, wdg::Checkboxes)
    options = wdg.options
    list = map(options["keys"], options["values"], options["selected"]) do k, v, s
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
