combine_profiles <- function(prof_path, out_path) {
  ds_rprof <- profile::read_rprof(out_path, version = "1.0")

  proto_path <- tempfile("jointprof", fileext = ".pb.gz")
  system2(
    get_pprof_path(),
    c("-proto", "-output", shQuote(proto_path), shQuote(prof_path))
  )
  ds_pprof <- profile::read_pprof(proto_path, version = "1.0")

  stopifnot(sum(ds_pprof$samples$value) == sum(ds_rprof$samples$value))
  stopifnot(ds_rprof$samples$value == 1)

  ds_pprof <- shift_ids(ds_pprof, ds_rprof)
  ds_rprof <- expand_samples(ds_rprof)
  ds_pprof <- expand_samples(ds_pprof)

  ds_combined <- combine_ds(ds_rprof, ds_pprof)
  ds_merged <- patch_combined_ds(ds_combined)
  ds_pruned <- prune_ds(ds_merged)
  ds_pruned
}

shift_ids <- function(ds, ds_base) {
  d_location_id <- max(ds_base$locations$location_id)
  d_function_id <- max(ds_base$functions$function_id)

  ds$samples$locations <- map(ds$samples$locations, function(x) {
    x$location_id <- x$location_id + d_location_id
    x
  })
  ds$locations$location_id <- ds$locations$location_id + d_location_id

  ds$locations$function_id <- ds$locations$function_id + d_function_id
  ds$functions$function_id <- ds$functions$function_id + d_function_id

  profile::validate_profile(ds)
  ds
}

expand_samples <- function(ds) {
  new_samples <- tibble::tibble(
    value = 1L,
    locations = rep(ds$samples$locations, ds$samples$value)
  )

  ds$samples <- new_samples
  profile::validate_profile(ds)
  ds
}

combine_ds <- function(ds_rprof, ds_pprof) {
  ds_rprof$samples$.pprof_locations <- ds_pprof$samples$locations
  ds_rprof$locations <- tibble::as_tibble(rbind(
    strip_dots(ds_rprof$locations), strip_dots(ds_pprof$locations)
  ))
  ds_rprof$functions <- tibble::as_tibble(rbind(
    strip_dots(ds_rprof$functions), strip_dots(ds_pprof$functions)
  ))
  profile::validate_profile(ds_rprof)
  ds_rprof
}

strip_dots <- function(x) {
  x[grep("^[.]", names(x))] <- NULL
  x
}

patch_combined_ds <- function(ds_combined) {
  ds_combined$samples$.rprof_locations <- ds_combined$samples$locations

  . <- merge(ds_combined$locations, ds_combined$functions, by = "function_id", all.x = TRUE)
  . <- tibble::as_tibble(.)
  locations_flat <- .

  ds_combined$samples$locations <- map2(
    ds_combined$samples$.rprof_locations,
    ds_combined$samples$.pprof_locations,
    patch_locations,
    list(locations_flat)
  )
  ds_combined
}

patch_locations <- function(rprof_locations, pprof_locations, locations_flat) {
  . <- rprof_locations
  . <- tibble::rowid_to_column(., "rprof_id")
  . <- merge(., locations_flat, by = "location_id", sort = FALSE)
  . <- .[order(.$rprof_id), ]
  . <- tibble::as_tibble(., rownames = NULL)
  rprof_locations_full <- .
  stopifnot(rprof_locations$location_id == rprof_locations_full$location_id)

  call_idx <- which(rprof_locations_full$system_name == ".Call")

  if (length(call_idx) == 0) {
    return(rprof_locations)
  }

  call_idx <- call_idx[[1]]

  . <- pprof_locations
  . <- tibble::rowid_to_column(., "pprof_id")
  . <- merge(., locations_flat, by = "location_id", sort = FALSE)
  . <- .[order(.$pprof_id), ]
  . <- tibble::as_tibble(., rownames = NULL)
  pprof_locations_full <- .
  stopifnot(pprof_locations$location_id == pprof_locations_full$location_id)

  eval_idx <- which(pprof_locations_full$system_name == "Rf_eval")
  if (length(eval_idx) == 0) {
    eval_idx <- length(pprof_locations_full$system_name)
  } else {
    eval_idx <- max(eval_idx[[1L]] - 1L, 1L)
    if (pprof_locations_full$system_name[[eval_idx]] == "<?>") eval_idx <- eval_idx - 1L
  }

  tibble::tibble(
    location_id = c(
      rprof_locations_full$location_id[seq2(1L, call_idx - 1L)],
      pprof_locations_full$location_id[seq2(1L, eval_idx)],
      rprof_locations_full$location_id[seq2(call_idx + 1L, nrow(rprof_locations_full))]
    )
  )
}

prune_ds <- function(ds) {
  # FIXME: prune unused locations and functions
  ds
}
