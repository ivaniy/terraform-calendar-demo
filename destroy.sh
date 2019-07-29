#!/bin/bash
terraform plan -destroy -out=DESTROYallTerraforms.tfplan -var "aws_access_key=$YOUR_ACCESS_KEY" -var "aws_secret_key=$YOUR_SECRET_KEY"
terraform apply DESTROYallTerraforms.tfplan
rm DESTROYallTerraforms.tfplan
