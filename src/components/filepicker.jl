struct FilePicker{T}
    files::Observable{T}
end

function jsrender(session::Session, fp::FilePicker)
    text = Observable{String}("no files selected")
    input = DOM.input(
        type="file",
        onchange=js"""
            $(UtilitiesJS).readFiles(this.files, $(fp.files));
            const text = [...this.files].map(file => file.name).join(' ');
            text && JSServe.update_obs($(text), text);
        """,
        multiple=true,
        style="display:none;",
    )
    trigger = js"$(input).click()"
    btn = DOM.button(
        class="text-blue-800 text-xl font-semibold rounded mr-4 p-4 text-left w-full font-semibold hover:bg-gray-200 focus:outline-none",
        onclick=trigger,
        "Upload Files",
    )
    p = DOM.p(
        class="px-4 py-2 bg-white w-full text-gray-700 hover:text-gray-900 cursor-pointer hover:bg-gray-200 max-h-64 overflow-y-hidden",
        onclick=trigger,
        text
    )
    return jsrender(session, DOM.div(input, btn, p))
end

function to_vec(dict)
    list = valtype(dict)[]
    i = 0
    while (el = get(dict, string(i), nothing)) !== nothing
        push!(list, el)
        i += 1
    end
    return list
end

function readfiles(files::AbstractDict)
    datasets = [CSV.File(codeunits(file)) for file in to_vec(files)]
    return to_littledict(reduce(vcat, datasets))
end
