sleep <- function() {
  stats::runif(2e7)
  NULL
}

callback1_r <- function() {
  sleep()
}

callback2_r <- function() {
  sleep()
  callback1_cpp()
  sleep()
}

callback3_r <- function() {
  sleep()
  callback2_cpp()
  sleep()
}
