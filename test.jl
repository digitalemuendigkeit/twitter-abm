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

result = simulate(g,a,10)

sum([agent.active for agent in result[2]])/length(result[2])

result[3]
result

using Plots

result[3].N_edges
collect(1:size(result[3],1))

println(result[3].N_edges)


plot(collect(1:size(result[3],1)),result[3].N_edges)
plot(collect(1:size(result[3],1)),result[3].mean)
plot(collect(1:size(result[3],1)),result[3].sd)

[a.opinion for a in result[2]]
