import DirectedGraph
import Foundation

extension DirectedGraph {
    public func reachableGraph(from target: Node) -> DirectedGraph {
        let forwardsGraph = self
        let reversedGraph = self.reversed()
        
        func reachableNodes(target: Node, graph: DirectedGraph) -> Set<Node> {
            var visitedNodes = Set<Node>()
            func visit(currentNode: Node) {
                visitedNodes.insert(currentNode)
                let adjacentEdges = graph.edges.filter({ $0.sourceNode == currentNode })
                for adjacentEdge in adjacentEdges {
                    if visitedNodes.contains(adjacentEdge.destinationNode) {
                        continue
                    }
                    visit(currentNode: adjacentEdge.destinationNode)
                }
            }
            visit(currentNode: target)
            return visitedNodes
        }
        
        let fowardReachableNodes = reachableNodes(target: target, graph: forwardsGraph)
        let reversedReachableNodes = reachableNodes(target: target, graph: reversedGraph)
        let reachableNodes = fowardReachableNodes.union(reversedReachableNodes)
        
        let reachableClusters = self.clusters.filter({
            !Set($0.nodes).intersection(Set(reachableNodes)).isEmpty
        }).map({
            let commonNodes = Array(Set($0.nodes).intersection(Set(reachableNodes)))
            return Cluster(name: $0.name, label: $0.label, nodes: commonNodes)
        })
        
        let forwardReachableEdges = forwardsGraph.edges.filter({
            fowardReachableNodes.intersection([$0.sourceNode, $0.destinationNode]).count == 2
        })
        let reverseReachableEdges = reversedGraph.edges.filter({
            reversedReachableNodes.intersection([$0.sourceNode, $0.destinationNode]).count == 2
        })
        let finalReversedEdges = DirectedGraph(edges: reverseReachableEdges).reversed().edges
        let reachableEdges = Array(Set<Edge>(forwardReachableEdges + finalReversedEdges))
        
        return DirectedGraph(clusters: reachableClusters, nodes: nodes, edges: reachableEdges)
    }
}

public extension DirectedGraph {
    func reversed() -> DirectedGraph {
        var reversedEdges: [Edge] = []
        for edge in edges {
            reversedEdges.append(.from(edge.destinationNode, to: edge.sourceNode))
        }
        return DirectedGraph(clusters: clusters, nodes: nodes, edges: reversedEdges)
    }
}

extension DirectedGraph.Edge: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sourceNode.name + destinationNode.name)
    }
}

extension DirectedGraph.Node: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
