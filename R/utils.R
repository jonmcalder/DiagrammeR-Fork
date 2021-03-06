###
# Graph validation functions
###

# Function to check whether a graph object is valid
graph_object_valid <- function(graph) {

  # Check for all component names to be present
  if (!all(c("graph_info", "nodes_df", "edges_df",
             "global_attrs", "directed",
             "last_node", "last_edge",
             "node_selection", "edge_selection",
             "graph_log") %in%
           names(graph))) {
    return(FALSE)
  }

  # Check for specific graph classes
  if (any(
    inherits(graph$graph_info, "data.frame") == FALSE,
    inherits(graph$nodes_df, "data.frame") == FALSE,
    inherits(graph$edges_df, "data.frame") == FALSE,
    inherits(graph$global_attrs, "data.frame") == FALSE,
    inherits(graph$global_attrs$attr, "character") == FALSE,
    inherits(graph$global_attrs$value, "character") == FALSE,
    inherits(graph$global_attrs$attr_type, "character") == FALSE,
    inherits(graph$directed, "logical") == FALSE,
    inherits(graph$node_selection, "data.frame") == FALSE,
    inherits(graph$edge_selection, "data.frame") == FALSE,
    inherits(graph$graph_log, "data.frame") == FALSE)) {
    return(FALSE)
  }

  return(TRUE)
}

# Function to check whether a graph contains any nodes
graph_contains_nodes <- function(graph) {

  if (node_count(graph) == 0) {
    return(FALSE)
  }

  return(TRUE)
}

# Function to check whether a graph contains any edges
graph_contains_edges <- function(graph) {

  if (edge_count(graph) == 0) {
    return(FALSE)
  }

  return(TRUE)
}

