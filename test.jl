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