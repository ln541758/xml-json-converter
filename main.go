package main

import (
	"log"
	"net/http"
	"xml-json-converter/handler"
)

func main() {
	http.HandleFunc("/convert", handler.ConvertHandler)
	log.Println("Server running at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
