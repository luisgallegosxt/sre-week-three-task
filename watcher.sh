#!/bin/bash

# Variables
deployment_target="swype-app"
namespace="sre"
max_retries=3

# Function to scale down the deployment to zero replicas
scale_down() {
    kubectl scale deployment "$deployment_target" --replicas=0 -n "$namespace"
    echo "Deployment $deployment_target scaled down to 0 due to excessive restarts."
    exit 0
}

# Loop
while true; do
    # get retries count for all pods of the deployment
    restart_counts=$(kubectl get pods -n "$namespace" -l app="$deployment_target" -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}')

    # Calculate total retries
    total_restarts=0
    for count in $restart_counts; do
        total_restarts=$((total_restarts + count))
    done

    echo "Total restarts for $deployment_target: $total_restarts"

    # Compare total retries
    if [ "$total_restarts" -ge "$max_retries" ]; then
        # if limit has reached, replicas to zero and loop break
        scale_down
    else
        # if limit not reached, wait 60 seconds
        echo "Restart count under limit, checking again in 60 seconds."
        sleep 60
    fi
done
