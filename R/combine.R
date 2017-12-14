combine_profiles <- function(path, prof_path, out_path) {
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
