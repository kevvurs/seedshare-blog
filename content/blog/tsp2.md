+++
title = "Test For Success"
date = 2020-07-29T20:22:00-07:00
description = ""
tags = [ "tsp", "algorithm", "optimization", "junit", "assertj" ]
categories = [ "programming", "optimization", "guide", "testing" ]
+++

Months ago, I wrote a [post on TSP](/blog/tsp1) with greedy approximation.
Events transpired in my career which prevented me from following-up on this
series sooner, but I am going to pick it back up now. In this episode of
optimization, we discuss __testing__ because it builds confidence in what you
ship. I also planned to cover visualizing the problem, but in an effort to keep
this short, I have decided to include that in a follow-up post.

![it is all a test](/tsp/undraw_solution_mindset.png)
_Solution mindset/undraw.co_

## unit testing
A unit test is a software routine that executes a selection of source code to
verify if it operates as expected. In this way, writing a unit test to cover your
application will effectively check that it works correctly. Unit tests usually
run automatically when you build or deploy an application, which is a good way
to certify that the features are not broken by recent changes. Importantly,
tests need to be maintained and updated to be useful and accurate. When
implemented thoughtfully, tests can build confidence that components work in
isolation. The scope of a unit test should focus-in on a single component or
pattern.

In the TSP codebase, I added a test for the `NNDroneRouter` component. The
conventional pattern for tests in Java projects is to create a Java class in
`src/test/java` with the same package as the component under test and named as
`${ComponentClass}Test`. This pattern is important, and some testing frameworks
will even rely on having this structure and naming.

```java
package io.seedshare.tsp.api.impl;

import static java.lang.Math.abs;
import static java.lang.Math.sqrt;
import static org.assertj.core.api.Assertions.assertThat;

import io.seedshare.tsp.model.ServiceDestination;
import java.util.LinkedList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

public class NNDroneRouterTest {

  private ServiceDestination dc;
  private List<ServiceDestination> destinations;
  private NNDroneRouter router;

  @BeforeEach
  public void setup() {
    dc = new ServiceDestination("warehouse1", 14, 14);
    destinations = new LinkedList<>();
    // each point is further from dc
    destinations.add(new ServiceDestination("A", 13, 12));
    destinations.add(new ServiceDestination("B", 8, 9));
    destinations.add(new ServiceDestination("C", 6, 7));
    destinations.add(new ServiceDestination("D", 5, 5));
    destinations.add(new ServiceDestination("E", 3, 5));
    destinations.add(new ServiceDestination("F", 1, 0));
    router = new NNDroneRouter(NNDroneRouterTest::euclideanDistance);
  }

  @Test
  public void test_route() {
    List<ServiceDestination> route = router.route(dc, destinations);
    assertThat(route)
        .isNotNull()
        .isNotEmpty()
        .hasSize(6)
        .extracting(ServiceDestination::getId)
        .containsExactly("A", "B", "C", "D", "E", "F");
  }

  private static Double euclideanDistance(ServiceDestination sd1, ServiceDestination sd2) {
    double xdif = abs(sd1.getX() - sd2.getX());
    double ydif = abs(sd1.getY() - sd2.getY());
    return sqrt(xdif * xdif + ydif * ydif);
  }
}
```

Despite having only one test method, this test demonstrates many parts. I used
the popular testing framework, [Junit 5][junit], and [AssertJ][assertj] for
assertions. I will add notes for how I added these in my Maven configuration
later. Junit 5 instruments unit tests in a very elegant way that provides
automation and organization of unit tests in Java. It also is incredibly
extensible for integrating with other frameworks in complex apps. AssertJ is a
fluent and easy-to-use library for writing assertions that verify that your
test execution passed successfully without writing a lot of verbose statements.

The `test_route` function runs when I test my code explicitly with the command
`mvn test` and automatically runs when I install my packaged JAR with
`mvn install`. This function will call the `route` method in our router
component and passes in objects to process. All of these fixtures are setup in
the `setup` method, which runs before each test execution with the help of
Junit's instrumentation. The setup will also instantiate the router component
with a method reference to provide the euclidean distance formula to calculate
the distance between the service destinations.

