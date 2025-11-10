package handler

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// convert endpoint - accepts POST with XML data
func ConvertHandler(w http.ResponseWriter, r *http.Request) {
	var xmlData []byte
	var err error

	if r.Method == "POST" {
		// Read XML from POST request body
		xmlData, err = io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusBadRequest)
			return
		}
		defer r.Body.Close()

		if len(xmlData) == 0 {
			http.Error(w, "Empty request body", http.StatusBadRequest)
			return
		}
	} else {
		// For backwards compatibility, support GET with local file (for local testing only)
		xmlData, err = os.ReadFile("sample/test.xml")
		if err != nil {
			http.Error(w, "Failed to read sample.xml. Please use POST with XML data in body.", http.StatusBadRequest)
			return
		}
	}

	// Convert XML to JSON
	jsonData, err := XMLToJSON(xmlData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Parse error: %v", err), http.StatusInternalServerError)
		return
	}

	// Return result to client
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)

	// Upload to S3 asynchronously (non-blocking)
	go func() {
		if err := uploadToS3(jsonData); err != nil {
			log.Printf("Error uploading to S3: %v", err)
		}
	}()
}

// upload to S3
func uploadToS3(data []byte) error {
	ctx := context.TODO()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return fmt.Errorf("failed to load AWS config: %w", err)
	}
	client := s3.NewFromConfig(cfg)

	// Get bucket name from environment variable or use default
	bucket := os.Getenv("S3_BUCKET_NAME")
	if bucket == "" {
		bucket = "xml-json-output-bucket"
		log.Printf("Warning: S3_BUCKET_NAME not set, using default: %s", bucket)
	}

	key := fmt.Sprintf("results/result-%d.json", time.Now().UnixNano())

	_, err = client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
		Body:   bytes.NewReader(data),
	})

	if err != nil {
		return fmt.Errorf("failed to upload to S3: %w", err)
	}

	log.Printf("Successfully uploaded result to s3://%s/%s", bucket, key)
	return nil
}
