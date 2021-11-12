struct List
    entries::Observable{Vector{String}}
    value::Observable{String}
end

function styled_list(entries=String[], value=Observable(""))
    activeClasses = ("text-gray-900", "bg-gray-200")
    inactiveClasses = ("text-gray-700",)
    itemclass = "cursor-pointer px-4 py-2 bg-white $(join(inactiveClasses, ' ')) $(join("hover:" .* activeClasses, ' '))"
    lis = map(entries) do entry
        return DOM.li(
            entry,
            class=itemclass,
            role="menuitem",
            tabIndex=-1,
            dataValue=entry,
            style="display:block;",
            onclick=js"JSServe.update_obs($(value), $(entry))"
        )
    end
    return DOM.ul(
        lis...,
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;",
    )
end

function jsrender(session::Session, list::List)
    ui = map(entries -> styled_list(entries, list.value), session, list.entries)
    return jsrender(session, ui)
end
