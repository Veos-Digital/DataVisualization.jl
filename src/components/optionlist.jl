Base.@kwdef struct List
    entries::Observable{Dict{String, Vector{String}}}
    value::Observable{String}
    selected::Observable{Union{Int, Nothing}}=Observable{Union{Int, Nothing}}(nothing) # 0-based indexing
    hidden::Observable{Bool}=Observable(true)
    keydown::Observable{String}=Observable("")
end

function List(keys::Observable{Vector{String}}, value::Observable{String}; kwargs...)
    entries = lift(to_entries, keys)
    return List(; entries, value, kwargs...)
end

function List(entries::Observable{Dict{String, Vector{String}}}, value::Observable{String}; kwargs...)
    return List(; entries, value, kwargs...)
end

function to_entries(keys::AbstractVector{<:AbstractString})
    return Dict("keys" => collect(String, keys), "values" => collect(String, keys))
end

function jsrender(session::Session, l::List)

    activeClasses = ["text-gray-900", "bg-gray-200"]
    inactiveClasses = ["text-gray-700"]
    fixedClasses = ["cursor-pointer", "px-4", "py-2", "bg-white"]
    itemClasses = vcat(fixedClasses, inactiveClasses, "hover:" .* activeClasses)

    hidden, selected = l.hidden, l.selected

    list = DOM.ul(;
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;"
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
            JSServe.update_obs($(selected), null);
        }
    """)

    # Add behavior when user presses key
    onjs(session, l.keydown, js"""
        function(key) {
            const selected = JSServe.get_observable($(selected));
            const children = $(list).children;
            const len = children.length;
            if (key == "ArrowDown") {
                JSServe.update_obs($(selected), $(UtilitiesJS).cycle(selected, len, 1))
            } else if (key == "ArrowUp") {
                JSServe.update_obs($(selected), $(UtilitiesJS).cycle(selected, len, -1))
            } else if (key == "Enter" || key == "Tab") {
                if (selected !== null && len > 0) {
                    const child = children[selected];
                    JSServe.update_obs($(l.value), child.dataset.value);
                }
            }
        }
    """)

    # Style selected options
    onjs(session, selected, js"idx => $(UtilitiesJS).styleSelected($(list).children, idx, $activeClasses, $inactiveClasses)")
    # When out of focus, unselect
    onjs(session, hidden, js"hidden => hidden && JSServe.update_obs($(selected), null)")

    notify!(l.entries)

    ui = DOM.div(list; style="position: relative; z-index: 1;", hidden)
    return jsrender(session, ui)
end
