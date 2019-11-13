# load all scripts
include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")

g = create_network(10,3)
agent_list = create_agents(g)
update_network(g,agent_list)

g
