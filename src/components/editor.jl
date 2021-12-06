# adapted from https://github.com/SimonDanisch/JSServe.jl/blob/master/examples/editor.jl
struct Editor
    source::Observable{String}
    theme::Observable{String}
    language::Observable{String}
    style::Observable{Dict{String, Any}}
end

function jsrender(session::Session, editor::Editor)
    # FIXME: currently, it does not update when changing observables
    ui = DOM.div(editor.source[])
    onload(session, dom, js"""
        function (element){
            const langTools = $ace.require("ace/ext/language_tools");
            const editor = $ace.edit(element);
            editor.session.on("change", function () {
                const value = editor.getValue();
                JSServe.update_obs($(editor.source), value);
            })
            editor.session.setMode("ace/mode/" + $(editor.language[]));
            editor.setTheme("ace/theme/" + $(editor.language[]));
            editor.setOptions({
                autoScrollEditorIntoView: true,
                copyWithEmptySelection: true,
                enableLiveAutocompletion: true,
                fontSize: 18,
            });
            const staticWordCompleter = {
                getCompletions: function(editor, session, pos, prefix, callback) {
                    const wordList = [":", "color:", "foo", "bar", "baz"];
                    callback(null, wordList.map(function(word) {
                        const line = session.getLine(pos.row); 
                        console.log(line[pos.column-1]);
                        console.log(prefix);
                        return {
                            caption: word,
                            value: word,
                        };
                    }));

                }
            }

            editor.completers = [staticWordCompleter]
            editor.commands.byName.startAutocomplete.exec(editor)
            editor.renderer.setShowGutter(false);
            editor.setShowPrintMargin(false);

            const style = $(style[])
            for (let [key, value] of Object.entries(style)) {
                $(dom).style[key] = value;
            }
            editor.resize();
        }
    """)
    return jsrender(session, ui)
end
