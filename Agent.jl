using Statistics
using LightGraphs

# agent class
mutable struct Agent
    opinion::AbstractFloat
    inclin_interact::AbstractFloat
    perceiv_publ_opinion::AbstractFloat
    timeline::AbstractArray
    function Agent(opinion, inclin_interact)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        # check if value for inclination to interact is valid
        if inclin_interact < 0 || inclin_interact > 1
            error("invalid value for inclination to interact")
        end
        new(opinion, inclin_interact, opinion, Array{Tweet, 1}(undef, 0))
    end
end

# compute the perceived public opinion of an agent
function update_perceiv_publ_opinion(g::AbstractGraph, v::Integer, a::AbstractArray)
    # get neighborhood opinion as baseline
    following = outneighbors(g, v)
    if length(following) != 0
        following_opinion_mean = mean([a[f].opinion for f in following])  # weighted?
    else
        following_opinion_mean = a[v].opinion
    end
    # compute timeline opinion 
    timeline_opinions = [t.opinion for t in a[v].timeline]
    timeline_weights = [t.weight for t in a[v].timeline]
    if length(timeline_opinions) > 0 
        timeline_opinion_mean = (
            sum([a * b for (a, b) in zip(timeline_opinions, timeline_weights)]) / 
            sum(timeline_weights)
        )
    else
        timeline_opinion_mean = a[v].opinion
    end
    # perceived public opinion is the mean between the timeline and neighborhood opinion
    return mean([following_opinion_mean, timeline_opinion_mean])
end

function update_opinion()
    # 0.8 * own_opinion + 0.2 * perceiv_publ_opinion
end

function update_inclin_interact()
    # 0.1 * abs(own_opinion - perceiv_publ_opinion) + 0.9 * own_inclin_interact  
end

function like()
end

function drop_worst_input()
end

function add_input()
end

function publish_tweet()
end

# suppress output of include()
;



