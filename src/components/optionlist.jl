# TODO: add `selected` `Observable` here as well 
struct List
    entries::Observable{Dict{String, Vector{String}}}
    value::Observable{String}
end

List(entries::Observable{Dict{String, Vector{String}}}) = List(entries, Observable(""))
List(keys::Observable{Vector{String}}, value::Observable{String}=Observable("")) = List(lift(to_entries, keys), value)

function to_entries(keys::AbstractVector{<:AbstractString})
    return Dict("keys" => collect(String, keys), "values" => collect(String, keys))
end

function jsrender(session::Session, l::List)

    activeClasses = ["text-gray-900", "bg-gray-200"]
    inactiveClasses = ["text-gray-700"]
    fixedClasses = ["cursor-pointer", "px-4", "py-2", "bg-white"]
    itemClasses = vcat(fixedClasses, inactiveClasses, "hover:" .* activeClasses)

    list = DOM.ul(
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;",
    )

    onjs(session, l.entries, js"""
        function (entries) {
            const {keys, values} = entries;
            const list = $(list);
            const classes = $(itemClasses);
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
                    node.classList.add(...classes);
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
