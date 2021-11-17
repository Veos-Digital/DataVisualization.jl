struct List
    entries::Observable{Vector{@NamedTuple{key::String, value::String}}}
    value::Observable{String}
end

List(entries::Observable) = List(entries, Observable(""))

to_entries(keys) = map(key -> (; key, value=key), keys)

function styled_list()
    return DOM.ul(
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;",
    )
end

# TODO: factor out common component
function jsrender(session::Session, l::List)
    activeClasses = ("text-gray-900", "bg-gray-200")
    inactiveClasses = ("text-gray-700",)
    itemclass = "cursor-pointer px-4 py-2 bg-white $(join(inactiveClasses, ' ')) $(join("hover:" .* activeClasses, ' '))"
    list = styled_list()
    onjs(session, l.entries, js"""
        function (entries) {
            const keys = entries.map(entry => entry.key);
            const values = entries.map(entry => entry.value);
            const list = $(list);
            while (list.childNodes.length > keys.length) {
                list.removeChild(list.lastChild);
            }
            for (let i = 0; i < keys.length; i++) {
                if (i >= list.children.length) {
                    const node = document.createElement("li");
                    node.classList.add("cursor-pointer");
                    node.role = "menuitem";
                    node.tabIndex = -1;
                    node.style.display = "block";
                    node.onclick = function (event) {
                        JSServe.update_obs($(l.value), event.target.dataset.value);
                    };
                    $(UtilitiesJS).addClass(node, $(itemclass));
                    list.appendChild(node);
                }
                const child = list.children[i];
                child.innerText = keys[i];
                child.dataset.value = values[i];
            }
        }
    """)
    notify!(l.entries)
    return jsrender(session, list)
end
