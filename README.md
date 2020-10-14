# Infrastructure

## Installing Terraform

    Follow the steps given in the following link:
    [Terraform Installation Link] (https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Install AWS CLI and Configure

    Follow the steps given in the following link:
    [AWS CLI Installation and Configuration Link] (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html)

* Check the list of AWS profiles added

    ```sh
    $ aws configure list-profiles
    ```
* Ensure `AWS_PROFILE` environment variable is set.

    ```sh
    $ export AWS_PROFILE={PROFILE_NAME}
    ```

## Terraform Script Commands

* The terraform init command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.

    ```sh
    $ terraform init
    ```
* The terraform apply command is used to apply the changes required to reach the desired state of the configuration

    ```sh
    $ terraform apply
    ```

* The terraform destroy command is used to destroy the Terraform-managed infrastructure.

    ```sh
    $ terraform destroy
    ```

## Instructions to Run:

1. Clone the repository
    ```sh
    $ git@github.com:gamitd-fall2020/infrastructure.git
    ```
2.  run `terraform apply` to input the resource values via command line. This is the script to create a stack to setup AWS network infrastructure.

3. run `terraform destroy` and input all the required paramters specific to that particular VPC. This is to terminate the entire network stack.

## Files Information

1.  "main.tf"     - This file has the entire network infrastructure that will setup all networking resources.
2.  "variable.tf" - All the initialized variables in main.tf must be defined with appropriate type and description in this particular file.
3. "terraform.tfvars" - We can pre-define the inputs in the .tfvars file if aren't passing them via command line. This file is optional.

## Network Setup Script:

    1. The main.tf has 1 VPC, 3 subnets, 1 route table, 1 internet gateway and 1 security group to setup the network.
    2. The commandline or .tfvars has following input parameters:
            a. AWS environment (dev/prod) (type-String)
            b. AWS region (us-east-1,us-east-2) (type-String)
            c. VPC Name (type-String)
    3. We can create multiple VPCs in different regions. If we try to create a VPC of same name in a same region, it's value will be written or updated.





