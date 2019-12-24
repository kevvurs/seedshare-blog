+++
title = "Scaling Microservice Development"
date = "2019-11-20"
description = "organizaing against a dissonant codebase"
tags = [ "software", "architecture", "microservice", "performance", "code" ]
categories = [ "architecture", "work", "retail", "data" ]
draft = true

+++

In 2019, my team was challenged with re-platforming an inventory management system (IMS).
The previous system was the typical enterprise mash-up of legacy mainframe software
and Linux VM deployments for applications written in an object-oriented language.
Obviously, DB2 is also involved somewhere, or everywhere. Our challenge was to re-platform
the IMS with __microservices__ that would run in Kubernetes. Microservices is a loaded
word that could mean a variety of things, but the 12 Factors by Adam Wiggins is as close I can come
to a proper definition of the concept. In our architecture, the applications would be
developed in multiple code repositories, and each repository would have a CI/CD pipeline
to build docker containers. Finally, these containers are blasted out into Google Kubernetes
Engine using modern tools.

The container has become the fundamental unit of deployments in cloud-native software.
Everything must be containerized before shipping in the cloud. However, the IMS that used
to be 1 big "enterprise" application was rewritten as 8 services and a few shared packages.
Working with several code repositories, each having its own CI/CD plumbing, quickly becomes
an organizational challenge. Features might get implemented simultaneously by various members
of the team, leading to a cognitive dissonance within the service. A good rule to keep in
mind is __Conway's Law__ which posits that the structure of the organization will shape its
products. To improve our systems, we needed to synchronize our communication channels,
and delegate clear responsibilities. Once our team was effectively communicating and coordinating
the work, we began to make meaningful progress in delivering key features.

The microservice architecture still created a lot of source in our repositories.
This is helpful because we can balance and assign work to targeted components in the
portfolio without needing to apply changes to other parts of the IMS. But not everything
in software development is suitable for this pattern. Specifically, services commonly
contain _cross-cutting concerns_ such as database driver configurations, middleware boilerplate,
and even custom things like transaction handling, logging, and asynchronous behavior. Many of
these concerns arise in each service, and since we are developing many services in parallel,
redundant code quietly became an issue. It is difficult to argue against this anti-pattern
because at first it appears to play in favor of productivity. Developers copy some configurations
and utility classes into multiple services. However, these manual copies create a debt by slowing
down your ability to adapt them.

For example, suppose you had a implementation of deadline propagation
in a service with some AOP hooks and configuration. Then this source was copied and pasted
into several other services. Later during a performance test, your team sees the deadlines
don't work as expected when a legacy system has an unexpected time format. Your team could
choose to pickup the edge-case by altering the design to account for another format, or
you can hedge against the legacy design by instituting a broad default case. Either change
requires you to update the deadline module, but this means you will need to find and replace
the implementation in each service. Of course, this is only an example, but in many organizations
this flawed process is prevalent.

Instead of "borrowing" source through copying, sharing it with modules creates a flexible
codebase, capable of withstanding the ubiquity of microservices. We began to move cross-cutting
concerns into extensible, minimal packages, and then import them back into the service through
the build system and middleware. Reusable code became dependencies which were tested and scaled
independently. New features could be intelligently versioned into the build artifacts. Following
this practice, the microservice source transitions from many silos to a fabric, joining the
enabling technologies with business requirements.




IV. Deployments
 A. Portrayal
 B. Rewards
 C. Links to Scaffold

https://12factor.net/
https://www.docker.com/
