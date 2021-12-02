struct Tabs{T}
    options::Vector{Option{T}}
end

function Tabs(nt::NamedTuple)
    T = eltype(nt)
    options = [Option{T}(string(key), val, true) for (key, val) in pairs(nt)]
    return Tabs(options)
end

function jsrender(session::Session, tabs::Tabs)
    activetab = Observable(1)
    options = tabs.options
    activeClasses = ["shadow", "bg-white"]
    inactiveClasses = String[]

    nodes = [DOM.li(
        class="text-blue-800 text-2xl font-semibold rounded mr-4 px-4 py-2 cursor-pointer hover:bg-gray-200",
        onclick=js"JSServe.update_obs($activetab, $i)",
        options[i].key
    ) for i in eachindex(options)]
    headers = DOM.ul(class="flex mb-12", nodes)

    onjs(session, activetab, js"""
        function (idx) {
            $(UtilitiesJS).styleSelected($(nodes), idx - 1, $activeClasses, $inactiveClasses);
        }
    """)
    activetab[] = activetab[]

    contents = map(eachindex(options)) do i
        display = activetab[] == i ? "block" : "none"
        content = DOM.div(style="display: $display;", options[i].value)
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