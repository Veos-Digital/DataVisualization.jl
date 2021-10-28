const AutocompleteOptions = Vector{Tuple{String, Vector{String}}}

to_autocomplete_options(options::Union{AbstractArray, Tuple}) = vecmap(Tuple, options)
to_autocomplete_options(options::AbstractDict) = [Tuple(p) for p in pairs(options)]

struct Autocomplete
    value::Observable{String}
    options::Observable{AutocompleteOptions}
end

function Autocomplete(value::Observable, options′)
    options = Observable(to_autocomplete_options(options′))
    return Autocomplete(value, options)
end

function Autocomplete(session::Session, value::Observable, options′::Observable)
    options = map(to_autocomplete_options, session, options′; result=Observable{AutocompleteOptions}())
    return Autocomplete(value, options)
end

Autocomplete(session::Session, value::Observable, options′) = Autocomplete(value, options′)

function autocomplete_script(options::Observable{AutocompleteOptions})
    return js"""
        function (value) {
            const options = JSServe.get_observable($(options));
            const pre = options.map(e => e[0]);
            const post = options.map(e => e[1]);
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

    script = autocomplete_script(wdg.options)

    onValue = js"""
        function (value) {
            const res = ($(script)(value));
            const list = $(list);
            for (let i = list.childNodes.length; i > res.keys.length; i--) {
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

struct RichTextField
    name::String
    widget::Autocomplete
    default::String
    parsed::Vector{Call}
end

function RichTextField(name, widget::Autocomplete, default)
    rtf = RichTextField(name, widget, default, Call[])
    parse!(rtf)
    return rtf
end

function RichTextField(name, options, default)
    wdg = Autocomplete(Observable(default), lift(to_autocomplete_options, convert(Observable, options)))
    return RichTextField(name, wdg, default)
end

function parse!(rtf::RichTextField)
    empty!(rtf.parsed)
    append!(rtf.parsed, compute_calls(rtf.widget.value[]))
end

function reset!(rtf::RichTextField)
    rtf.widget.value[] = rtf.default
    parse!(rtf)
end

function jsrender(session::Session, rtf::RichTextField)
    label = DOM.p(class="text-blue-800 text-xl font-semibold p-4 w-full text-left", rtf.name)
    ui = DOM.div(class="mb-4", label, DOM.div(class="pl-4", rtf.widget))
    return jsrender(session, ui)
end
