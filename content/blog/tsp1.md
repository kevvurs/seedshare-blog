+++
title = "Intro to Combinatorial Optimization"
date = 2020-05-13T11:31:50-07:00
description = ""
tags = [ "tsp", "algorithm", "optimization" ]
categories = [ "programming", "optimization", "guide" ]
+++

> Worldwide e-commerce retailer, Congo.com, has begun trials of its UAV delivery
service, which uses drones to ship smaller products to customers in the area
surrounding a distribution center. As an engineer at Congo, your task is to
develop a drone routing program. Your program should accept the location of the
distribution center and a list of the customer locations as inputs and return a
list of customers in the order they should be visited.

This prompt, which I wrote, is a clear example of the [Traveling Salesman
Problem (TSP)][tsp]. In TSP, a salesman must visit a series of cities for business,
and wants to find the optimal route to visit all of the cities. Usually, this
means finding the shortest Hamiltonian cycle or path to visit each node in the
network. The purpose of this article is to begin exploring TSP by prototyping
an implementation to satisfy the prompt.

This article is also the first installment in a series that I plan to write,
which will cover optimization, testing, benchmarking, and finally VRP. This
won't be a deep dive into [Graph Theory][graph], but it should be helpful for developers
who are interested in getting started with optimization research and
performance. Source code snippets will be presented in Java and all of the
examples will be available on [GitHub][repo] for science or whatever.

![drones are cool](/tsp/drone.jpg)

TSP is an ancient art that has been studied for millennia. Actually, it may not
be as old as Stonehenge, but it is a classical computer science problem that has
inspired decades of research into the [NP-hard problem][karp]. In the Drone Router
example, each customer location is one of the cities and the drone is the
salesman. By the nature of the problem, the optimal route can be found by brute
force, i.e., comparing every possible combination of traversals. However, the
runtime for this solution is O(n!), which does not scale for moderately sized
inputs.

_We can sacrifice accuracy for performance._ An approximation algorithm will
search a subset of candidate solutions and determine which are feasible under
the given constraints and optimize to find the best solution with the subset. An approximation algorithm uses heuristics to navigate the problem space,
simplifying it to avoid the factorial runtime of a brute force approach. This
approach finds a solution that is optimal compared to many other solutions and operates faster than checking every combination.

## designing a solution
I will begin by writing the necessary components in order to frame the problem.
We need something to represent the locations of the drone visits and the distances
between them. The distance specification was not provided, so I will present an
oversimplified model. Let each location have a pair of Cartesian coordinates,
and the path the drone takes between locations will be estimated with the 2D
[Euclidean distance][eucl] between coordinates. This is a near estimate if the
coordinate grid is appropriately translated, but it will ignore altitude changes
in flight and while dropping off the package.

```java
package io.seedshare.tsp.model;

/** Represents the location of a customer that requires parcel service. */
public class ServiceDestination {
  private final String id;
  private final double x;
  private final double y;

  public ServiceDestination(String id, double x, double y) {
    this.id = id;
    this.x = x;
    this.y = y;
  }

  public String getId() {
    return id;
  }

  public double getX() {
    return x;
  }

  public double getY() {
    return y;
  }

  @Override
  public String toString() {
    return "ServiceDestination{" + "id=" + id + ", x=" + x + ", y=" + y + '}';
  }
}
```

The next feature of the problem is an API that defines the solution. This is a
simple interface to tell the user what the drone router does. It relates to the
information we're given in the prompt.

```java
package io.seedshare.tsp.api;

import io.seedshare.tsp.model.ServiceDestination;
import java.util.List;

/** Approximates the optimal path for servicing a set of customers by drone. */
public interface DroneRouter {

  /**
   * Find an optimal order to visit each service destination.
   *
   * @param distributionCenter
   * @param serviceDestinations locations to visit
   * @return ordered list of service destinations, first to last visited
   */
  List<ServiceDestination> route(
      ServiceDestination distributionCenter, List<ServiceDestination> serviceDestinations);
}
```

The API does not concern itself with distance, which I inferred to be Euclidean.
Instead, I will add an abstract class that implements the `DroneRouter` and adds
a feature for distance calculation. Since my definition of distance is imposed,
it makes sense to inject distance as a function. This design will allow routers
to be flexible. The algorithm for optimizing the service route is decoupled from
the implementation of the distance function. Sub-classes of
`AbstractDroneRouter` may be used with any type of distance function, e.g. arc
lengths, cache lookup, or calling an external geo-service.

