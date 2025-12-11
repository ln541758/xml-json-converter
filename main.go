package main

import (
	"context"
	"log"
	"os"
	"time"

	"xml-json-converter/handler"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

// Environment variables for SQS configuration
var sqsQueueURL = os.Getenv("SQS_QUEUE_URL")

func main() {
	if sqsQueueURL == "" {
		log.Fatal("FATAL: SQS_QUEUE_URL environment variable is not set.")
	}

	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("FATAL: Failed to load AWS config: %v", err)
	}
	sqsClient := sqs.NewFromConfig(cfg)

	log.Printf("INFO: Starting SQS Worker. Polling from: %s", sqsQueueURL)

	// Continuous loop to poll for SQS messages
	for {
		// 1. Receive SQS Messages (using long polling for efficiency)
		result, err := sqsClient.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
			QueueUrl:            aws.String(sqsQueueURL),
			MaxNumberOfMessages: 10,         // Process up to 10 messages concurrently per poll
			WaitTimeSeconds:     20,         // Enable long polling
			VisibilityTimeout:   int32(300), // 5-minute visibility timeout for processing
		})

		if err != nil {
			log.Printf("ERROR: Error receiving message from SQS: %v. Retrying in 10s.", err)
			time.Sleep(10 * time.Second)
			continue
		}

		// 2. Process all received messages concurrently
		for _, message := range result.Messages {
			go processMessage(ctx, sqsClient, message)
		}
	}
}

// processMessage handles the execution flow for a single SQS message.
func processMessage(ctx context.Context, sqsClient *sqs.Client, message types.Message) {
	messageID := *message.MessageId
	log.Printf("INFO: Received message: %s", messageID)

	if message.Body == nil {
		log.Printf("WARN: Message %s has an empty body. Deleting.", messageID)
		deleteMessage(ctx, sqsClient, message)
		return
	}

	// The message body is expected to contain the S3 Key of the XML input file.
	s3Key := *message.Body

	// Delegate the core logic to the handler package.
	err := handler.ProcessJob(ctx, s3Key)

	if err != nil {
		// Log the failure but DO NOT delete the message.
		// The message will automatically become visible again after the VisibilityTimeout
		// expires, triggering a retry or eventually moving to the DLQ.
		log.Printf("FAILURE: Job processing FAILED for message %s (S3 Key: %s): %v. Will be retried.",
			messageID, s3Key, err)
		return
	}

	// 3. Delete the message upon successful completion.
	log.Printf("SUCCESS: Job processing complete for message %s (S3 Key: %s). Deleting message.",
		messageID, s3Key)
	deleteMessage(ctx, sqsClient, message)
}

// deleteMessage removes a message from the SQS queue.
func deleteMessage(ctx context.Context, sqsClient *sqs.Client, message types.Message) {
	_, err := sqsClient.DeleteMessage(ctx, &sqs.DeleteMessageInput{
		QueueUrl:      aws.String(sqsQueueURL),
		ReceiptHandle: message.ReceiptHandle,
	})

	if err != nil {
		log.Printf("CRITICAL: Failed to delete message %s: %v. Message may be processed again.", *message.MessageId, err)
	}
}
