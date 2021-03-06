% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_graph_from_series.R
\name{get_graph_from_series}
\alias{get_graph_from_series}
\title{Get a graph available in a series}
\usage{
get_graph_from_series(graph_series, graph_no)
}
\arguments{
\item{graph_series}{a graph series object of type
\code{dgr_graph_1D}.}

\item{graph_no}{the index of the graph in the graph
series.}
}
\description{
Using a graph series object of type
\code{dgr_graph_1D}, get a graph object.
}
\examples{
# Create three graphs
graph_1 <-
  create_graph() \%>\%
  add_n_nodes(3) \%>\%
  add_edges_w_string(
    "1->3 1->2 2->3")

graph_2 <-
  graph_1 \%>\%
  add_node() \%>\%
  add_edge(4, 3)

graph_3 <-
  graph_2 \%>\%
  add_node() \%>\%
  add_edge(5, 2)

# Create an empty graph series and add
# the graphs
series <-
  create_series() \%>\%
  add_to_series(graph_1, .) \%>\%
  add_to_series(graph_2, .) \%>\%
  add_to_series(graph_3, .)

# Get the second graph in the series
extracted_graph <-
  get_graph_from_series(
    graph_series = series,
    graph_no = 2)
}
