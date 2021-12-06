# adapted from https://github.com/SimonDanisch/JSServe.jl/blob/master/examples/editor.jl
struct Editor
    source::Observable{String}
    language::Observable{String}
    style::Observable{Dict{String, Any}}
end

function Editor(source::Observable, language′)
    language::Observable{String} = language′
    style = Observable(Dict{String, Any}("width" => "100%", "height" => "500px"))
    return Editor(source, language, style)
end

function jsrender(session::Session, editor::Editor)
    # FIXME: currently, it does not update when changing observables
    ui = DOM.div(editor.source[])

    # const staticWordCompleter = {
    #     getCompletions: function(editor, session, pos, prefix, callback) {
    #         const wordList = [":", "color:", "foo", "bar", "baz"];
    #         callback(null, wordList.map(function(word) {
    #             const line = session.getLine(pos.row); 
    #             console.log(line[pos.column-1]);
    #             console.log(prefix);
    #             return {
    #                 caption: word,
    #                 value: word,
    #             };
    #         }));

    #     }
    # }
    # editor.completers = [staticWordCompleter]
    # editor.commands.byName.startAutocomplete.exec(editor)

    # editor.session.setMode("ace/mode/" + $(editor.language[]));

    onload(session, ui, js"""
        function (element){
            const langTools = $ace.require("ace/ext/language_tools");
            const editor = $ace.edit(element);
            editor.session.on("change", function () {
                const value = editor.getValue();
                JSServe.update_obs($(editor.source), value);
            });
            editor.setOptions({
                autoScrollEditorIntoView: true,
                copyWithEmptySelection: true,
                enableLiveAutocompletion: true,
                fontSize: 18,
            });
            editor.renderer.setShowGutter(false);
            editor.setShowPrintMargin(false);

            const style = $(editor.style[])
            for (let [key, value] of Object.entries(style)) {
                $(ui).style[key] = value;
            }
            editor.resize();
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

function RichEditor(name, language, default)
    wdg = Editor(Observable(default), language)
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
