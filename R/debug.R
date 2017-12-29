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
