struct Tabs
    options::Dict{String, Vector}
    activetab::Observable{Int}
end

Tabs(options::Dict{String, Vector}) = Tabs(options, Observable(1))
function Tabs(nt::Union{AbstractDict, NamedTuple}, activetab=Observable(1))
    options = Dict("keys" => collect(keys(nt)), "values" => collect(values(nt)))
    return Tabs(options, activetab)
end

function jsrender(session::Session, tabs::Tabs)
    options, activetab = tabs.options, tabs.activetab
    activeClasses = ["shadow", "bg-white"]
    inactiveClasses = String[]

    nodes = [DOM.li(
        class="text-blue-800 text-2xl font-semibold rounded mr-4 px-4 py-2 cursor-pointer hover:bg-gray-200",
        onclick=js"JSServe.update_obs($activetab, $i)",
        key
    ) for (i, key) in enumerate(options["keys"])]
    headers = DOM.ul(class="flex mb-12", nodes)

    onjs(session, activetab, js"""
        function (idx) {
            $(UtilitiesJS).styleSelected($(nodes), idx - 1, $activeClasses, $inactiveClasses);
        }
    """)
    activetab[] = activetab[]

    contents = map(enumerate(options["values"])) do (i, value)
        display = activetab[] == i ? "block" : "none"
        content = DOM.div(style="display: $display;", value)
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