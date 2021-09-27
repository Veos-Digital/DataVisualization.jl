using PalmerPenguins, DataFrames
ENV["DATADEPS_ALWAYS_ACCEPT"] = true
penguins = dropmissing(DataFrame(PalmerPenguins.load()))

using DataVisualization
set_aog_theme!()
update_theme!(fontsize=28)

(@isdefined server) && close(server)
server = DataVisualization.serve(penguins, url="0.0.0.0", port=9000)