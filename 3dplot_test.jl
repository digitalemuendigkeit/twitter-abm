using RCall
using Plots
using DelimitedFiles

# load all scripts
include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")


g = create_network(100, 10, 1)
a = create_agents(g)

result = simulate(g,a,200)

activityhist = Float64[]
for agent in result[2]
    append!(activityhist,agent.activity)
end

histogram(activityhist)
activityhist


# Create another visualization. Result Dataframe, Agent count and step count needed as params
# Last param defines visualization method: 1=Build histograms, 2=Build lineplots
visualize_Opinionspread(result[1],100,200,2)

# Export data for tests in RStudio
z = DataFrame(reshape(result.Opinions,100,div(length(result.Opinions),100))) # Hardcoded int is agent_count
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
