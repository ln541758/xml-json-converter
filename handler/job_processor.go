package handler

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// S3 clients and bucket names are initialized once.
var s3Client *s3.Client
var s3InputBucket = os.Getenv("S3_INPUT_BUCKET_NAME")
var s3OutputBucket = os.Getenv("S3_OUTPUT_BUCKET_NAME")

func init() {
	// Initialize S3 clients and check environment variables at startup.
	if s3InputBucket == "" || s3OutputBucket == "" {
		log.Fatal("FATAL: S3_INPUT_BUCKET_NAME and S3_OUTPUT_BUCKET_NAME environment variables must be set.")
	}

	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("FATAL: Failed to load AWS config in init: %v", err)
	}
	s3Client = s3.NewFromConfig(cfg)
}

// ProcessJob orchestrates the entire XML-to-JSON workflow.
// It downloads the XML file pointed to by s3Key, converts it, and uploads the result.
func ProcessJob(ctx context.Context, s3Key string) error {
	log.Printf("INFO: Starting job for S3 Key: %s", s3Key)

	// 1. Download XML Data from S3
	xmlData, err := downloadFromS3(ctx, s3InputBucket, s3Key)
	if err != nil {
		return fmt.Errorf("step 1 (S3 Download) failed for key %s: %w", s3Key, err)
	}

	// 2. Convert XML to JSON
	jsonData, err := XMLToJSON(xmlData)
	if err != nil {
		// This conversion error indicates a malformed XML structure.
		// Retrying is unlikely to help, but SQS retry mechanism handles this flow.
		return fmt.Errorf("step 2 (XML Conversion) failed for key %s: %w", s3Key, err)
	}

	// 3. Upload Resulting JSON to S3
	outputKey := fmt.Sprintf("json-output/%s-%d.json", s3Key, time.Now().UnixNano())
	if err := uploadToS3(ctx, jsonData, s3OutputBucket, outputKey); err != nil {
		return fmt.Errorf("step 3 (S3 Upload) failed for key %s: %w", s3Key, err)
	}

	return nil
}

// downloadFromS3 utility fetches an object from S3.
func downloadFromS3(ctx context.Context, bucket, key string) ([]byte, error) {
	resp, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	_, err = buf.ReadFrom(resp.Body)
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// uploadToS3 utility puts an object to S3.
func uploadToS3(ctx context.Context, data []byte, bucket, key string) error {
	_, err := s3Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
		Body:   bytes.NewReader(data),
	})

	if err != nil {
		return err
	}

	log.Printf("INFO: Successfully uploaded result to s3://%s/%s", bucket, key)
	return nil
}
