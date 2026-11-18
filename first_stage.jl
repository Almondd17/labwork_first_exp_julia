
using Plots
using Statistics
using Printf

g = 9.81

#ruler uncertainty (m): half of 1 mm
delta_D = 0.0005
delta_hs = 0.0005

filename = "data1.csv"

#store heights and their corresponding distance measurements
hs = Float64[]
D_measurements = Vector{Vector{Float64}}()

# Read the CSV file
open(filename, "r") do file
    readline(file)
    for line in eachline(file)
        if isempty(strip(line))
            continue
        end
        #separate values using commas
        values = split(strip(line), ",")
        #each row should contain 11 values
        if length(values) != 11
            error("Invalid row: $line")
        end
        #convert height from mm to meters
        h = parse(Float64, strip(values[1])) / 1000

        #read the 10 distance measurements
        distances = Float64[]

        for j in 2:11

            #convert distances from cm to meters
            D = parse(Float64, strip(values[j])) / 100

            push!(distances, D)

        end

        # Store the height and its 10 measurements
        push!(hs, h)
        push!(D_measurements, distances)

    end
end


#data organizing

order = sortperm(hs)

hs = hs[order]#rearrange the heights array by size
D_measurements = D_measurements[order]#matches the distances for each height

#print organized measurements
# println("ORGANIZED MEASUREMENTS")

# for i in eachindex(hs)

#     println("\nHeight: $(hs[i]) m")
#     println("Distances (m): ", D_measurements[i])

# end




#Statistical Analysis
mean_D2 = Float64[]
stat_uncertainty = Float64[]
ruler_uncertainty = Float64[]
total_uncertainty = Float64[]

rounded_mean_D2 = Float64[]
rounded_uncertainty = Float64[]

for i in eachindex(hs)
    distances = D_measurements[i]

    D2 = distances .^ 2 #squared distances list in specific hs

    #average calculation for each D2
    N = length(D2)

    average = sum(D2) / N

   
    #deviation for all D2 (סטיית תקן לכל המרחקים בריבוע)
    # σ = sqrt(Σ(Dᵢ² - average)² / (N - 1))
    standard_deviation = std(D2)

    #statistical uncertainty for all D2
    #Δ average = σ / sqrt(N)
    stat_error = standard_deviation / sqrt(N)

    #ruler uncertainty for D squared
    # Δ(Dᵢ²) = |d(Dᵢ²)/dDᵢ| * ΔD
    #  = 2D * ΔD where D is the average distance and ΔD is the ruler uncertainty (0.5mm constant)
    ruler_error = 2 * mean(distances) * delta_D
    #calculate final uncertainty by combining the stat_error and ruler_error
    total_error = sqrt(stat_error^2 + ruler_error^2)

    #round uncertainty up to one significant digit
    place = 10.0 ^ floor(log10(total_error))
    rounded_error = ceil(total_error / place) * place

    #round the average to the same decimal place as the uncertainty
    decimal_places = -floor(Int, log10(rounded_error))
    rounded_average = round(average; digits=decimal_places)

    println("\nRounded results:")
    println("Average D² = ", rounded_average, " m²")
    println("Uncertainty = ", rounded_error, " m²")

    #store results

    push!(mean_D2, average)

    push!(stat_uncertainty, stat_error)
    push!(ruler_uncertainty, ruler_error)
    push!(total_uncertainty, total_error)

    push!(rounded_mean_D2, rounded_average)
    push!(rounded_uncertainty, rounded_error)

end

#lines parameters

a_upper = 0.27
b_upper = -0.001

a_middle = 0.25
b_middle = -0.0025

a_lower = 0.23
b_lower = -0.002



#graph creation
xline = range(minimum(hs), maximum(hs), length=200)


y_upper = a_upper .* xline .+ b_upper

y_middle = a_middle .* xline .+ b_middle

y_lower = a_lower .* xline .+ b_lower




y_min = minimum(mean_D2 .- total_uncertainty)
y_max = maximum(mean_D2 .+ total_uncertainty)

#add some space around the theoretical data

y_padding = 0.08 * (y_max - y_min)

x_min = minimum(hs) - 0.015
x_max = maximum(hs) + 0.015

y_min = y_min - y_padding
y_max = y_max + y_padding


println("Total uncertainties:")
println(total_uncertainty)
p = scatter(
    hs,
    mean_D2,

    #uncertainty in hs
    xerror = fill(delta_hs, length(hs)),

    #uncertainty in average D²
    yerror = total_uncertainty,

    xlabel = "hs (m)",
    ylabel = "D² (m²)",
    title = "D² as a function of hs",

    label = "Experimental measurements",
    legend = :topleft,

    #keep the graph scale fixed
    xlims = (x_min, x_max),
    ylims = (y_min, y_max),

    xticks = (hs, [@sprintf("%.3f", h) for h in hs]),
    xrotation = 45,
    xtickfont = font(8),
    capsize = 4
)

#upper line
plot!(
    p,
    xline,
    y_upper,
    label = "Upper line",
    linewidth = 2,
    linestyle = :dash
)

#middle line
plot!(
    p,
    xline,
    y_middle,
    label = "Middle line",
    linewidth = 2
)

#lower line
plot!(
    p,
    xline,
    y_lower,
    label = "Lower line",
    linewidth = 2,
    linestyle = :dash
)

#display the graph
display(p)

#save the graph
savefig(p, "experiment_part1.png")

#save calculated data to CSV
open("results_part1.csv", "w") do file

    println(file,
        "hs,mean_D2,stat_uncertainty,ruler_uncertainty,total_uncertainty,rounded_mean_D2,rounded_uncertainty"
    )

    for i in eachindex(hs)

        println(file,
            "$(hs[i]),$(mean_D2[i]),$(stat_uncertainty[i]),$(ruler_uncertainty[i]),$(total_uncertainty[i]),$(rounded_mean_D2[i]),$(rounded_uncertainty[i])"
        )

    end

end

println("\nGraph saved as experiment_part1.png")
println("Results saved as results_part1.csv")
