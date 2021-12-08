using DataVisualization: log_scaler, logistic_scaler
using DataVisualization: min_max_scaler, max_abs_scaler
using DataVisualization: binner, quantile_binner, uniform_binner

@testset "Scaler test" begin
    isf = logistic_scaler([1.0])
    @test 15 |> isf |> inv(isf) ≈ 15
    isf = log_scaler([1.0])
    @test 15 |> isf |> inv(isf) ≈ 15
    isf = min_max_scaler([1, 10])
    @test 15 |> isf |> inv(isf) ≈ 15
    isf = max_abs_scaler([1, 10])
    @test 15 |> isf |> inv(isf) ≈ 15
    
end

@testset "Binning test" begin
    column = [0, 11, 23, 34, 50, 75, 98]
    bins = 0:20:100
    result = [1, 1, 2, 2, 3, 4, 5]
    @test binner(column, bins) ≈ result
    result = [1, 1, 2, 2, 3, 4, 6]
    @test uniform_binner(column, 6) ≈ result
    result = [1, 1, 2, 3, 4, 5, 6]
    @test quantile_binner(column, 6) ≈ result
end
