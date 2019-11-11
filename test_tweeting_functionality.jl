include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")

# --- test update functions --- # 

g = create_network(100, 3, 1)
a = create_agents(g)

update_perceiv_publ_opinion!(g, 4, a)
update_opinion!(a, 4)
update_inclin_interact!(a, 4)

push!(a[1].timeline, Tweet(0.5, 0))
push!(a[1].timeline, Tweet(0.3, 17))

publish_tweet!(a, g, 4)
update_timeline!(a, 1, 0.5)


# --- test simulation --- #

g = create_network(100, 3, 1)
a = create_agents(g)

h, b = simulate(g, a, 100);
