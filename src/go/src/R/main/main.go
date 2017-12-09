package main

import "C"

import (
	"github.com/google/pprof/driver"
)

//export cgo_DoubleIt
func cgo_DoubleIt(x int) int {
	return x * 2;
}

//export cgo_run_pprof
func cgo_run_pprof() {
	driver.PProf(&driver.Options{})
}

func main() {}
