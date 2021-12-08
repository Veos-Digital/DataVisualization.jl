using DataVisualization: logistic_scaler, binner

@testset "logistic scale test" begin
    isf = logistic_scaler([1.0])
    @test 15 |> isf |> inv(isf) ≈ 15
end

@testset "Binning" begin
    column = [3, 2, 56, 4, 32, 4, 7, 88, 4, 3, 4]
    bins = 0:20:100
    result = [1, 1, 3, 1, 2, 1, 1, 5, 1, 1, 1]
    @test binner(column, bins) ≈ result
end
