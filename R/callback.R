sleep <- function() {
  runif(5e7)
  NULL
}

#' @export
callback1_r <- function() {
  sleep()
}

#' @export
callback2_r <- function() {
  sleep()
  callback1_cpp()
  sleep()
}

#' @export
callback3_r <- function() {
  sleep()
  callback2_cpp()
  sleep()
}
