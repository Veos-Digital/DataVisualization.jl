# adapted from https://github.com/SimonDanisch/JSServe.jl/blob/master/examples/editor.jl
struct Editor
    value::Observable{String}
    language::Observable{String}
    options::Observable{Vector{String}}
    style::Observable{String}
end

function Editor(value::Observable, language′, options=Observable(String[]))
    language::Observable{String} = language′
    style = Observable("width: 100%; height: 16rem;")
    return Editor(value, language, options, style)
end

function jsrender(session::Session, editor::Editor)
    # FIXME: currently, not everything updates when changing observables
    ui = DOM.div(editor.value[]; editor.style)

    # TODO: make meta field customizable
    onload(session, ui, js"""
        function (element){
            const editor = $(ace).edit(element);
            const language = $(editor.language[])
            const langTools = $(ace).require("ace/ext/language_tools");
            const langMode = $(ace).require("ace/mode/" + language);

            editor.session.setMode("ace/mode/" + language);
            editor.session.on("change", function () {
                const value = editor.getValue();
                JSServe.update_obs($(editor.value), value);
            });
            editor.setOptions({
                enableLiveAutocompletion: true,
                enableBasicAutocompletion: true,
                enableSnippets: true,
                fontSize: 18,
            });
            editor.renderer.setShowGutter(false);
            editor.setShowPrintMargin(false);
            const staticWordCompleter = {
                getCompletions: function(editor, session, pos, prefix, callback) {
                    const wordList = JSServe.get_observable($(editor.options));
                    callback(null, wordList.map(function(word) {
                        const line = session.getLine(pos.row); 
                        return {
                            caption: word,
                            value: word,
                            meta: "column"
                        };
                    }));
                }
            };
            editor.completers.push(staticWordCompleter);
        }
    """)
    return jsrender(session, ui)
end

struct RichEditor
    name::String
    widget::Editor
    default::String
    confirmedvalue::Observable{String}
end

function RichEditor(name, language, default, options::Observable{Vector{String}}=Observable(String[]))
    wdg = Editor(Observable(default), language, options)
    return RichEditor(name, wdg, default, Observable(default))
end

function parse!(rtf::RichEditor)
    value = rtf.widget.value[]
    rtf.confirmedvalue[] = value
    return
end

function reset!(rtf::RichEditor)
    rtf.widget.value[] = rtf.default
    parse!(rtf)
end

function jsrender(session::Session, rtf::RichEditor)
    label = DOM.p(class="text-blue-800 text-xl font-semibold py-4 w-full text-left", rtf.name)
    ui = DOM.div(class="mb-4", label, rtf.widget)
    return jsrender(session, ui)
end
