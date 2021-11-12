struct List
    entries::Observable{Vector{String}}
end

function styled_list(entries=String[])
    activeClasses = ("text-gray-900", "bg-gray-200")
    inactiveClasses = ("text-gray-700",)
    itemclass = "cursor-pointer px-4 py-2 bg-white $(join(inactiveClasses, ' ')) $(join("hover:" .* activeClasses, ' '))"
    lis = map(entry -> DOM.li(entry, class=itemclass), entries)
    return DOM.ul(
        lis,
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;",
    )
end

function jsrender(session::Session, list::List)
    ui = map(styled_list, session, list.entries)
    return jsrender(session, ui)
end
