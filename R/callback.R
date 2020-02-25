sleep <- function() {
  stats::runif(2e7)
  NULL
}

callback1_r <- function(x) {
  sleep()
}

callback2_r <- function(x) {
  sleep()
  callback1_cpp(x)
  sleep()
}

callback3_r <- function(x) {
  sleep()
  callback2_cpp(x)
  sleep()
}

callback_r <- function() {
  sleep()
  callback3_cpp()
  sleep()
}
