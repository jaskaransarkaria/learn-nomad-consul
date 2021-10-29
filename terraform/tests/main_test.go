package main

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// This is an e2e test it will spin the entire infrastrucure up and run ansible over the instances
// it then fires a health check off for a load balanced server
func TestMain(t *testing.T) {

	t.Parallel()

	// we need to create a bucket and supply this as the back end so we don't overwrite any existing
	// infrastructure
	awsRegion := "eu-west-2"
	uniqueId := random.UniqueId()

	// Create an S3 bucket where we can store state
	bucketName := fmt.Sprintf("test-terraform-backend-example-%s", strings.ToLower(uniqueId))
	defer cleanupS3Bucket(t, awsRegion, bucketName)
	aws.CreateS3Bucket(t, awsRegion, bucketName)

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",
		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name": uniqueId[:4],
		},
		BackendConfig: map[string]interface{}{
			"bucket": bucketName,
			"key":    "terratest-terraform.tfstate",
			"region": awsRegion,
		},
		Reconfigure: true,
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the IP of the instance
	bastionIps := terraform.OutputList(t, terraformOptions, "bastion_ips")
	privateServerIps := terraform.OutputList(t, terraformOptions, "server_ips")
	privateClientIps := terraform.OutputList(t, terraformOptions, "client_ips")

	assert.Equal(t, 3, len(bastionIps))
	assert.Equal(t, 3, len(privateServerIps))
	assert.Equal(t, 2, len(privateClientIps))

	// It can take a minute or so for the Instance to boot up, so retry a few times
	maxRetries := 30
	timeBetweenRetries := 5 * time.Second

	runAnsibleFn := runAnsible(t)

	retry.DoWithRetry(t, "init the ec2 agents via ansible", maxRetries, timeBetweenRetries, runAnsibleFn)

	albURL := terraform.Output(t, terraformOptions, "alb_url")
	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// Verify that we get back a 200 OK with the expected response body -- this call checks one of the servers health
	http_helper.HttpGetWithRetry(t, "http://"+albURL+":4646/v1/agent/health", &tlsConfig, 200, "{\"server\":{\"message\":\"ok\",\"ok\":true}}", maxRetries, timeBetweenRetries)
}

func cleanupS3Bucket(t *testing.T, awsRegion string, bucketName string) {
	aws.EmptyS3Bucket(t, awsRegion, bucketName)
	aws.DeleteS3Bucket(t, awsRegion, bucketName)
}

func runAnsible(t *testing.T) func() (string, error) {
	return func() (string, error) {
		// need to wait until the instances are all running then I can run the next block
		err := shell.RunCommandE(t, shell.Command{
			Command:    "./init-agents.sh",
			WorkingDir: "../../ansible",
		})

		if err != nil {
			return "fail", err
		}

		return "succeeded", nil
	}
}
