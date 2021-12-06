struct WildCard{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

# WildCard(table::Observable) = WildCard(table, Observable(""))

# function WildCard(table::Observable{T}) where T
#     source = Observable{String}("")
#     value = map(table, source) do table, source
#         private_module = Module()
#         @eval private_module begin
#             input = $table
#             output = $table
#             $(Meta.parse(source))
#         end
#         output::T = to_littledict(private_module.output)
#         return output
#     end
#     return WildCard(table, source)
# end

function jsrender(session::Session, wc::WildCard)
    editor = Editor(
        wc.source,
        Observable("julia"),
        Observable("cobalt"),
        Observable(Dict{String, Any}("width" => "100%", "height" => "500px"))
    )
    jsrender(session, editor)
end
