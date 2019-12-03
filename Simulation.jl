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
    for agent in 1:length(agent_list)
        agent_list[agent] = Agent(generate_opinion(), generate_inclin_interact(), generate_check_regularity())
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
    graph::AbstractGraph, agent_list::AbstractArray, tweet_list::AbstractArray, 
    tick_nr::Int64, growth::Integer=4, max_inactive_ticks::Integer=2
)  
#= 
TODO: 
julia convention changed object first
always return changed object 
simplify interface -> use tuple simulation_state = (graph, agent_list)
squish / splat
=#
    for agent in shuffle(1:length(agent_list))
        this_agent = agent_list[agent]
        if this_agent.active && (rand() < this_agent.check_regularity) 
            update_feed!(graph, agent_list, agent)
            update_perceiv_publ_opinion!(graph, agent_list, agent)
            update_opinion!(agent_list, agent)
            like(agent_list, agent)
            retweet!(graph, agent_list, agent)
            drop_input!(graph, agent_list, agent)
            add_input!(graph, agent_list, agent)
            inclin_interact = deepcopy(this_agent.inclin_interact)
            while inclin_interact > 0
                if rand() < inclin_interact
                    publish_tweet!(graph, agent_list, agent, tweet_list, tick_nr)
                end
                inclin_interact -= 1.0
            end
            update_check_regularity!(agent_list, agent)
            this_agent.inactive_ticks = 0
        elseif this_agent.active
            this_agent.inactive_ticks += 1
            if this_agent.inactive_ticks > max_inactive_ticks
                set_inactive!(graph, agent_list, agent, tweet_list)
            end
        end
    end
    update_network!(graph, agent_list, growth)
    return log_network(graph, agent_list, tick_nr)
end

function log_network(graph::AbstractGraph, agent_list::AbstractArray, tick_nr::Int64)
    agent_opinion = [a.opinion for a in agent_list]
    agent_perceiv_publ_opinion = [a.perceiv_publ_opinion for a in agent_list]
    agent_inclin_interact = [a.inclin_interact for a in agent_list]
    agent_inactive_ticks = [a.inactive_ticks for a in agent_list]
    agent_active_status = [a.active for a in agent_list]
    agent_indegree = indegree(graph)
    return DataFrame(
        TickNr = tick_nr, AgentID = 1:length(agent_list),
        Opinion = agent_opinion, PerceivPublOpinion = agent_perceiv_publ_opinion,
        InclinInteract = agent_inclin_interact, InactiveTicks = agent_inactive_ticks,
        Indegree = agent_indegree, ActiveStatus = agent_active_status
    )
end

# the actual simulation
function simulate(graph::AbstractGraph, agent_list::AbstractArray, n_iter::Integer, growth::Integer=4)
    agent_list = deepcopy(agent_list)
    tweet_list = Array{Tweet, 1}(undef, 0)
    graph = deepcopy(graph)
    df = DataFrame(
        TickNr = Int64[], 
        AgentID = Int64[], 
        Opinion = Float64[], 
        PerceivPublOpinion = Float64[], 
        InclinInteract = Float64[], 
        InactiveTicks = Int64[], 
        Indegree = Float64[], 
        ActiveStatus = Bool[]
    )
    for i in 1:n_iter
        append!(df, tick!(graph, agent_list, tweet_list, i, growth))
        if i % ceil(n_iter / 10) == 0
            print(".")
        end
    end
    return df, agent_list, tweet_list, graph
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
            filter(df$TickNr == i, df$ActiveStatus) %>%
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
