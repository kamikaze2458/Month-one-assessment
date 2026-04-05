# TechCorp AWS Infrastructure — Month One Assessment

**Name:** Aleruchi Kingsley Omodu  
**Student ID:** ALT/SOE/025/4241  
**School:** AltSchool Africa  

---

## What This Project Does

This project provisions a complete AWS infrastructure using Terraform. It sets up a VPC with public and private subnets across two availability zones, a bastion host for secure access, two Apache web servers behind an Application Load Balancer, and a PostgreSQL database server. Everything is defined as code so it can be deployed and destroyed repeatably.

---

## Prerequisites

You need the following before you can deploy anything:

**Terraform** — https://developer.hashicorp.com/terraform/install  
Verify with:
terraform -v

**AWS CLI** — https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html  
Verify with:
aws --version

**An AWS account with an IAM user** that has AdministratorAccess. Do not use the root account. Generate an Access Key and Secret Key for the IAM user.

**Configure the AWS CLI** with your credentials:
aws configure

Set the region to `eu-central-1`.

**An EC2 Key Pair** in the eu-central-1 region. Create it with:
aws ec2 create-key-pair --key-name techcorp-key --region eu-central-1 --query 'KeyMaterial' --output text > ~/.ssh/techcorp-key.pem
chmod 600 ~/.ssh/techcorp-key.pem
```

> **Important:** Make sure the key pair is created in eu-central-1 specifically. Creating it in the wrong region will cause all EC2 instances to fail during deployment. I learned this the hard way.

**Your public IP address** — check https://whatismyip.com and note it down in CIDR format, e.g. `83.137.6.60/32`. This is used to restrict SSH access to the bastion host to your machine only.

> **Note:** If your IP address changes between sessions (which it can on home networks), you will lose SSH access to the bastion. If that happens, update `my_ip` in `terraform.tfvars` and run `terraform apply` again to fix it.

---

## Deployment Steps

### 1. Clone the repository
```bash
git clone https://github.com/kamikaze2458/Month-one-assessment.git
cd Month-one-assessment
```

### 2. Set up your variables file
```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and fill in your values:
```hcl
region            = "eu-central-1"
instance_type_web = "t2.micro"
instance_type_db  = "t2.micro"
key_pair_name     = "techcorp-key"
my_ip             = "83.137.6.60/32"
```

Never commit this file. It is already in `.gitignore`.

### 3. Initialize Terraform
terraform init

### 4. Preview what will be created
terraform plan

Read through the output before applying. It shows every resource that will be created.

### 5. Deploy
terraform apply

Type `yes` when prompted. This takes around 5 to 10 minutes. The NAT Gateways take the longest.

### 6. Check your outputs
terraform output

This prints the Bastion public IP, the ALB DNS name, and the VPC ID.

---

## Accessing the Infrastructure

### Bastion Host
ssh -i ~/.ssh/techcorp-key.pem ec2-user@18.192.148.176

### Web Servers (from inside the bastion)
First copy your key to the bastion from your local machine:
scp -i ~/.ssh/techcorp-key.pem ~/.ssh/techcorp-key.pem ec2-user@<bastion_public_ip>:~/.ssh/techcorp-key.pem

Then SSH from the bastion:
ssh -i ~/.ssh/techcorp-key.pem ec2-user@10.0.3.111

### Database Server (from inside the bastion)
ssh -i ~/.ssh/techcorp-key.pem ec2-user@10.0.3.44

### PostgreSQL (from inside the DB server)
sudo -u postgres psql

### Web Application
Open your browser and go to:
http://techcorp-alb-1580213901.eu-central-1.elb.amazonaws.com

You should see a page showing the TechCorp web server and the instance ID of whichever web server is currently handling your request. Refreshing may show a different instance ID as the ALB switches between the two servers.

## Cleanup Instructions

When you are done, destroy everything to avoid unnecessary AWS charges. NAT Gateways in particular cost money even when idle.

### Destroy all resources
terraform destroy

Type `yes` when prompted. Wait for it to complete fully before closing your terminal.

### Confirm everything is gone
terraform state list

Should return nothing.

### Delete the key pair if no longer needed
aws ec2 delete-key-pair --key-name techcorp-key --region eu-central-1
rm ~/.ssh/techcorp-key.pem

## Challenges I Ran Into

A few things caught me out during this project that are worth documenting:

**Empty configuration files** — The `main.tf` and `variables.tf` files were blank initially, which meant Terraform had nothing to build. Always verify your files have content before running `terraform apply`.

**Key pair in the wrong region** — The EC2 key pair has to exist in the same region as your instances. Creating it in a different region causes all instances to fail with an `InvalidKeyPair.NotFound` error. Always create the key pair using the CLI with the `--region` flag to be sure.

**vCPU limits on new accounts** — New AWS accounts have a default vCPU limit of 1, which is not enough to run four instances simultaneously. I had to switch to a different AWS account and request a limit increase through AWS Service Quotas.

**Account pending verification** — A brand new AWS account goes through a verification period before you can launch EC2 instances. The error says it usually resolves within minutes but can take up to 4 hours. Just wait and re-run `terraform apply` once it clears.

**SSH permission denied after recreating instances** — When instances are destroyed and recreated, the host key changes. You need to remove the old entry from `known_hosts` using `ssh-keygen -R <ip>` before connecting again. Also, if the key pair was recreated, the `.pem` file on disk may not match what AWS has registered, requiring a full key pair recreation.

**IP address changing between sessions** — My home network assigned a different public IP mid-way through the project, which locked me out of the bastion. The fix is straightforward: update `my_ip` in `terraform.tfvars` and run `terraform apply` to update the security group rule.

**Empty user data scripts** — The `web_server_setup.sh` and `db_server_setup.sh` files were empty, so Apache and PostgreSQL were never installed on first boot. User data only runs once when an instance starts, so the fix was to populate the scripts and use `terraform taint` to force the instances to be recreated.

**Git history bloated by .terraform folder** — The `.terraform` folder containing the AWS provider binary was accidentally committed, pushing the repo size to 168MB and causing repeated upload timeouts. The fix was to remove it from git tracking, add it to `.gitignore`, and reinitialize the git history from scratch.

---

## File Structure

```
Month-one-assessment/
├── main.tf                        # All AWS resource definitions
├── variables.tf                   # Variable declarations
├── outputs.tf                     # Output definitions
├── terraform.tfvars.example       # Example variable values (safe to commit)
├── terraform.tfvars               # Your actual values (do NOT commit)
├── user_data/
│   ├── web_server_setup.sh        # Installs and configures Apache
│   └── db_server_setup.sh         # Installs and configures PostgreSQL
├── evidence/                      # Screenshots of deployment
└── README.md                      # This file
```