Now that the semantics are clear, what does this test mean? From the previous
post, we know that the nearest neighbor algorithm in our router will traverse to
whichever destination is the closest to its current location before returning to
the depot. In order to test this behavior, we assert that the route will contain
the destinations in the same order that they were inserted to the input list.
Why? As noted in the comment, the stops are inserted to the input list with
coordinates that gradually drift further away from the depot. A greedy traversal
should pick-up on this fact. You can verify this behavior by swapping the IDs of
the stops such that they are no longer sequential and running the test to see it
fail.

Another beneficial aspect of testing is finding small bugs in your
implementation without having to boot-up or deploy an artifact for manual
testing. When I initially ran this test, it actually failed for me with the
message copied below for reference. At first, I was perplexed by this, but when
I investigated it, I found a bug in the original code I shared in the previous
post and the initial commit. This bug is still there in the post; _see if you
can find it_.

```
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.seedshare.tsp.api.impl.NNDroneRouterTest
Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.09 s <<< FAILURE! - in io.seedshare.tsp.api.impl.NNDroneRouterTest
test_route  Time elapsed: 0.085 s  <<< FAILURE!
java.lang.AssertionError:

Expecting actual not to be empty
	at io.seedshare.tsp.api.impl.NNDroneRouterTest.test_route(NNDroneRouterTest.java:53)
```

As it turns out, my original version had a mistake in the loop condition, `while (neighbors.isEmpty())`, of the route method's implementation. The test then
failed since the program never entered this loop if the input was not empty. For
these reasons, testing your program is an essential and compelling way to
develop better programs.

## integration testing
In the industry, another common form of testing is __integration testing__. This
type of test will instantiate your application or a slice of your application
and establish a connection to an external resource, a subsystem or dependency,
or a test environment. For example, if your test connects to database
infrastructure or makes HTTP requests and verifies those results, then this is
a form of integration testing. The purpose of such tests is to observe and
confirm semi-realistic app interactions in isolation. I do not recommend
automating these unless your testing environment is robust enough to
provide consistent, verifiable results every time. In practice, I use Junit's
Tag API coupled with build profiles or plugins to orchestrate when these tests
should run. I usually run all unit test by default, yet only execute integration
tests on-demand or in the context of an automated [Jenkins pipeline][jenkins]
where the environment is predictable. Since our current codebase is a simple
library without such dependencies (yet), I will not present an integration test
in this post.

## dependencies
For those that are unfamiliar with Java projects or new to programming, I
thought it may be helpful to share the Maven dependencies I added for testing.
The example codebase I am building uses [Maven][mvn] for dependency management.
I have a __pom.xml__ in the [code repository][repo] that defines the
dependencies for this project. To enable testing, I added the following
dependencies and plugins.

```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-api</artifactId>
    <version>5.6.2</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-engine</artifactId>
    <version>5.6.2</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.11.1</version>
    <scope>test</scope>
</dependency>
```

```xml
<plugin>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>2.22.2</version>
</plugin>
<plugin>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>2.22.2</version>
</plugin>
```

## tdd
Some developers & thought-leaders have established an [esoteric process][tdd]
around unit testing. The basics are that you should write tests before
implementing a feature, program until your test passes, and then go back to
refactor your work. This might work for you, and if so, great. It has certainly
sold a lot of conference tickets, training courses, and driven traffic to
influencers. Others have become [cynical][dhh] towards the idea over time.
However, I encourage you to use your best judgment and develop in a way that
proves to be productive to your goals.

## next
In my next unscheduled post, I will be working on a visualization for our TSP
algorithm. My goal is to run our current code and observe its results in a
meaningful way. Then, in future articles, I plan to work towards improving our
optimization algorithm and driving benchmarks to compare their quality.

[repo]: https://github.com/kevvurs/combinatorics
[junit]: https://junit.org/junit5/
[assertj]: https://joel-costigliola.github.io/assertj/index.html
[jenkins]: https://www.jenkins.io/
[mvn]: https://maven.apache.org/
[tdd]: https://www.agilealliance.org/glossary/tdd/
[dhh]: https://dhh.dk/2014/tdd-is-dead-long-live-testing.html
