using RCall
using Plots
using DelimitedFiles

# load all scripts
include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")


g = create_network(200, 10, 1)
a = create_agents(g)

@time result = simulate(g,a,200)

length([agent for agent in result[2] if agent.active==true])

activityhist = Float64[]
for agent in result[2]
    append!(activityhist,agent.active)
end

using Plots
histogram(activityhist)
activityhist


# Create another visualization. Result Dataframe, Agent count and step count needed as params
# Last param defines visualization method: 1=Build histograms, 2=Build lineplots
visualize_opinionspread(result[1],100,200)

z = result[1]
@rput z
R"save(z,file=\"data.Rda\")"


# Save Viewpoint Position
R"um<-par3d()$userMatrix"
@rget um
# Write to CSV
writedlm("viewpoint.csv",um, ';')
# Restore Viewpoint Position from CSV
readdlm("viewpoint.csv",';')

# Test Histogram Plot in Julia
histogram(result[result[:,1].== 200, 2])

# Test Histogram Plot in R
R"test = hist(x = z[,200], breaks = seq(-1,1, by = 0.1))"
R"test$counts"

# Experimenting with the Window Position and Size
R"par3d(windowRect = c(10, 20, 1400, 900))"
println(R"par3d(\"windowRect\")")
