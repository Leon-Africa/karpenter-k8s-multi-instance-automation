.PHONY: infra config all clean

# Provision the EKS cluster and IAM roles with Terraform
infra:
	@echo "Provisioning infrastructure with Terraform..."
	cd terraform && terraform init -upgrade && terraform apply -auto-approve

# Deploy cluster-level configuration (install Karpenter via Helm) with Ansible
config:
	@echo "Deploying cluster-level configuration with Ansible..."
	sleep 7
	# Using a static inventory override to run on localhost
	cd ansible && ansible-galaxy collection install -r requirements.yml
	cd ansible && ansible-playbook -i localhost, playbooks/autoscaler/install_karpenter.yml --flush-cache -vvv

# Optional combined target to run infrastructure then configuration
all: infra config
	@echo "Infrastructure and cluster configuration deployed."

# Clean up temporary files or local state (customize as needed)
clean:
	@echo "Cleaning up..."
	cd terraform && terraform destroy --auto-approve
