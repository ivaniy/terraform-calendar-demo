#!/bin/bash
terraform apply -var "aws_access_key=$YOUR_ACCESS_KEY" -var "aws_secret_key=$YOUR_SECRET_KEY" -auto-approve
