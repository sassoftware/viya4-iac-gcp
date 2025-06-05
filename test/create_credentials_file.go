// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
)

type Config struct {
	Type                    string `json:"type"`
	ProjectID               string `json:"project_id"`
	PrivateKeyID            string `json:"private_key_id"`
	PrivateKey              string `json:"private_key"`
	ClientEmail             string `json:"client_email"`
	ClientID                string `json:"client_id"`
	AuthUri                 string `json:"auth_uri"`
	TokenUri                string `json:"token_uri"`
	AuthProviderx509CertUrl string `json:"auth_provider_x509_cert_url"`
	Clientx509CertUrl       string `json:"client_x509_cert_url"`
	UniverseDomain          string `json:"universe_domain"`
}

func CreateCredsFile() {
	// Read environment variables
	project_id := os.Getenv("GCP_PROJECT_ID")
	private_key_id := os.Getenv("GCP_PRIVATE_KEY_ID")
	client_email := os.Getenv("GCP_CLIENT_EMAIL")
	client_id := os.Getenv("GCP_CLIENT_ID")
	client_x509_cert_url := os.Getenv("GCP_CLIENT_CERT_URL")
	private_key := os.Getenv("GCP_PRIVATE_KEY")

	private_key = strings.ReplaceAll(private_key, "\\n", "\n")

	// Create a Config struct
	config := Config{
		Type:                    "service_account",
		ProjectID:               project_id,
		PrivateKeyID:            private_key_id,
		PrivateKey:              private_key,
		ClientEmail:             client_email,
		ClientID:                client_id,
		Clientx509CertUrl:       client_x509_cert_url,
		AuthUri:                 "https://accounts.google.com/o/oauth2/auth",
		TokenUri:                "https://oauth2.googleapis.com/token",
		AuthProviderx509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
		UniverseDomain:          "googleapis.com",
	}

	// Convert struct to JSON
	jsonData, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		log.Fatalf("Error converting struct to JSON: %v", err)
	}
	// Write JSON to file
	err = os.WriteFile(".viya4-tf-gcp-service-account.json", jsonData, 0644)
	if err != nil {
		log.Fatalf("Error writing JSON to file: %v", err)
	}
	fmt.Println("Environment variables have been written to config.json")
}

func main() {
	CreateCredsFile()
}
