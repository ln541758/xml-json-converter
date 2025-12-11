package main

import (
	"fmt"
	"os"
)

func main() {
	f, err := os.Create("test.xml")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	// write XML header
	fmt.Fprintln(f, "<logs>")

	// simulate 500,000 logs
	for i := 0; i < 20; i++ {
		fmt.Fprintf(f, "  <log><id>%d</id><level>INFO</level><msg>Message %d</msg></log>\n", i, i)
	}

	fmt.Fprintln(f, "</logs>")
	fmt.Println("sample.xml generated successfully.")
}
