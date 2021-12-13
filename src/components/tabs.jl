struct Tabs
    options::SimpleList
    activetab::Observable{Int}
end

Tabs(options::SimpleList) = Tabs(options, Observable(1))
function Tabs(nt::Union{AbstractDict, NamedTuple}, activetab=Observable(1))
    options = Iterators.map(pairs(nt)) do (k, v)
        return SimpleDict("key" => k, "value" => v)
    end
    return Tabs(collect(Any, options), activetab)
end

function jsrender(session::Session, tabs::Tabs)
    options, activetab = tabs.options, tabs.activetab
    activeClasses = ["shadow", "bg-white"]
    inactiveClasses = String[]

    nodes = [DOM.li(
        class="text-blue-800 text-2xl font-semibold rounded mr-4 px-4 py-2 cursor-pointer hover:bg-gray-200",
        onclick=js"JSServe.update_obs($activetab, $i)",
        getkey(option)
    ) for (i, option) in enumerate(options)]
    headers = DOM.ul(class="flex mb-12", nodes)

    onjs(session, activetab, js"""
        function (idx) {
            $(UtilitiesJS).styleSelected($(nodes), idx - 1, $activeClasses, $inactiveClasses);
        }
    """)
    activetab[] = activetab[]

    contents = map(enumerate(options)) do (i, option)
        display = activetab[] == i ? "block" : "none"
        content = DOM.div(style="display: $display;", getvalue(option))
        onjs(
            session,
            activetab,
            js"""
                function (val) {
                    $(content).style.display = (val == $i) ? "block" : "none";
                }
            """
        )
        return jsrender(session, content)
    end
    return DOM.div(
        class="flex flex-col h-screen py-8",
        DOM.div(class="flex-initial", headers),
        DOM.div(class="flex-auto", contents...)
    )
end