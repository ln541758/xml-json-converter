package handler

import (
	"github.com/clbanning/mxj/v2"
)

// XMLToJSON takes XML data as bytes and returns the converted JSON data as bytes.
func XMLToJSON(data []byte) ([]byte, error) {
	// Parse XML to map[string]interface{}
	mv, err := mxj.NewMapXml(data)
	if err != nil {
		return nil, err
	}

	// Convert map to JSON
	jsonData, err := mv.Json()
	if err != nil {
		return nil, err
	}

	return jsonData, nil
}
