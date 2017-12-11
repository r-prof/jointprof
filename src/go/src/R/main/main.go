package main

import "C"

import (
	"github.com/google/pprof/profile"
	"os"
	"fmt"
	//"github.com/google/pprof/driver"
)

//export cgo_DoubleIt
func cgo_DoubleIt(x int) int {
	return x * 2;
}

//export cgo_run_pprof
func cgo_run_pprof(path string, target_path string) (err_string string) {
	//driver.PProf(&driver.Options{})
	//return "";

	in_file, err := os.Open(path)
	if err != nil {
		return fmt.Sprint(err)
	}
	defer in_file.Close()

	p, err := profile.Parse(in_file)
	if err != nil {
		return fmt.Sprint(err)
	}

	out_file, err := os.Create(target_path)
	if err != nil {
		return fmt.Sprint(err)
	}
	defer out_file.Close()

	p.Aggregate(true, true, true, true, false)

	p.WriteUncompressed(out_file)

	fmt.Printf("HasFileLines: %d\n", p.HasFileLines())
	//fmt.Printf("Profile: %s\n", p)
	//fmt.Printf("Mapping: %s", p.Mapping)
	fmt.Printf("Location: %s\n", p.Location[0].Mapping)
	fmt.Printf("")
	return ""
}

func main() {}
