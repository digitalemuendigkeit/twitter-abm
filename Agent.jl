using Statistics
using LightGraphs
using StatsBase

mutable struct Agent
    opinion::AbstractFloat
    inclin_interact::AbstractFloat
    perceiv_publ_opinion::AbstractFloat
    check_regularity::AbstractFloat
    active::Bool
    inactive_ticks::Integer
    feed::AbstractArray
    liked_Tweets::AbstractArray
    retweeted_Tweets::AbstractArray
    function Agent(opinion, inclin_interact, check_regularity)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        # check if value for inclination to interact is valid
        if inclin_interact < 0
            error("invalid value for inclination to interact")
        end
        new(
            opinion, inclin_interact, opinion, check_regularity, true, 0, 
            Array{Tweet, 1}(undef, 0), Array{Tweet, 1}(undef, 0), Array{Tweet, 1}(undef, 0)
        )
    end
end

function update_perceiv_publ_opinion!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer)
    # get neighborhood opinion as baseline
    input = outneighbors(graph, agent)
    if length(input) != 0
        input_opinion_mean = mean([agent_list[input_agent].opinion for input_agent in input])
    else
        input_opinion_mean = agent_list[agent].opinion
    end
    # compute feed opinion
    feed_opinions = [tweet.opinion for tweet in agent_list[agent].feed]
    feed_weights = [tweet.weight for tweet in agent_list[agent].feed]
    if length(feed_opinions) > 0
        feed_opinion_mean = (
            sum([opinion * weight for (opinion, weight) in zip(feed_opinions, feed_weights)]) /
            sum(feed_weights)
        )
    else
        feed_opinion_mean = agent_list[agent].opinion
    end
    # perceived public opinion is the mean between the feed and neighborhood opinion
    agent_list[agent].perceiv_publ_opinion = mean([input_opinion_mean, feed_opinion_mean])
end

function update_opinion!(agent_list::AbstractArray, agent::Integer, opinion_thresh::AbstractFloat=0.3, base_weight::AbstractFloat=0.99)
    # weighted mean of own opinion and perceived public opinion
    if (abs(agent_list[agent].opinion - agent_list[agent].perceiv_publ_opinion) < opinion_thresh)
        agent_list[agent].opinion = (
            base_weight * agent_list[agent].opinion +
            (1 - base_weight) * agent_list[agent].perceiv_publ_opinion
        )
    # backfire effect?
    else
        agent_list[agent].opinion = (2 - base_weight) * agent_list[agent].opinion
        if agent_list[agent].opinion > 1
            agent_list[agent].opinion = 1
        elseif agent_list[agent].opinion < -1
            agent_list[agent].opinion = -1
        end
    end
end

function update_check_regularity!(agent_list::AbstractArray, agent::Integer, opinion_thresh::AbstractFloat=0.3, decrease_factor::AbstractFloat=0.9)
    if (abs(agent_list[agent].opinion - agent_list[agent].perceiv_publ_opinion) > opinion_thresh)
        agent_list[agent].check_regularity = decrease_factor * agent_list[agent].check_regularity
    else
        agent_list[agent].check_regularity = 1.0
    end
end

function update_inclin_interact!(agent_list::AbstractArray, agent::Integer, base_weight::AbstractFloat=0.9)
    # weighted mean of current inclination to interact and
    # absolute difference between own and perceived public opinion
    agent_list[agent].inclin_interact = (
        (1 - base_weight) * abs(agent_list[agent].opinion - agent_list[agent].perceiv_publ_opinion) +
        base_weight * agent_list[agent].inclin_interact
    )
end

function like(agent_list::AbstractArray, agent::Integer, opinion_thresh::AbstractFloat=0.2)
    inclin_interact = deepcopy(agent_list[agent].inclin_interact)
    i = 1
    while agent_list[agent].inclin_interact > rand()
        if i < length(agent_list[agent].feed)
            if (abs(agent_list[agent].feed[i].opinion - agent_list[agent].opinion) < opinion_thresh) && !(agent_list[agent].feed[i] in agent_list[agent].liked_Tweets)
                agent_list[agent].feed[i].like_count += 1
                agent_list[agent].feed[i].weight *= 1.01
                push!(agent_list[agent].liked_Tweets, agent_list[agent].feed[i])
            end
        else
            break
        end

        i += 1
        inclin_interact -= 1
    end
