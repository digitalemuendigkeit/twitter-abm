using Statistics
using LightGraphs

include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")


g = create_network(100, 3, 1)
a = create_agents(g)

drop_worst_input(g,1, a)
drop_worst_input(g,2,0.05)
add_input(g,2)
add_input(g,1,10)
