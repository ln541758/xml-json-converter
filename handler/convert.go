package handler

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// convert endpoint
func ConvertHandler(w http.ResponseWriter, r *http.Request) {
	// read XML from local file
	xmlData, err := os.ReadFile("sample/test.xml")
	if err != nil {
		http.Error(w, "Failed to read sample.xml", http.StatusInternalServerError)
		return
	}

	// convert XML to JSON
	jsonData, err := XMLToJSON(xmlData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Parse error: %v", err), http.StatusInternalServerError)
		return
	}

	// return result to client
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)

	// write to local file (for local debugging)
	filename := fmt.Sprintf("./output/result-%d.json", time.Now().Unix())
	os.MkdirAll("./output", 0755)
	os.WriteFile(filename, jsonData, 0644)

	// upload to S3 (for production)
	go uploadToS3(jsonData)
}

// upload to S3
func uploadToS3(data []byte) error {
	ctx := context.TODO()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}
	client := s3.NewFromConfig(cfg)

	bucket := "xml-json-output-bucket"
	key := fmt.Sprintf("result-%d.json", time.Now().Unix())

	_, err = client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
		Body:   bytes.NewReader(data),
	})
	return err
}
