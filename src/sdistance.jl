module Sdistance
include("./distance_function.jl")
include("./floodfill.jl")
include("./utils/utils.jl")
include("./environments.jl")

import .DistanceFunction: create_signed_distance_function_multiprocess, create_signed_distance_function, distanceToCurve, create_distance_function, create_distance_function_multiprocess
import .Floodfill: signining_field
import .Utils: is_jordan_curve, interpolation
import CSV, DataFrames, DelimitedFiles, Luxor, BenchmarkTools
using CSV, DataFrames, DelimitedFiles, Luxor, BenchmarkTools
if STAGE == "dev"
    import Plots, TimerOutputs
    using Plots, TimerOutputs
    const tmr = TimerOutput()
end

"""
    benchmark用method
    - floodfill使用時のmultiprocessとsingleprocessの比較
"""
function benchmark_floodfill(N::Int = 1000, _csv_datafile::String = "../test/mock_csv_data/interface.csv", multiprocess::Bool = true)
    exetimes = 3
    runtime = 0
    if multiprocess
        for i = 1:exetimes
            _phi, time = @timed signedDistance2D(_csv_datafile, N, "multi")
            runtime += time
        end
    else
        for i = 1:exetimes
            _phi, time = @timed signedDistance2D_singleprocess(_csv_datafile, N, "multi")
            runtime += time
        end
    end

    return (runtime / exetimes)
end


"""
benchmark用method
- single curveの時のisinsideメソッド使用時ののmultiprocessとsingleprocessの比較
"""
function benchmark_singlecurves_isinside(N::Int = 1000, _csv_datafile::String = "../test/mock_csv_data/interface.csv", multiprocess::Bool = true)
    exetimes = 3
    runtime = 0
    if multiprocess
        for i = 1:exetimes
            _phi, time = @timed signedDistance2D(_csv_datafile, N, "single")
            runtime += time
        end
    else
        for i = 1:exetimes
            _phi, time = @timed signedDistance2D_singleprocess(_csv_datafile, N, "single")
            runtime += time
        end
    end

    return (runtime / exetimes)
end



"""
    csv_datafile::Union{String, DataFrame}
    N::Int
    curves::Union{String, Nothing}
"""
function signedDistance2D(csv_datafile::Union{String,DataFrame}, N::Int = 100, curves::Union{String,Nothing} = nothing)
    #===  case: multiple circles ===#
    if curves == "multi"
        # create the computational domain
        _phi = zeros(Float64, N + 1, N + 1)
        # loading the csv file(the circle data)
        _gamma = Array{Any}(undef, 0, 2)
        _gamma = readdlm(csv_datafile, ',', Float64)
        if length(_gamma) < 200
            _gamma = interpolation(_gamma, Int(floor(log(length(_gamma) / 2, N^1.5))) + 2, true)
        elseif Int(floor(log(length(_gamma) / 2, N^1.5))) > 0
            _gamma = interpolation(_gamma, Int(floor(log(length(_gamma) / 2, N^1.5))), true)
        end

        _x = [i for i = -L:2*L/N:L] # len:N+1 
        _y = [i for i = -L:2*L/N:L] # len:N+1
        println("Data format: Multi curves\nThe CSV data size: ", size(_gamma))
        _phi = create_distance_function_multiprocess(_x, _y, _gamma)
        signining_field(_phi, N + 1, L)
        return _phi

        #=== case: simple circle ===#
    else
        # create the computational domain
        _phi = zeros(Float64, N + 1, N + 1)
        _gamma = readdlm(csv_datafile, ',', Float64)
        _x = [i for i = -L:2*L/N:L] # len:N+1 
        _y = [i for i = -L:2*L/N:L] # len:N+1

        is_jordan_curve(_gamma) # TODO: 丁寧なError messageを付与
        _gamma = interpolation(_gamma, Int(floor(log(length(_gamma) / 2, 2 * N))) + 1, false)
        println("Data format: The jordan curve\nThe CSV data size: ", size(_gamma))
        _phi = create_signed_distance_function_multiprocess(_x, _y, _gamma) # parallel processing
        return _phi
    end
end

function signedDistance2D_singleprocess(csv_datafile::Union{String,DataFrame}, N::Int = 100, curves::Union{String,Nothing} = nothing)
    #===  case: double circle ===#
    if curves == "multi"
        # create the computational domain
        _phi = zeros(Float64, N + 1, N + 1)
        _gamma = Array{Any}(undef, 0, 2)
        _gamma = readdlm(csv_datafile, ',', Float64)
        if length(_gamma) < 200
            _gamma = interpolation(_gamma, Int(floor(log(length(_gamma) / 2, N^1.5))) + 2, true)
        elseif Int(floor(log(length(_gamma) / 2, N^1.5))) > 0
            _gamma = interpolation(_gamma, Int(floor(log(length(_gamma) / 2, N^1.5))), true)
        end

        println("Data format: Multi curves\nThe CSV data size: ", size(_gamma))

        _x = [i for i = -L:2*L/N:L] # len:N+1 
        _y = [i for i = -L:2*L/N:L] # len:N+1
        _phi = create_distance_function(_x, _y, _gamma)
        signining_field(_phi, N + 1, L, false)
        return _phi

        #=== case: simple circle ===#
    else
        # create the computational domain
        _phi = zeros(Float64, N + 1, N + 1)
        _gamma = readdlm(csv_datafile, ',', Float64)
        _x = [i for i = -L:2*L/N:L] # len:N+1 
        _y = [i for i = -L:2*L/N:L] # len:N+1

        is_jordan_curve(_gamma) # TODO: 丁寧なError messageを付与
        _gamma = interpolation(_gamma, Int(floor(log(length(_gamma) / 2, 2 * N))) + 1, false)

        println("Data format: The jordan curve\nThe CSV data size: ", size(_gamma))
        _phi = create_signed_distance_function(_x, _y, _gamma) # single processing
        return _phi
    end
end
precompile(signedDistance2D, (Union{String,DataFrame}, Int, Union{String,Nothing}))

export signedDistance2D, benchmark_floodfill, benchmark_singlecurves_isinside
end
