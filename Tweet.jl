mutable struct Tweet
    opinion::AbstractFloat
    weight::AbstractFloat
    source_agent::Integer
    published_at::Integer
    like_count::Integer
    comment_count::Integer
    retweet_count::Integer
    function Tweet(opinion, weight, source_agent, published_at)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        if weight < 0
            error("invalid weight value")
        end
        new(opinion, weight, source_agent, published_at, 0, 0, 0)
    end
end

Base.:<(x::Tweet, y::Tweet) = x.weight < y.weight

# suppress output of include()
;
