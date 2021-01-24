# instant-instance

Instant Remote Desktop Service based on AWS Spot Instances

# To initialize the backend

1. `terraform init` Downloads the initial modules and all
2. `terraform apply -auto-approve` Creates the backend.tf file with the config and the s3 bucket
3. `terraform init -force-copy` Copies the local state to s3

# To delete the backend

1. ```hcl
   module "terraform_state_backend" {
       ...
     terraform_backend_config_file_path = ""
     force_destroy                      = true
   }
   ```
2. `terraform apply -target module.terraform_state_backend -auto-approve` Deletes the backend.tf file and enables s3 deletion
3. `terraform init -force-copy` Copies the state back to local
4. `terraform destroy` Now finally the infra is destroyed

# Additional Project requirements

1. terraform - obviously
2. jq - should be installed and available for the local-execs
3. NVIDIA based local GPU for best performance
4. Custom Resolution Utility - CRU for forcing widescreen resolution

# Optional config
1. Optimize your gpu settings - AWS - `https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/optimize_gpu.html`
2. Use ec2config v2 for ephimeral
3. Install NVIDIA OpenGL for RDP
4. OverClock the GPU using the provided ps script
5. Optimize the RDP Session settings
