#!/usr/bin/env bash

# Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

# Print out arguments
terratest_help() {
  echo "Usage: terratest_docker_entrypoint.sh [OPTIONS]"
  echo "Options:"
  echo "  -p, --package=PACKAGE        The package to test. Default is './...'"
  echo "  -r, --run=TEST               The name of the test to run. Default is '.*Plan.*'"
  echo "  -v, --verbose                Run the tests in verbose mode"
  echo "  -h, --help                   Display this help message"
}

# Verify the /viya4-iac-gcp directory has been mounted by checking if
# the main.tf file exists
if [ ! -f "/viya4-iac-gcp/main.tf" ]; then
  echo "Error: The /viya4-iac-gcp directory has not been mounted"
  exit 1
fi
# Verify the /.viya4-tf-gcp-service-account.json file has been mounted
if [ ! -f "/.viya4-tf-gcp-service-account.json" ]; then
  echo "Error: The /.viya4-tf-gcp-service-account.json credentials file has not been mounted"
  exit 1
fi

# setup container user
echo "viya4-iac-gcp:*:$(id -u):$(id -g):,,,:/viya4-iac-gcp:/bin/bash" >> /etc/passwd
echo "viya4-iac-gcp:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

for i in "$@"; do
  case $i in
    -p=*|--package=*)
      PACKAGE="${i#*=}"
      shift # past argument=value
      ;;
    -r=*|--run=*)
      TEST="${i#*=}"
      shift # past argument=value
      ;;
    -v|--verbose)
      VERBOSE=-v
      shift # past argument with no value
      ;;
    -h|--help)
      terratest_help
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $i"
      terratest_help
      exit 1
      ;;
    *)
      ;;
  esac
done

# Set the defaults if the variables are not set
if [ -z "$PACKAGE" ]; then
  PACKAGE="./..."
fi
if [ -z "$TEST" ]; then
  TEST=".*Plan.*"
fi
if [ -z "$VERBOSE" ]; then
  VERBOSE=""
fi

# Run the tests
echo "Running 'go test $VERBOSE $PACKAGE -run $TEST -timeout 60m'"
exec go test $VERBOSE $PACKAGE -run $TEST -timeout 60m | tee ./testoutput/test_output.log

# Parse the results
cd testoutput
terratest_log_parser -testlog test_output.log -outputdir .
go run parse_results.go
