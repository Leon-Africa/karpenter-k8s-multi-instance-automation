# karpenter-k8s-multi-instance-automation

🚧 Work in Progress (WIP) 🚧

# Technical Specification

https://github.com/user-attachments/assets/800522b5-9aeb-427a-9667-3dbebad9209f

# Dependancies

- terraform
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installationhtml#installing-and-upgrading-ansible-with-pip) (install using pip)
- [helm](https://helm.sh/)
- [aws-cli](https://docs.aws.amazon.com/streams/latest/dev/setup-awscli.html)
- [boto3 and botocore](https://www.learnaws.org/2022/08/21/boto3-vs-botocore/): ````python3 -m pip install --user boto3 botocore````
- [make](https://www.gnu.org/software/make/)


# VPC Requirements
Your vpc needs to be setup according to https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html

create a ````terraform.tfvars```` filling the neccesary details following the structure in ````terrafrom.tfvars.example````


# Deployment

Ensure that you [aws configure](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-configure.html) with credentials that have the neccesary access policy. 

From the root of the project run:

1. To Provision infrastructure: ````make infra````
2. To configure the infrasture: ````make config````

If you want to do both 1. and 2. in one go simply run ````make all````

If you want to deprovision what was deployed simply run ````make clean````
