struct Wildcard{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

# Wildcard(table::Observable) = Wildcard(table, Observable(""))

# function Wildcard(table::Observable{T}) where T
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
#     return Wildcard(table, source)
# end

function Wildcard(table::Observable)
    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=[""]), ""),
        method=RichEditor("Method", "julia", ""),
        outputs=RichTextField("Outputs", data_options(table, keywords=[""]), "")
    )
    card = ProcessingCard(:Project; wdgs...)
    return DimensionalityReduction(table, card)
end
