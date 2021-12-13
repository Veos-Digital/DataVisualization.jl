const AutocompleteOptions = Vector{Tuple{String, Vector{String}}}

to_autocomplete_options(options::Union{AbstractArray, Tuple}) = vecmap(Tuple, options)
to_autocomplete_options(options::AbstractDict) = [Tuple(p) for p in pairs(options)]
to_autocomplete_options(options::AbstractObservable) = lift(to_autocomplete_options, options)

struct Autocomplete
    value::Observable{String}
    options::Observable{AutocompleteOptions}
    list::List
end

function Autocomplete(value::Observable, options::Observable{AutocompleteOptions})
    return Autocomplete(value, options, List(Observable(String[]), value))
end

function Autocomplete(value::Observable, options′)
    options::Observable{AutocompleteOptions} = to_autocomplete_options(options′)
    return Autocomplete(value, options)
end

function jsrender(session::Session, wdg::Autocomplete)

    hidden, keydown = wdg.list.hidden,wdg.list.keydown

    list = jsrender(session, wdg.list)

    input = DOM.input(
        onfocus=js"JSServe.update_obs($(hidden), false)",
        onblur=js"""
            const tgt = event.relatedTarget;
            if (tgt && $(list).contains(tgt)) {
                this.focus();
            } else {
                JSServe.update_obs($(hidden), true);
            }
        """,
        class="w-full",
        type="text",
        autocomplete="off",
        spellcheck=false,
        value=wdg.value,
        oninput=js"JSServe.update_obs($(wdg.value), this.value)",
        onkeydown=js"event.key == 'Escape' ? this.blur() : JSServe.update_obs($(keydown), event.key)"
    )

    ui = DOM.div(input, list)

    onjs(session, wdg.value, js"""
        function (value) {
            const options = JSServe.get_observable($(wdg.options));
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
            const values = keys.map(key => value.slice(0, idx + 1) + key);
            JSServe.update_obs($(wdg.list.entries), {keys, values});
        }
    """)

    notify!(wdg.value)

    return jsrender(session, ui)
end

struct RichTextField
    name::String
    widget::Autocomplete
    default::String
    parsed::Vector{Call}
    confirmedvalue::Observable{String}
end

function RichTextField(name, widget::Autocomplete, default)
    rtf = RichTextField(name, widget, default, Call[], Observable(widget.value[]))
    parse!(rtf)
    return rtf
end

function RichTextField(name, options, default)
    wdg = Autocomplete(Observable(default), options)
    return RichTextField(name, wdg, default)
end

function parse!(rtf::RichTextField)
    value = rtf.widget.value[]
    empty!(rtf.parsed)
    append!(rtf.parsed, compute_calls(value))
    rtf.confirmedvalue[] = value
    return
end

function reset!(rtf::RichTextField)
    rtf.widget.value[] = rtf.default
    parse!(rtf)
end

maybethrow(e::Exception; strict) = strict ? throw(e) : nothing

function extract_call(rtf::RichTextField; strict=true)
    calls = rtf.parsed
    length(calls) == 1 || maybethrow(ArgumentError("Field $(rtf.name) must have a unique addend"); strict)
    return first(calls) 
end

function extract_positional_argument(rtf::RichTextField; strict=true)
    positionals = extract_call(rtf; strict).positional
    length(positionals) == 1 || maybethrow(ArgumentError("Field $(rtf.name) must have a unique positional argument"); strict)
    return first(positionals)
end

extract_positional_arguments(rtf::RichTextField; strict=true) = extract_call(rtf; strict).positional

function extract_positional_arguments(rtf::RichTextField, n::Int; strict=true)
    positionals = extract_positional_arguments(rtf; strict)
    length(positionals) == n || maybethrow(ArgumentError("Field $(rtf.name) must have exactly $n positional arguments"); strict)
    return positionals
end

extract_named_arguments(rtf::RichTextField; strict=true) = extract_call(rtf; strict).named

function extract_all_arguments(rtf::RichTextField; strict=true)
    positional = extract_positional_arguments(rtf; strict)
    named = extract_named_arguments(rtf; strict)
    return positional, named
end

function extract_function(rtf::RichTextField; strict=true)
    fs = extract_call(rtf; strict).fs
    length(fs) == 1 || maybethrow(ArgumentError("Field $(rtf.name) must have a unique function"); strict)
    return first(fs)
end

function jsrender(session::Session, rtf::RichTextField)
    label = DOM.p(class="text-blue-800 text-xl font-semibold py-4 w-full text-left", rtf.name)
    ui = DOM.div(class="mb-4", label, rtf.widget)
    return jsrender(session, ui)
end