end

function drop_input!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, opinion_thresh::AbstractFloat=0.5)
    # look for current input tweets that have too different opinion compared to own
    # and remove them if source agent opinion is also too different
    for tweet in agent_list[agent].feed
        if abs(tweet.opinion - agent_list[agent].opinion) > opinion_thresh
            if abs(agent_list[tweet.source_agent].opinion - agent_list[agent].opinion) > opinion_thresh
                rem_edge!(graph, tweet.source_agent, agent)
            end
        end
    end
end

function add_input!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, new_input_count::Integer=4)
    # neighbors of neighbors
    input_candidates = Integer[]
    for neighbor in inneighbors(graph, agent)
        append!(input_candidates, setdiff(inneighbors(graph, neighbor), inneighbors(graph, agent)))
    end

    shuffle!(input_candidates)
    # Order neighbors by frequency of occurence in input_candidates descending
    input_queue = first.(sort(collect(countmap(input_candidates)), by=last, rev=true))
    # add edges
    if (length(input_queue) - new_input_count) < 0
        new_input_count = length(input_queue)
    end
    for _ in 1:new_input_count
        add_edge!(graph, popfirst!(input_queue), agent)
    end
end

function set_inactive!(graph::AbstractGraph, agent_list::AbstractArray, tweet_list::AbstractArray, agent::Integer)
    agent_list[agent].active = false
    agent_edges = [e for e in edges(graph) if (src(e) == agent || dst(e) == agent)]
    for e in agent_edges
        rem_edge!(graph, e)
    end
    empty!(agent_list[agent].feed)
    for t in tweet_list
        if t.source_agent == agent
            t.weight = -1
        end
    end
    return true
end

function retweet!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, opinion_thresh::AbstractFloat=0.1)
    for tweet in agent_list[agent].feed
        if (abs(agent_list[agent].opinion - tweet.opinion) <= opinion_thresh) && !(tweet in agent_list[agent].retweeted_Tweets)
            tweet.weight *= 1.01
            tweet.retweet_count += 1
            push!(agent_list[agent].retweeted_Tweets, tweet)
            for neighbor in outneighbors(graph, agent)
                push!(agent_list[neighbor].feed, tweet)
            end
            break
        end
    end
end

function publish_tweet!(graph::AbstractGraph, agent_list::AbstractArray, tweet_list::AbstractArray, tick_nr::Integer, agent::Integer)
    tweet_opinion = agent_list[agent].opinion + rand(-0.1:0.0000001:0.1)
    # upper opinion limit is 1
    if tweet_opinion > 1
        tweet_opinion = 1.0
    # lower opinion limit is -1
    elseif tweet_opinion < -1
        tweet_opinion = -1.0
    end
    tweet = Tweet(tweet_opinion, length(outneighbors(graph, agent)), agent, tick_nr)
    push!(tweet_list, tweet)
    # send tweet to each outneighbor
    for neighbor in outneighbors(graph, agent)
        push!(agent_list[neighbor].feed, tweet)
    end
end

function update_feed!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, decay_factor::AbstractFloat=0.5)
    unique!(agent_list[agent].feed)
    deletedTweets = Integer[]
    for (index,tweet) in enumerate(agent_list[agent].feed)
        if tweet.weight == -1 || !(tweet.source_agent in inneighbors(graph, agent))
            push!(deletedTweets,index)
        else
            tweet.weight = decay_factor * tweet.weight
        end
    end
    deleteat!(agent_list[agent].feed,deletedTweets)
    sort!(agent_list[agent].feed, lt=<, rev=true)
    if length(agent_list[agent].feed) > 10
        agent_list[agent].feed = agent_list[agent].feed[1:10]
    end
end

# suppress output of include()
;
