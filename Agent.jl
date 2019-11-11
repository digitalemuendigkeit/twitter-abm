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

# Patrick
function drop_worst_input(g::AbstractGraph, v::Integer, opThreshold=0.5)

    println("OpThreshold is $opThreshold.")

    # Look for current input sources that have too different opinion compared to own
    # and remove them

    #println("Current agent is $v. Opinion is " * string(a[v].opinion))
    #println("Waiting inneighbors in list:" * string(inneighbors(g,v)))

    # Möglichkeit 1: Deepcopy der Inneighbors, nur eine Schleife erforderlich
    checkinput = deepcopy(inneighbors(g,v))
    while (length(checkinput) > 0)

        println("Opinion difference between $v and " * string(checkinput[1]) *" is " * string(a[v].opinion - a[checkinput[1]].opinion))
        if abs(a[v].opinion - a[checkinput[1]].opinion) > opThreshold
            rem_edge!(g, checkinput[1], v)
            println("Edge " * string(checkinput[1]) * " => $v removed")
        end

        popfirst!(checkinput)
    end

    # Möglichkeit 2: Neues Array anlegen und zwei Schleifen durchlaufen
    # newenemies = Integer[]
    # for input in inneighbors(g,v)
    #     if abs(a[v].opinion - a[input].opinion) > 0.1
    #         push!(newenemies,input)
    #     end
    # end
    #
    # # println("new enemies are $newenemies")
    #
    # for i in newenemies
    #     rem_edge!(g,i,v)
    # end


end

# Patrick
function add_input(g::AbstractGraph, v::Integer, newinputcount=4)

    if rand(1:10) > 2
        # In most cases, new friends are recommended out of friends of friends.
        # Opinion difference is not considered here.
        inputcandidates = Integer[]
        for neighbor in inneighbors(g,v)
            # Avoid duplicates in newcandidates through setdiff
            append!(inputcandidates,setdiff(inneighbors(g,neighbor),inputcandidates))
        end

    else
        # In rare cases, an agent adds new friends with very similar opinion.
        # Possible explanation: Add a "real-world" friend
        notneighbors = setdiff([1:v-1;v+1:nv(g)],inneighbors(g,v))

        inputcandidates = Integer[]
        for candidate in notneighbors
            if abs(a[v].opinion - a[candidate].opinion) < 0.2
                push!(inputcandidates,candidate)
            end
        end
    end

    # println("New inputcandidates are $inputcandidates.")

    # Choose IDs of new inputs randomly. Currently fixed to 4 new inputs per tick.
    # If there are not enough new fitting inputs, adapt the selection process.
    shuffle!(inputcandidates)
    # println("Shuffled Survivers are $inputcandidates")
    if length(inputcandidates) < 4
        newinputcount = length(inputcandidates)
    end

    # println("Chosen IDs are " * string(inputcandidates[1:newinputcount]))

    # Add incoming edges from new inputs
    for i in 1:newinputcount
        # println("Opinion difference is " * string(abs(a[inputcandidates[i]].opinion - a[v].opinion)))
        add_edge!(g,inputcandidates[i],v)
        # println("Edge" * string(inputcandidates[i]) * " => $v added.")
    end

end

function publish_tweet()
end

function update_timeline()
end

# suppress output of include()
;
