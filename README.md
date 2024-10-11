# Gossip Simulator

## Team Members
- Saranya Yadlapalli
- Sai Harshitha Baskar

## Project Overview
This project simulates network topologies and algorithms (gossip and push-sum) to study network convergence properties. Nodes in different topologies exchange messages to either propagate gossip or converge values using the push-sum algorithm.

## What is Working
This Pony-based Gossip Simulator successfully implements the following features:

1. Network Topologies:
   - Full Network : Every node is connected to every other node.
   - 3D Grid Network: Nodes are arranged in a 3D grid.
   - Line Network: Nodes are connected in a linear fashion.
   - Imperfect 3D Grid : Similar to the 3D grid but with additional random neighbors.

2. Algorithms:
   - Gossip : Each node spreads a gossip message to its neighbors until convergence
   - Push-Sum : Nodes exchange partial sums and weights until a stable value is reached across the network.

3. Functionality:
   - Dynamic network creation based on user input
   - Random initial node selection for starting the algorithm
   - Convergence detection and reporting
   - Timer-based progress checking
   - Convergence time measurement and reporting
   - Nodes can simulate different topologies: Full, 3D Grid, Line, and Imperfect 3D Grid.
   - Gossip algorithm works for all topologies.
   - Push-sum algorithm runs correctly and converges across various topologies.
   - The system reports the convergence time and the number of nodes that have converged.
	
    

4. Error Handling:
   - Input validation for correct number of arguments
   - Topology and algorithm validation

## Largest Network Managed
 # For Gossip Algorithm:
    -  Full Network: Successfully ran with up to 10000 nodes.
    -  3D Grid: Managed a network with up to 20000 nodes.
    -  Line Network: Handled 50000 nodes.
    -  Imperfect 3D Grid: Successfully ran with 20000 nodes.
 # For Push-Sum Algorithm:
    - Full Network: Successfully ran with up to 10000 nodes.
    - 3D Grid: Managed a network with up to 200000 nodes.
    - Line Network: Handled 50000 nodes.
    - Imperfect 3D Grid: Successfully ran with 20000 nodes.


## Running the Project
To run the project, use the following command:
dosp_project_2 <numNodes> <topology> <algorithm>
Where:
* numNodes is the number of nodes in the network.
* topology is one of the following: full, 3D, line, imp3D.
* algorithm is either gossip or push-sum.
Example:
project2 100 full gossip
This command will run a simulation with 100 nodes using the full network topology and the gossip algorithm.
Dependencies
* Pony Standard Library
* Random Number Generation
* Time and Timer utilities
* Promises for asynchronous processing
