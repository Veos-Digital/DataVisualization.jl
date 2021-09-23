struct Togglers
    options::Vector{Option}
end

function jsrender(session::Session, togglers::Togglers)
    options = togglers.options
    toggles = map(options) do entry
        selected = entry.selected
        isoriginal = entry.value.isoriginal
        reset = Observable(true)
        JSServe.register_resource!(session, reset)
        on(session, reset) do _
            reset!(entry.value)
        end
        modified = DOM.span(
            class="float-right p-4 inline-block hover:text-red-300",
            "⬤",
            style=isoriginal[] ? "display:none" : "display:inline",
            onclick=string(js"JSServe.update_obs($(reset), true)")
        )
        onjs(session, isoriginal, js"""
            function (val) {
                $(modified).style.display = val ? "none" : "inline";
            }
        """
        )
        content = DOM.div(style="display:none", class="p-4 bg-white rounded-b", jsrender(session, entry.value))
        button = DOM.button(
            class="text-blue-800 text-xl font-semibold border-b-2 border-gray-200 hover:bg-gray-200 w-full text-left",
            onclick=string(js"""
                if (!$(modified).isEqualNode(event.target)) {
                    JSServe.update_obs($selected, !(JSServe.get_observable($selected)))
                }
            """), # FIXME: report to JSServe that this requires string
            DOM.span(class="pl-4 py-4 inline-block", entry.key),
            modified
        )
        onjs(
            session,
            selected,
            js"""
                function (val) {
                    $(content).style.display = val ? "block" : "none";
                    $(button).classList.toggle("border-b-2")
                }
            """
        )
        return DOM.div(button, content)
    end
    return DOM.div(toggles...)
end
