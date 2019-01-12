# Copied from https://github.com/jimhester/lintr.
# https://github.com/jimhester/lintr/blob/master/COPYING
# Copyright (c) James Hester 2014-2016.
# MIT license
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) <= 0) {
    y
  } else {
    x
  }
}
