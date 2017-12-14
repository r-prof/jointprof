read_rprof <- function(path) {
  lines <- readLines(path)

  header <- 1L
  files <- grep("^#File ", lines)
  traces <- setdiff(seq_along(lines), c(header, files))
  list(
    lines = lines,
    header = header,
    files = files,
    traces = traces
  )
}

get_header <- function(rprof) {
  rprof$lines[rprof$header]
}

get_files <- function(rprof) {
  rprof$lines[rprof$files]
}

get_n_files <- function(rprof) {
  length(rprof$files)
}

get_traces <- function(rprof) {
  rprof$lines[rprof$traces]
}

`get_traces<-` <- function(rprof, x) {
  rprof$lines[rprof$traces] <- x
  invisible(rprof$lines[rprof$traces])
}

get_n_traces <- function(rprof) {
  length(rprof$traces)
}

find_calls <- function(rprof) {
  grep('".Call" [0-9]+#[0-9]+ ', get_traces(rprof))
}

substitute_call <- function(rprof, calls, inject) {
  splits <- strsplit(get_traces(rprof)[calls], '".Call" [0-9]+#[0-9]+ ')

  pasted_splits <- Map(splits, inject, f = function(split, inject) {
    len <- length(split)
    stopifnot(len > 1)
    split[[len - 1]] <- paste0(split[[len - 1]], inject, split[[len]])
    length(split) <- len - 1
    split
  })

  traces_with_inject <- vapply(pasted_splits, paste, collapse = '".Call" ', FUN.VALUE = character(1))
  rprof$lines[rprof$traces][calls] <- traces_with_inject

  rprof
}

add_files <- function(rprof, file) {
  new_file_ids <- seq.int(get_n_files(rprof) + 1, length.out = length(file))
  new_file_lines <- paste0("#File ", new_file_ids, ": ", file)
  new_file_line_pos <- seq.int(length(rprof$lines) + 1, length.out = length(file))
  rprof$lines[new_file_line_pos] <- new_file_lines
  rprof$files <- c(rprof$files, new_file_line_pos)
  rprof
}

write_rprof <- function(rprof, path) {
  writeLines(
    c(
      get_header(rprof),
      get_files(rprof),
      get_traces(rprof)
    ),
    path
  )
}
