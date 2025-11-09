package handler

import (
	"github.com/clbanning/mxj/v2"
)

func XMLToJSON(data []byte) ([]byte, error) {
	// parse XML to map[string]interface{}
	mv, err := mxj.NewMapXml(data)
	if err != nil {
		return nil, err
	}

	// convert map to JSON
	jsonData, err := mv.Json()
	if err != nil {
		return nil, err
	}

	return jsonData, nil
}
