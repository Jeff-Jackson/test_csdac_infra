# Terraspace Project

This is a Terraspace project. It contains code to provision Cloud infrastructure built with [Terraform](https://www.terraform.io/) and the [Terraspace Framework](https://terraspace.cloud/).

# Production regions and EKS names
+ prod - us-west-1
+ prodeu - eu-central-1
+ prodapj - ap-northeast-1

## Set ENV to deploy and AWS region
    TS_ENV=dev
    AWS_REGION=us-west-1

## Deploy

To deploy all the infrastructure stacks:

    TS_ENV=dev AWS_REGION=us-west-1 terraspace all up

To deploy individual stacks:

    TS_ENV=dev AWS_REGION=us-west-1 terraspace up eks # where eks is app/stacks/eks

## Destroy

To destroy all the infrastructure stacks:

    TS_ENV=dev AWS_REGION=us-west-1 terraspace all down

To destroy individual stacks:

    TS_ENV=dev AWS_REGION=us-west-1 terraspace down eks # where eks is app/stacks/eks

## Other commands

Auto approve:

    TS_ENV=dev AWS_REGION=us-west-1 terraspace all down/up --yes

Terraspace help output:

    Commands:
    terraspace all SUBCOMMAND          # all subcommands
    terraspace build [STACK]           # Build project.
    terraspace bundle                  # Bundle with Terrafile.
    terraspace check_setup             # Check setup.
    terraspace clean SUBCOMMAND        # clean subcommands
    terraspace completion *PARAMS      # Prints words for auto-completion.
    terraspace completion_script       # Generates a script that can be eval to setup auto-completion.
    terraspace console STACK           # Run console in built terraform project.
    terraspace down STACK              # Destroy infrastructure stack.
    terraspace fmt                     # Run terraform fmt
    terraspace force_unlock            # Calls terrform force-unlock
    terraspace help [COMMAND]          # Describe available commands or one specific command
    terraspace info STACK              # Get info about stack.
    terraspace init STACK              # Run init in built terraform project.
    terraspace list                    # List stacks and modules.
    terraspace logs [ACTION] [STACK]   # View and tail logs.
    terraspace new SUBCOMMAND          # new subcommands
    terraspace output STACK            # Run output.
    terraspace plan STACK              # Plan stack.
    terraspace providers STACK         # Show providers.
    terraspace refresh STACK           # Run refresh.
    terraspace seed STACK              # Build starer seed tfvars file.
    terraspace show STACK              # Run show.
    terraspace state SUBCOMMAND STACK  # Run state.
    terraspace summary                 # Summarize resources.
    terraspace test                    # Run test.
    terraspace tfc SUBCOMMAND          # tfc subcommands
    terraspace up STACK                # Deploy infrastructure stack.
    terraspace validate STACK          # Validate stack.
    terraspace version                 # Prints version.
    
    Options:
    [--verbose], [--no-verbose]
    [--noop], [--no-noop]


## Useful links and documentation
### Tfvars
https://terraspace.cloud/docs/config/tfvars/

### Tfvars: Layering
https://terraspace.cloud/docs/tfvars/layering/

### Dependencies: Tfvars and understanding of mock
https://terraspace.cloud/docs/dependencies/tfvars/

### Terrafile
To use more modules, add them to the https://terraspace.cloud/docs/terrafile/

### Terraspace official docs
https://terraspace.cloud/docs/

### Terraspace community forum
https://community.boltops.com/c/terraspace/6
