#!/bin/bash

# Function to make HTTP request
make_request() {
    curl -i -X GET 127.0.0.1/compute
}

# Infinite loop to keep sending requests
while true; do
    # Generate a random number between 5 and 10
    delay=$((RANDOM % 6 + 5))

    # Call the function asynchronously in the background
    make_request &

    # Sleep for the generated delay
    sleep $delay
done

