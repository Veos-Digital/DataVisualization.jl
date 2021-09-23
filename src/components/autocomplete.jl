struct Autocomplete
    f::JSServe.JSCode
    value::Observable{String}
end

Autocomplete(value::Observable, options) = Autocomplete(value, collect(keys(options)), collect(values(options)))

function Autocomplete(value::Observable, pre, post′)
    post = map(t -> t isa Union{AbstractArray, Tuple} ? t : [t], post′)
    f = js"""
        function (value) {
            const pre = $(pre);
            const post = $(post);
            const lastSpace = value.lastIndexOf(' ');
            const lastColon = value.lastIndexOf(':');
            const idx = Math.max(lastSpace, lastColon);
            let list
                if (lastSpace < lastColon) {
                const key = value.slice(lastSpace + 1, lastColon);
                const extendedKey = value.slice(value.lastIndexOf(' ', lastSpace - 1) + 1, lastColon)
                const target = post[pre.indexOf(extendedKey)] || post[pre.indexOf(key)]
                list = target.map(str => str + ' ');
            } else {
                list = pre.map((str, i) => str + (post[i].length ? ':' : ' '));
            }
            const slice = value.slice(idx + 1, value.length)
            const keys = list.filter(text => text && text.toLowerCase().startsWith(slice.toLowerCase()));
            const values = keys.map(option => value.slice(0, idx + 1) + option);
            return {keys, values}
        }
    """
    return Autocomplete(f, value)
end

function jsrender(session::Session, wdg::Autocomplete)

    isblur = Observable(true)
    selected = Observable{Union{Int, Nothing}}(nothing) # 0-based indexing
    keydown = Observable("")

    list = DOM.ul(
        class="border-2 border-gray-200 max-h-64",
        role="menu",
        style="position: absolute; left:0; right:0; top:0.5rem; overflow-y: scroll;",
    )

    input = DOM.input(
        onfocusin=js"JSServe.update_obs($(isblur), false)",
        onfocusout=js"""
            const tgt = event.relatedTarget;
            tgt && $(list).contains(tgt) || JSServe.update_obs($(isblur), true);
        """,
        class="w-full",
        type="text",
        autocomplete="off",
        spellcheck=false,
        value=wdg.value,
        oninput=js"JSServe.update_obs($(wdg.value), this.value)",
        onkeydown=js"JSServe.update_obs($(keydown), event.key)"
    )

    div = DOM.div(input, DOM.div(style="position: relative; z-index: 1;", hidden=isblur, list))

    activeClasses = ("text-gray-900", "bg-gray-200")
    inactiveClasses = ("text-gray-700",)
    itemclass = "px-4 py-2 bg-white $(join(inactiveClasses, ' ')) $(join("hover:" .* activeClasses, ' '))"

    # Add behavior when user presses key
    onjs(session, keydown, js"""
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
                    JSServe.update_obs($(wdg.value), child.dataset.value);
                }
            } else if (key == "Escape") {
                $(input).blur();
            }
        }
    """)

    onjs(session, selected, js"idx => $(UtilitiesJS).styleSelected($(list).children, idx, $activeClasses, $inactiveClasses)")
    # When out of focus, unselect
    onjs(session, isblur, js"isblur => isblur && JSServe.update_obs($(selected), null)")

    onValue = js"""
        function (value) {
            const res = ($(wdg.f)(value));
            const list = $(list);
            for (let i = list.childNodes.length; i >= res.keys.length; i--) {
                list.removeChild(list.lastChild);
            }
            for (let i = 0; i < res.keys.length; i++) {
                if (i >= list.children.length) {
                    const node = document.createElement("li");
                    node.classList.add("cursor-pointer");
                    node.role = "menuitem";
                    node.tabIndex = -1;
                    node.style.display = "block";
                    node.onclick = function (event) {
                        JSServe.update_obs($(wdg.value), event.target.dataset.value);
                    };
                    $(UtilitiesJS).addClass(node, $(itemclass));
                    list.appendChild(node);
                }
                const child = list.children[i];
                child.innerText = res.keys[i];
                child.dataset.value = res.values[i];
            }
            JSServe.update_obs($(selected), null);
        }
    """

    evaljs(session, js"($(onValue))($(wdg.value[]))")
    onjs(session, wdg.value, js"""
        function (value) {
            ($onValue)(value);
            $(input).focus();
        }
    """)

    return jsrender(session, div)
end