# Function to check whether a graph contains a valid edge selection
graph_contains_edge_selection <- function(graph) {

  # Check if graph contains an edge selection
  if (nrow(graph$edge_selection) > 0) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

# Function to check whether a graph contains a valid node selection
graph_contains_node_selection <- function(graph) {

  # Check if graph contains a node selection
  if (nrow(graph$node_selection) > 0) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}


# Function to replace the `node_selection` df with
# different node ID values
#' @importFrom tibble tibble as_tibble
#' @importFrom dplyr bind_rows
replace_graph_node_selection <- function(graph, replacement) {

  # Get the graph's `node_selection` df
  node_selection <- graph$node_selection

  # Remove objects in `graph$node_selection`
  node_selection <-
    node_selection %>%
    tibble::as_tibble()

  node_selection <-
    node_selection[-seq(1, nrow(node_selection)), 1] %>%
    as.data.frame(stringsAsFactors = FALSE)

  # Add replacement to `graph$node_selection`
  node_selection <-
    node_selection %>%
    dplyr::bind_rows(
      tibble::tibble(
        node = as.integer(replacement)))

  return(node_selection)
}

# Function to replace the `edge_selection` df with
# different node ID values
#' @importFrom tibble tibble as_tibble
#' @importFrom dplyr bind_rows
replace_graph_edge_selection <- function(graph, edge_id, from_node, to_node) {

  # Get the graph's `edge_selection` df
  edge_selection <- graph$edge_selection

  # Remove objects in `graph$edge_selection`
  edge_selection <-
    edge_selection %>%
    tibble::as_tibble()

  edge_selection <-
    edge_selection[-seq(1, nrow(edge_selection)), 1] %>%
    as.data.frame(stringsAsFactors = FALSE)

  # Add replacement to `graph$edge_selection`
  edge_selection <-
    edge_selection %>%
    dplyr::bind_rows(
      tibble::tibble(
        edge = as.integer(edge_id),
        from = as.integer(from_node),
        to = as.integer(to_node)))

  return(edge_selection)
}

create_empty_nsdf <- function() {

  # Create empty `nsdf`
  nsdf <-
    tibble::tibble(
      node = as.integer(NA))[-1, ] %>%
    as.data.frame(stringsAsFactors = FALSE)

  return(nsdf)
}

create_empty_esdf <- function() {

  # Create empty `esdf`
  esdf <-
    tibble::tibble(
      edge = as.integer(NA),
      from = as.integer(NA),
      to = as.integer(NA))[-1, ] %>%
    as.data.frame(stringsAsFactors = FALSE)

  return(esdf)
}

# Function to determine whether a node or edge
# attribute has values that are all non-NA and
# are unique
#' @importFrom dplyr select_ distinct
#' @importFrom magrittr not
is_attr_unique_and_non_na <- function(graph,
                                      which_graph_df,
                                      attr) {

  if (which_graph_df == "ndf") {
    df <- graph$nodes_df
  } else if (which_graph_df == "edf") {
    df <- graph$edges_df
  } else {
    stop("The `which_graph_df` argument must be either `ndf` or `edf`.")
  }

  if (!(attr %in% colnames(df))) {
    stop("The `attr` provided is not available.")
  }

  # Are all values not NA?
  all_is_not_na <-
    df %>% dplyr::select_(attr) %>%
    is.na %>% magrittr::not() %>% all()

  # Are all values distinct?
  all_values_distinct <-
    df %>% dplyr::select_(attr) %>% dplyr::distinct() %>% nrow() ==
    nrow(df)

  if (all_is_not_na & all_values_distinct) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}


###
# Graph transformation functions
###


# Function to take a graph object and labels for `from`
# and `to` values, and, translate the `from`/`to` label
# values to node ID values
translate_to_node_id <- function(graph, from, to) {

  # Check that node labels are unique
  if (length(unique(graph$nodes_df$label)) !=
      node_count(graph)) {
    stop("You cannot use labels to form edges because they are not distinct")
  }

  # No node labels can be empty
  if (any(graph$nodes_df$label == "")) {
    stop("You cannot use labels to form edges if there are empty strings for labels")
  }

  # Create the `from_id` and `to_id` vectors
  from_id <- vector("integer")
  to_id <- vector("integer")

  # Get an ordered vector of node ID values
  # as `from` nodes
  for (i in 1:length(from)) {
    from_id <-
      c(from_id,
        graph$nodes_df[
          which(graph$nodes_df$label %in% from[i]), 1])
  }

  # Get an ordered vector of node ID values
  # as `to` nodes
  for (i in 1:length(to)) {
    to_id <-
      c(to_id,
        graph$nodes_df[
          which(graph$nodes_df$label %in% to[i]), 1])
  }

  # Reassign these nodes back to `from` and `to`
  from <- from_id
  to <- to_id

  id_from_to <- list(from = from_id, to = to_id)

  return(id_from_to)
}


###
# Graph logging functions
###

# Function to get the time of the graph function in
# the user's locale
graph_function_sys_time <- function() {
  return(Sys.time())
}

# Function to get the time difference from the start
# of the function (relies on a call of the
# `graph_function_sys_time()` function) to the time
# of invoking this function
graph_function_duration <- function(start_time) {
  end_time <- Sys.time()
  time_diff_s <- (end_time - start_time)[[1]]
  return(time_diff_s)
}

# Function to add log line for a graph `action`
#' @importFrom dplyr bind_rows
add_action_to_log <- function(graph_log,
                              version_id,
                              function_used,
                              time_modified,
                              duration,
                              nodes,
                              edges) {

  # Ensure that `time_modified` inherits from POSIXct
  if (inherits(time_modified, "POSIXct") == FALSE) {
    stop("The `time_modified` value must inherit from POSIXct.")
  }

  # Create a log line
  graph_log_line <-
    data.frame(
      version_id = as.integer(version_id),
      function_used = as.character(function_used),
      time_modified = time_modified,
      duration = as.numeric(duration),
      nodes = as.integer(nodes),
      edges = as.integer(edges),
      stringsAsFactors = FALSE)

  # Append the log line to `graph_log`
  graph_log <-
    dplyr::bind_rows(graph_log, graph_log_line)

  return(graph_log)
}

# Function to save the graph as an RDS file within
# a subdirectory in the working directory
save_graph_as_rds <- function(graph) {

  # Construct a file name for the RDS
  rds_filename <-
    paste0(
      graph$graph_info$graph_id, "_",
      formatC(
        graph$graph_log$version_id[nrow(graph$graph_log)],
        width = 6, format = "d", flag = "0"), "_",
      round(
        as.integer(
          graph$graph_log$time_modified[nrow(graph$graph_log)]), 4),
      ".rds")

  # Construct the subdirectory name for the RDS-based
  # graph backups
  rds_dir_name <-
    paste0("backup_", graph$graph_info$graph_id)

  # If directory doesn't exist, create the directory
  # inside of the working directory
  if (!dir.exists(rds_dir_name)) {
    dir.create(rds_dir_name)
  }

  # Save the graph as an RDS file in the subdirectory
  saveRDS(graph, file = paste0(rds_dir_name, "/", rds_filename))
}

