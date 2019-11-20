using RCall
using Plots

# load all scripts
include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")


# --- test agent creation ---#

Agent(0.1, 0.1)  # valid
Agent(0, 0)  # valid
Agent(2, 0)  # invalid
Agent(0, 2)  # invalid


# --- test tweet creation --- #

Tweet(0, 13)  # valid
Tweet(0.4, 13.5)  # invalid
Tweet(5, 2000)  # invalid
Tweet(0.5, -1)  # invalid
Tweet(-0.5, 14)  # valid


# --- test network creation --- #

create_network(10, 3, 3)  # valid
create_network(10, 3)  # valid
create_network(10, 11)  # invalid
create_network(10.1, 4)  # invalid
create_network(10, 3.1)  # invalid

# --- test network updating --- #

g = create_network(500, 15, 1)
a = create_agents(g)

inneighbors(g, 243)  # input before
add_input(g, a, 243, 4)
inneighbors(g, 243)  # input after (should be 4 more than input before)

inneighbors(g, 317)  # input before
add_input(g, a, 317, 1000)
inneighbors(g, 317)  # input after (should not throw out of bounds error)

# --- test agent set creation --- #

g = create_network(10, 3)
h = SimpleGraph()
k = SimpleDiGraph(15)
create_agents(g)  # valid
create_agents(h)  # valid
create_agents(k)  # valid


# --- test initialization functions --- #

# opinion generation
for _ in 1:1000
    op = generate_opinion()
    if op < -1 || op > 1
        error("function generate_opinion() is broken")
    end
end  # correct if no output

# generation of inclination to interact
generate_inclin_interact(0)  # invalid
generate_inclin_interact(-1)  # invalid
generate_inclin_interact(1)  # valid
generate_inclin_interact()  # valid



exp = [randexp() for _ in 1:1000]

maximum(exp)

using Plots

histogram(exp)

sum([e <= 1 ? 1 : 0 for e in exp]) / length(exp)

function generate_inclin_interact(lambda=log(25))
    if lambda <= 0.0
        error("mean must be positive")
    end
    random_exp = -(1 / lambda) * log(rand())
    return random_exp
end

histogram([generate_inclin_interact() for _ in 1:1000])


include("Simulation.jl")
g = create_network(100, 10, 1)
a = create_agents(g)

result = simulate(g,a,200)
# Prepare for 3D Histogram
z = reshape(result.Opinions,100,div(length(result.Opinions),100)) # Hardcoded int is agent_count
@rput z

R"""
library(viridis)
library(plot3D)
"""

# Test Histogram Plot in Julia
result[result[:,1].== 100, 2]
histogram(result[result[:,1].== 1, 2])

# Test Histogram Plot in R
R"test = hist(x = z[,200], breaks = seq(-1,1, by = 0.1))"

# Build Array of Histograms
R"""
histarray <- array(dim=c(200,20)) # First number is agent_count, second is number of bars
for (i in 1:nrow(testarray))
{
    temphist = hist(x = z[,i], breaks = seq(-1,1, by = 0.1))
    histarray[i,] = temphist$density/10*200
}
"""
# Build 3D Histogram
R"persp3D(x=1:nrow(histarray),y = seq(-1,0.9, by = 0.1), z = histarray,theta = -70, phi = 30, xlab=\"Simulation Steps\", ylab=\"Opinion Distribution\", zlab=\"Agent count\", ticktype = \"detailed\",  col=viridis(n=2000, direction = -1))"
