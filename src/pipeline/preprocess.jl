struct InvertibleScalarFunction{S,T}
    f::S
    f⁻¹::T
end

function Base.:∘(isf1::InvertibleScalarFunction, isf2::InvertibleScalarFunction)
    f = isf1.f ∘ isf2.f
    f⁻¹ = isf2.f⁻¹ ∘ isf1.f⁻¹
    return InvertibleScalarFunction(f, f⁻¹)
end

(isf::InvertibleScalarFunction)(x) = isf.f(x)

function Base.inv(isf::InvertibleScalarFunction)
    f, f⁻¹ = isf.f, isf.f⁻¹
    return InvertibleScalarFunction(f⁻¹, f)
end

const RealVector = AbstractVector{<:Real}

is_constant(column::RealVector) = maximum(column) == minimum(column)

function binner(column::RealVector, bins::RealVector)
    rtol = 1.0e-5
    atol = 1.0e-8
    eps = @. atol + rtol * abs(column)
    return searchsortedfirst.(Ref(bins), column + eps) .- 1
end

function uniform_binner(column::RealVector, num_bins::Integer)
    if is_constant(column)
        return ones(Int46, length(column))
    end
    col_min = minimum(column)
    col_max = maximum(column)
    bins = range(col_min, stop = col_max, length = num_bins)
    return binner(column, bins)
end

function quantile_binner(column::RealVector, num_bins::Integer)
    bins = range(0, stop=1, length=num_bins)
    return binner(column, quantile(column, bins))    
end

function log_scaler(_::RealVector)
    return InvertibleScalarFunction(log, exp)
end

function logistic_scaler(_::RealVector)
    sigmoid(x::T) where {T<:Real} = one(T) / (one(T) + exp(-x))
    logit(x::T) where {T<:Real} = log(x / (one(T) - x))
    return InvertibleScalarFunction(sigmoid, logit)
end

function min_max_scaler(column::RealVector, range::RealVector = [0, 1])
    max_val = maximum(column)
    min_val = minimum(column)
    min_range, max_range = range[1], range[2]
    f(x) = (x - min_val) / (max_val - min_val) * (max_range - min_range) + min_range
    f⁻¹(y) = (y - min_range) * (max_val - min_val) / (max_range - min_range) + min_val
    return InvertibleScalarFunction(f, f⁻¹)
end

function max_abs_scaler(column::RealVector)
    max_val = maximum(maximum(column), abs(minimum(column)))
    f(x) = x / max_val
    f⁻¹(y) = y * ma_val
    return InvertibleScalarFunction(f, f⁻¹)
end

function standardizer(column::RealVector)
    m = mean(column)
    s = std(column)
    f(x) = (x - m) / s
    f⁻¹(y) = y * s + m
    return InvertibleScalarFunction(f, f⁻¹)
end

