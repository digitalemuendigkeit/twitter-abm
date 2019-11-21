using RCall
using Plots
using DelimitedFiles

# load all scripts
include("Agent.jl")
include("Tweet.jl")
include("Network.jl")
include("Simulation.jl")


g = create_network(200, 10, 1)
a = create_agents(g)

result = simulate(g,a,200)

# Prepare for 3D Histogram
z = DataFrame(reshape(result.Opinions,200,div(length(result.Opinions),200))) # Hardcoded int is agent_count
viewpoint = [0.369116097688674 -0.929286122 0.013450718 0;
                0.33802402 0.147717804 0.929472387 0;
                -0.865732551 -0.338536531 0.368645668 0;
                0 0 0 1]

@rput z viewpoint

# Build Array of Histograms
R"""
library(plot3Drgl)
histarray <- array(dim=c(200,20)) # First number is Simulation steps, second is number of bars
for (i in 1:nrow(histarray))
{
    temphist = hist(x = z[,i], breaks = seq(-1,1, by = 0.1))
    histarray[i,] = temphist$counts
}

# Build the 3D Histogram
persp3Drgl(x=1:nrow(histarray),y = seq(-1,0.9, by = 0.1), contour=FALSE, z = histarray, box=FALSE, shade=0,theta = -80, phi = -30, xlab=\"\", ylab=\"\", zlab=\"Test\",  col=viridis(n=2000, direction = -1), colkey=FALSE)
# Formatting the RGL

view3d(userMatrix=um, zoom=0.7)
aspect3d(x=1.4,y=1.2,z=0.5)
bbox3d(color=c(\"#EEEEEE\",\"#AAAAAA\"))
grid3d(side=\"x++\", col=\"white\", lwd=2)
grid3d(side=\"y++\", col=\"white\", lwd=2)
grid3d(side=\"z--\", col=\"white\", lwd=2)
mtext3d(\"Agent Count\", \"z-+\", line=2.5)
mtext3d(\"Opinion\", \"y--\", line=2.4)
mtext3d(\"Simulation Step\", \"x++\", line=2.5)
"""

# Save to PNG
R"snapshot3d(\"output.png\")"


# Save Viewpoint Position
R"""
um<-par3d()$userMatrix
"""
@rget um
# Write to CSV
writedlm("viewpoint.csv",um, ';')
# Restore Viewpoint Position from CSV
readdlm("viewpoint.csv",';')

# Test Histogram Plot in Julia
result[result[:,1].== 100, 2]
histogram(result[result[:,1].== 200, 2])

# Test Histogram Plot in R
R"test = hist(x = z[,200], breaks = seq(-1,1, by = 0.1))"
R"test$counts"
