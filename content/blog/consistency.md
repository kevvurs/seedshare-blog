+++
title = "Data Operations in Supply Chain"
date = "2019-06-17"
description = "insights for a supply chain data pipeline"
tags = [ "software", "architecture", "nosql", "retail", "streaming" ]
categories = [ "architecture", "work", "retail", "data" ]

+++

![warehouse shelves](/consistency/warehouse-shelves.jpg)
_chuttersnap/unsplash_

## retail inventory lifecycle
In a retail supply chain, eventual consistency is unavoidable. Products follow a
lifecycle of inventory, often intersecting with a lifecycle in the Order Management
System (OMS). If I operate a shoe store, I may have items that are on the sales floor
and additional stock in the backroom. These states cover the same products but
at different points in the lifecycle. During a restock, backroom products will move
onto the sales floor.

When an item is sold, it is effectually leaving the inventory of the store, but
even that transaction has its own lifecycle. When a customer is trying on a pair
of shoes, they are learning about that product. They may carry the shoes through
the store, as they consider purchasing it, which like reserving it or adding it
to a cart online. The product naturally transitions between various states of inventory.
In a digital space, the same model is followed as a user browses
and interacts with the product page and the checkout flow.

## state management
An overwhelming amount of logistics IT depends on visibility into the states of
items. A decent system should understand not only where an item is and what lifecycle stage it
holds, but it should also log previous stages in the history of the
item. In this respect, I learned a lot from event sourcing. A simple
tool for understanding event sourcing is to imagine data as if it was managed with
[git version control][git]. If I recorded each time an item's lifecycle updated as a directed acyclic
graph (DAG), I could compute the state of that item at any given time by applying
those changes in-order.

The impetus for this is clear in the case of a lost order.
Storing all the information about an item that should have been shipped in a DAG, like a timeline, offers a powerful tool for resolving conflicts and mitigating
repeated issues. If the item was lost in transit, then a tracking number will help
me find it. That's because a tracking number is essentially backed by a DAG of
locations where the package was scanned, connected by the timestamps of each scan.

## eventual consistency
I won't try to explain all the calculus of eventual consistency. Simply think about
the edges between nodes in a DAG. Between the touch-points in the product's lifecycle,
its state in the inventory system does not change. The truth
is that there is a natural delay between the time a package's physical state or location
changes and the time at which digital systems become aware of changes. The reality
I see when looking into an inventory database is an echo of
what has happened. It constructs an estimation of where all my items are
and which states they inhabit.

Under pressure to design highly-available applications, I face challenges
in reconciling with eventually consistent data. When an inventory system is wrong,
it can ruin the user experience. Rapidly changing, near real-time data pipelines become
a burden, especially in staging data from an event sourced system into an efficient
read model. I need a design pattern for our systems to enhance the consistency without
compromising on availability.

## command query responsibility segregation
CQRS is a pattern for separating the read-behavior of an app from the write-behavior.
Super simple data services may have CRUD actions exposed in a REST API. I can
tell the application to create, update, and destroy persistent records. This is the
command layer or the write-path. Reading records is the query layer, which specifies
the rules for retrieving data. The CQRS parity for my CRUD app could involve deploying
a query service, for read-operations and a separate command service for pushing updates.
This pattern would offer advantages in scaling elastically. The query service could
scale up during peak browsing traffic while the command service scales during checkouts.

However, my position is that the most compelling use of CQRS in supply chain IT is
across the data pipeline. Consider the concept of a write-path where all incoming changes
are posted in a commit log. The system will maintain a fixed period of
the events for each product in the commit log. Following a common event sourcing fixture,
the pipeline would create projections from the event log. The projection is the result
of applying all the changes up to a point in time. A projection of the current state
represents the read model. To offer high availability, the system loads the
read model into a distributed, NoSQL database and leverages [complex events processing][cep]
architecture to re-hydrate the state in near real-time.

## the future of supply chain data
In a CQRS data pipeline, any new data is logged and stored as it enters the system.
This creates a resilient system of record that can be used to reconstruct the state
of inventory at any point in time. The read model stays available and is updated with
deterministic stream processing. You will never go to the write-path to query the state
of an item, and you will never abuse the read-path to push an update. Each domain
is distinct in its responsibilities. Another great feature would be adding elastic
scaling to the event processing so that the consistency becomes tunable and tolerant
to high load scenarios.

A retail supply chain is an expansive, imperfect, and often asymmetric system. Handling
the flux of data in order to provide useful selling experiences for members challenges
even the best software architecture and infrastructure at scale. Interacting with data
against a static model in a few dozen tables isn't good enough anymore. In order to
grow in our capabilities to forecast and represent the resources of a company, consider
capturing the changes of state in motion as a stream within the supply chain. With
the advent [Amazon Go][amzngo] or [Kroger's partnership with Microsoft AI][kroger], I have begun to see
a path towards using computer vision to get a high fidelity record of state across
the supply chain. Such efforts would be doomed without first designing a data pipeline
for consistency in motion and availability at rest.

[git]: https://git-scm.com/
[cep]: https://cloud.google.com/solutions/architecture/complex-event-processing
[amzngo]: https://www.amazon.com/b?ie=UTF8&node=16008589011
[kroger]: https://news.microsoft.com/2019/01/07/kroger-and-microsoft-partner-to-redefine-customer-experience-introduce-digital-solutions-for-retail-industry/
