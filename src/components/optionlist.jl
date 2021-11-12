struct List
    entries::Observable{Vector{String}}
end

function styled_list(args...)
    return DOM.ul(
        args...,
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;",
    )
end

function jsrender(session::Session, list::List)
    ui = map(styled_list, session, list)
    return jsrender(session, ui)
end
