combine_profiles <- function(path, prof_path, out_path) {
  ds_rprof <- profile::read_rprof(out_path)
  write_flat_ds(ds_rprof, "rprof.csv")

  proto_path <- tempfile("gprofiler", fileext = ".pb.gz")
  system2(
    get_pprof_path(),
    c("-proto", "-output", shQuote(proto_path), shQuote(prof_path))
  )
  ds_pprof <- profile::read_pprof(proto_path)
  write_flat_ds(ds_pprof, "pprof.csv")

  stopifnot(sum(ds_pprof$samples$value) == sum(ds_rprof$samples$value))
  stopifnot(ds_rprof$samples$value == 1)

  ds_pprof <- shift_ids(ds_pprof, ds_rprof)
  ds_rprof <- expand_samples(ds_rprof)
  ds_pprof <- expand_samples(ds_pprof)

  ds_combined <- combine_ds(ds_rprof, ds_pprof)
  ds_merged <- patch_combined_ds(ds_combined)
  ds_pruned <- prune_ds(ds_merged)

  profile::write_rprof(ds_pruned, path)
}

write_flat_ds <- function(ds, path) {
  ds <- expand_samples(ds)

  . <- tibble::tibble(
    sample_id = rep(seq_along(ds$samples$locations), map_int(ds$samples$locations, nrow)),
    location_seq = unlist(map(map_int(ds$samples$locations, nrow), seq_len), use.names = FALSE),
    location_id = invoke(rbind, ds$samples$locations)$location_id
  )

  . <- merge(., ds$locations, by = "location_id", all.x = TRUE)
  . <- tibble::as_tibble(.)
  . <- merge(., ds$functions, by = "function_id", all.x = TRUE)
  . <- tibble::as_tibble(.)
  . <- .[order(.$sample_id, .$location_seq), ]

  readr::write_csv(., path)
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

  profile::validate_profile_v1(ds)
  ds
}

expand_samples <- function(ds) {
  new_samples <- tibble::tibble(
    value = 1L,
    locations = rep(ds$samples$locations, ds$samples$value)
  )

  ds$samples <- new_samples
  profile::validate_profile_v1(ds)
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
  profile::validate_profile_v1(ds_rprof)
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

  call_idx <- which(rprof_locations_full$name == ".Call")

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

  eval_idx <- which(pprof_locations_full$name == "Rf_eval")
  if (length(eval_idx) == 0) {
    eval_idx <- length(pprof_locations_full$name) + 1L
  } else {
    eval_idx <- eval_idx[[1L]] - 1L
  }

  if (pprof_locations_full$name[[eval_idx]] == "<?>") eval_idx <- eval_idx - 1L

  tibble::tibble(
    location_id = c(
      pprof_locations_full$location_id[seq2(1L, eval_idx - 1L)],
      rprof_locations_full$location_id[seq2(call_idx + 1L, nrow(rprof_locations_full))]
    )
  )
}

prune_ds <- function(ds) {
  # FIXME: prune unused locations and functions
  ds
}

function() {
  rprof <- read_rprof(out_path)
  pprof_dfs <- read_pprof(prof_path, get_n_traces(rprof))

  calls <- find_calls(rprof)
  if (length(calls) > 0) {
    pprof_df <- do.call(rbind, pprof_dfs[calls])
    new_files_idx_offset <- get_n_files(rprof)
    new_files <- unique(pprof_df$filename)
    new_files <- new_files[!is.na(new_files)]
    new_files <- grep("vendor", new_files, invert = TRUE, value = TRUE)

    rprof <- add_files(rprof, new_files)

    pprof_rprof_traces <- vapply(
      pprof_dfs[calls],
      pprof_df_to_rprof_trace,
      new_files,
      new_files_idx_offset,
      FUN.VALUE = character(1)
    )

    rprof <- substitute_call(rprof, calls, pprof_rprof_traces)
  }

  write_rprof(rprof, path)
}

pprof_df_to_rprof_trace <- function(pprof_df, files, file_idx_offset) {
  pprof_df$file_id <- match(pprof_df$filename, files) + file_idx_offset
  pprof_df <- pprof_df[!is.na(pprof_df$label), ]
  eval_pos <- which(pprof_df$label == "Rf_eval")
  stopifnot(length(eval_pos) > 0)
  pprof_df_native <- pprof_df[seq_len(eval_pos[[1]] - 1), ]
  if (nrow(pprof_df_native) == 0) return("")
  stopifnot(nrow(pprof_df_native) > 0)
  pprof_df_native$loc <- ifelse(
    is.na(pprof_df_native$line) | is.na(pprof_df_native$file_id),
    "",
    paste0(pprof_df_native$file_id, "#", pprof_df_native$line, " ")
  )
  paste0(
    '"', pprof_df_native$label, '" ', pprof_df_native$loc,
    collapse = ""
  )
}

read_pprof <- function(path, n_traces) {
  raw_traces <- system2(
    get_pprof_path(),
    c("-unit", "us", "-lines", "-traces", shQuote(path)),
    stdout = TRUE)

  combined_traces <- strsplit(paste(raw_traces, collapse = "\n"), "\n-+[+]-+\n?")[[1L]][-1L]
  periods <- as.numeric(sub("^ +([0-9]+).*$", "\\1", combined_traces))
  counts <- periods * n_traces / sum(periods)
  stopifnot(abs(counts - round(counts)) < 1e-6)
  counts <- round(counts)

  traces <- combined_traces[rep(seq_along(combined_traces), counts)]
  parse_pprof(traces)
}