```java
package io.seedshare.tsp.api;

import io.seedshare.tsp.model.ServiceDestination;
import java.util.List;

/** Super unnecessary. */
public abstract class AbstractDroneRouter implements DroneRouter {
  protected final TravelMetric distanceFn;

  protected AbstractDroneRouter(TravelMetric distanceFn) {
    this.distanceFn = distanceFn;
  }

  protected double distance(ServiceDestination sd1, ServiceDestination sd2) {
    return distanceFn.applyAsDouble(sd1, sd2);
  }

  @Override
  public abstract List<ServiceDestination> route(
      ServiceDestination distributionCenter, List<ServiceDestination> serviceDestinations);
}
```

The `TravelMetric` functional interface is an extension of `ToDoubleBiFunction`.

## solving (approx.)
Now that the framing components have been designed, I will approach writing the algorithm to implement the `DroneRouter`. The brute force solution would consist
of finding every permutation of the route and selecting the one with the
shortest overall length. This would yield a truly optimal solution although it has
runtime complexity of __O(n!)__.

For my router, I will implement a simple solution with a polynomial runtime.
First, the drone will start at the distribution center as directed. Next, I will
search for the closest destination to the distribution center. After visiting
that destination, I'll again find the closest destination to the new location of
the drone. That is, in each iteration, the drone advances to the next stop that
is near its previous location. This is the Nearest Neighbor algorithm. NN
offers a greedy approximation of the optimal solution by minimizing each edge of
the path sequentially. The sum of these parts is not guaranteed to be the best
route, but hopefully we can reduce the overall length by reducing each part.

```java
package io.seedshare.tsp.api.impl;

import io.seedshare.tsp.api.AbstractDroneRouter;
import io.seedshare.tsp.api.TravelMetric;
import io.seedshare.tsp.model.ServiceDestination;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

/** Routes the drone's path using a nearest neighbor greedy approximation. */
public class NNDroneRouter extends AbstractDroneRouter {

  public NNDroneRouter(TravelMetric distanceFn) {
    super(distanceFn);
  }

  @Override
  public List<ServiceDestination> route(
      ServiceDestination distributionCenter, List<ServiceDestination> serviceDestinations) {
    if (distributionCenter == null || serviceDestinations == null) {
      throw new IllegalArgumentException("route(): arguments cannot be null");
    }
    ServiceDestination origin = distributionCenter;
    List<ServiceDestination> serviceRoute = new LinkedList<>();
    List<ServiceDestination> neighbors = new ArrayList<>(serviceDestinations);
    while (neighbors.isEmpty()) {
      origin = pollNearestNeighbor(origin, neighbors);
      serviceRoute.add(origin);
    }
    return serviceRoute;
  }

  // finds, removes, and returns the destination in the neighors that is nearest to the origin
  private ServiceDestination pollNearestNeighbor(
      ServiceDestination origin, List<ServiceDestination> neighbors) {
    int nearestNeighbor = 0;
    double nearestDistance = -1d;
    for (int i = 0; i < neighbors.size(); i++) {
      ServiceDestination destination = neighbors.get(i);
      double d = distance(origin, destination);
      if (nearestDistance < 0d || nearestDistance > d) {
        nearestNeighbor = i;
        nearestDistance = d;
      }
    }
    return neighbors.remove(nearestNeighbor);
  }
}
```

The `NNDroneRouter` implements the Nearest Neighbor approximation to solve TSP.
Its runtime complexity is __O(n^2)__, which improves on the brute force
approach.

## next steps
Now that we have a candidate implementation, we must ask, "Does it even work?"
In the next post, I will discuss testing my example and visualizing the problem.
Then, we'll examine another algorithm to solve TSP and perform benchmarks to
determine the characteristics of each approximation algorithm.

[tsp]: https://en.wikipedia.org/wiki/Travelling_salesman_problem
[graph]: https://ocw.mit.edu/courses/mathematics/18-315-combinatorial-theory-introduction-to-graph-theory-extremal-and-enumerative-combinatorics-spring-2005/
[repo]: https://github.com/kevvurs/combinatorics
[karp]: https://en.wikipedia.org/wiki/Karp%27s_21_NP-complete_problems
[eucl]: https://mathworld.wolfram.com/Distance.html
