struct AddNewCard
    entries::Observable{Vector{@NamedTuple{key::String, value::String}}}
    value::Observable{String}
    isblur::Observable{Bool}
end

function AddNewCard(keys::Observable{Vector{String}}, value=Observable(""))
    entries = lift(to_entries, keys)
    return AddNewCard(entries, value, Observable(true))
end

function jsrender(session::Session, add::AddNewCard)
    l = List(add.entries, add.value)
    list = JSServe.jsrender(session, l)
    isblur = add.isblur
    onfocusin = js"JSServe.update_obs($(isblur), false)"
    onfocusout=js"""
        const tgt = event.relatedTarget;
        tgt && $(list).contains(tgt) || JSServe.update_obs($(isblur), true);
    """
    box = DOM.button(
        "+";
        class="w-full p-8 cursor-pointer text-left text-blue-800 text-2xl hover:bg-gray-200 hover:text-blue-900",
        onfocusin,
        onfocusout,
    )
    ui = DOM.div(box, DOM.div(list, style="position: relative; z-index: 1;", hidden=isblur))
    return jsrender(session, ui)
end

const StringLittleDict{T} = LittleDict{String, T, Vector{String}, Vector{T}}

function to_stringdict(p)
    k = String[string(key) for key in keys(p)]
    v = Any[v for v in values(p)]
    return LittleDict(k, v)
end

struct EditableList
    keys::Observable{Vector{String}}
    options::Observable{StringLittleDict{Any}}
    steps::Observable{Vector{Any}}
    list::Observable{Vector{Any}}
    add_selected::Observable{Int}
    card_selected::Observable{Int}
end

function add_callbacks!(add::AddNewCard, el::EditableList)
    return add
end
#     on(add.value) do val
#         list = el.list[]
#         id = objectid(add)
#         idx = findfirst(==(id)∘objectid, list)
#         _selected = count(x -> x isa AddNewCard, view(list, 1:idx))
#         el.selected[] = _selected
#         _steps = el.steps[]
#         for (idx, step) in enumerate(_steps)
#             if step.card.selected
#                 old = idx
#                 new = _selected - (_selected > old)
#                 el.steps[] = move_item(_steps, old => new)
#             end
#         end
#     end
#     return add
# end

function EditableList(options::Observable, steps::Observable)
    keys = lift(options) do options
        acc = ["Move Selected"]
        for key in Base.keys(options)
            push!(acc, key)
        end
        return acc
    end
    add_selected, card_selected = Observable(0), Observable(0)
    list = Observable{Vector{Any}}()
    el = EditableList(keys, options, steps, list, add_selected, card_selected)
    map!(list, steps) do steps
        elements = Any[]
        push!(elements, add_callbacks!(AddNewCard(keys), el))
        for step in steps
            push!(elements, step)
            push!(elements, add_callbacks!(AddNewCard(keys), el))
        end
        return elements
    end
    return el
end

function jsrender(session::Session, el::EditableList)
    ui = map(DOM.div, session, el.list)
    return jsrender(session, ui)
end
