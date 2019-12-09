using LightGraphs
using DataFrames
using Statistics
using RCall
using Distributed
using Random

function generate_opinion()
    return 2 * rand() - 1
end

# this function was adapted from:
# https://www.johndcook.com/julia_rng.html
function generate_inclin_interact(lambda=log(25))
    if lambda <= 0.0
        error("mean must be positive")
    end
    -(1 / lambda) * log(rand())
end

function generate_check_regularity()
    return 1 - (rand() / 4)^2
end

function create_agents(graph::AbstractGraph)
    agent_list = Array{Agent, 1}(undef, length(vertices(graph)))
    for agent_idx in 1:length(agent_list)
        agent_list[agent_idx] = Agent(generate_opinion(), generate_inclin_interact(), generate_check_regularity())
    end
    return agent_list
end

function create_agents(agent_count::Integer)
    agent_list = Array{Agent, 1}(undef, agent_count)
    for agent in 1:length(agent_list)
        agent_list[agent] = Agent(generate_opinion(), generate_inclin_interact(), generate_check_regularity())
    end
    return agent_list
end

# simulation step
function tick!(
    state::Tuple{AbstractGraph, AbstractArray}, tweet_list::AbstractArray,
    tick_nr::Int64, config::Config
    )

    agent_list = state[2]
    for agent_idx in shuffle(1:length(agent_list))
        this_agent = agent_list[agent_idx]
        if this_agent.active && (rand() < this_agent.check_regularity)
            update_feed!(state, agent_idx, config)
            update_perceiv_publ_opinion!(state, agent_idx)
            update_opinion!(state, agent_idx, config)
            like(state, agent_idx, config)
            retweet!(state, agent_idx, config)
            drop_input!(state, agent_idx, config)
            add_input!(state, agent_idx, config)
            inclin_interact = deepcopy(this_agent.inclin_interact)
            while inclin_interact > 0
                if rand() < inclin_interact
                    publish_tweet!(state, tweet_list, agent_idx, tick_nr)
                end
                inclin_interact -= 1.0
            end
            update_check_regularity!(state, agent_idx, config)
            this_agent.inactive_ticks = 0
        elseif this_agent.active
            this_agent.inactive_ticks += 1
            if this_agent.inactive_ticks > config.simulation.max_inactive_ticks
                set_inactive!(state, agent_idx, tweet_list)
            end
        end
    end
    update_network!(state, config)
    return log_network(state, tick_nr)
end

function log_network(state::Tuple{AbstractGraph, AbstractArray}, tick_nr::Int64)
    graph, agent_list = state
    agent_opinion = [a.opinion for a in agent_list]
    agent_perceiv_publ_opinion = [a.perceiv_publ_opinion for a in agent_list]
    agent_inclin_interact = [a.inclin_interact for a in agent_list]
    agent_inactive_ticks = [a.inactive_ticks for a in agent_list]
    agent_active_state = [a.active for a in agent_list]
    agent_indegree = indegree(graph)
    return DataFrame(
        TickNr = tick_nr,
        AgentID = 1:length(agent_list),
        Opinion = agent_opinion,
        PerceivPublOpinion = agent_perceiv_publ_opinion,
        InclinInteract = agent_inclin_interact,
        InactiveTicks = agent_inactive_ticks,
        Indegree = agent_indegree,
        ActiveState = agent_active_state
    )
end

# the actual simulation
function simulate(config::Config = Config())
    graph = create_network(config.network.agent_count,config.network.m0)
    init_state = (graph, create_agents(graph))
    state = deepcopy(init_state)
    tweet_list = Array{Tweet, 1}(undef, 0)
    graph_list = Array{AbstractGraph, 1}([graph])
    df = DataFrame(
        TickNr = Int64[],
        AgentID = Int64[],
        Opinion = Float64[],
        PerceivPublOpinion = Float64[],
        InclinInteract = Float64[],
        InactiveTicks = Int64[],
        Indegree = Float64[],
        ActiveState = Bool[]
    )
    for i in 1:config.simulation.n_iter
        append!(df, tick!(state, tweet_list, i, config))
        if i % ceil(config.simulation.n_iter / 10) == 0
            print(".")
            push!(graph_list, deepcopy(state[1]))
        end
    end

    tweet_df = DataFrame(
                Opinion = [t.opinion for t in tweet_list],
                Weight = [t.weight for t in tweet_list],
                Source_Agent = [t.source_agent for t in tweet_list],
                Published_At = [t.published_at for t in tweet_list],
                Likes = [t.like_count for t in tweet_list],
                Retweets = [t.retweet_count for t in tweet_list]
                )

    return (df, tweet_df, graph_list), state, init_state
end

function visualize_opinionspread(df::DataFrame, agentcount::Integer, iterations::Integer)
    # Prepare for 3D Histogram
    viewpoint = [0.7800890207290649 -0.6242091059684753 -0.042710430920124054 1.9048346798919553;
                    0.32599347829818726 0.34723764657974243 0.8792917132377625 17.26966831053973;
                    -0.5340309143066406 -0.6998494267463684 0.47436413168907166 18.17097474580554;
                    0.0 0.0 0.0 1.0]

    @rput df viewpoint agentcount iterations

    # Build Array of Histograms
    R"""
    library(plot3Drgl)
    library(viridis)
    library(dplyr)

    seq(-1,1, by=0.1) %>%
        round(digits=1) %>%
        table() -> histarray


    for (i in 1:max(df$TickNr)){
        df %>%
            filter(df$TickNr == i, df$Activestate) %>%
            .[,3] %>%
            round(digits=1) %>%
            table() %>%
            bind_rows(histarray,.) -> histarray
    }

    histarray[is.na(histarray)] <- 0
    histarray %>%
        .[-1,] %>%
        as.matrix() -> histarraymatrix

    # Build the 3D Histogram
    persp3Drgl(
        x=1:nrow(histarraymatrix), y = seq(-1,1, by=0.1),
            contour=FALSE, z = histarraymatrix,
            box=FALSE, shade=0.1,
            xlab=\"\", ylab=\"\", zlab=\"\",
            col=viridis(n=2000, direction = -1), colkey=FALSE, axes=FALSE
        )


    # Formatting the Output
    view3d(userMatrix=viewpoint, zoom=0.6)
    par3d(windowRect = c(405, 104, 1795, 984))
    aspect3d(x=1.4,y=1.2,z=0.5)
    bbox3d(color=c(\"#EEEEEE\",\"#AAAAAA\"), xlen = 0, ylen = 0, zlen = 0)
    grid3d(side=\"x++\", col=\"white\", lwd=2)
    grid3d(side=\"y++\", col=\"white\", lwd=2)
    grid3d(side=\"z--\", col=\"white\", lwd=2)
    axis3d('x--', at = seq(0,floor(max(df$TickNr)/50)*50, by=50))
    axis3d('y--')
    axis3d('z-+', at = seq(0,floor(max(histarraymatrix)/50)*50, by=50))
    mtext3d(\"Simulation Step\", \"x--\", line=2)
    mtext3d(\"Opinion\", \"y--\", line=2)
    mtext3d(\"Agent Count\", \"z-+\", line=2)

    snapshot3d(paste0(\"output_\", agentcount,\"_\", iterations, \".png\"))
    """
end

# suppress output of include()
;
