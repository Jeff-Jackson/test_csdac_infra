# Troubleshoot
This is a space which contains a tool (`cdcsdac-cli.sh` script) and instructions for collection info from the cloud CSDAC.

To use `cdcsdac-cli.sh` script user need to:
- be authorized to AWS;
- have installed [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)

## CLI access using SSO([duo-sso tool](https://wwwin-github.cisco.com/ATS-operations/duo-sso))
### Basic configuration
Configure aws configuration:
```
duo-sso
```

Define an Environment type (`dev`, `staging`, `qa`, etc)
```
export ENV=dev
```

Set or update kube configuration:
```
aws eks update-kubeconfig --region us-west-1 --name csdac-$ENV-cluster
```

## Use `cdcsdac-cli` script for troubleshooting:
- `./cdcsdac-cli.sh help` - get help instructions.
- `./cdcsdac-cli.sh list-namespaces` - get list of namspaces with tenants names.
- `./cdcsdac-cli.sh ts-gen <namespace>` - generate troubleshoot for specified namespace.

## Use `cdcsdac-cli` script for monitoring and restreaming dynamic objects:
- `./cdcsdac-cli.sh get-objects-fmc -n <namespace> -p <pod>`                  - Get objects names from FMC for provided namespace and adapter pod.
- `./cdcsdac-cli.sh get-objects-adapter -n <namespace> -p <pod>`              - Get objects names from adapter for provided namespace and adapter pod.
- `./cdcsdac-cli.sh get-object-fmc <object_name> -n <namespace> -p <pod>`     - Get object mappings from FMC by provided object name for specified namespace and adapter pod.
- `./cdcsdac-cli.sh get-object-adapter <object_name> -n <namespace> -p <pod>` - Get object mappings from adapter by provided object name for specified namespace and adapter pod.
- `./cdcsdac-cli.sh get-object-diff <object_name> -n <namespace> -p <pod>`    - Get diff in object mappings between FMC and adapter by provided object name for specified namespace and adapter pod.
- `./cdcsdac-cli.sh get-diff-all -n <namespace> -p <pod>`                     - Get diff in all objects mappings between FMC and adapter for specified namespace and adapter pod.
- `./cdcsdac-cli.sh restream-object <object_name> -n <namespace> -p <pod>`    - Restream diff in object mappings by provided object name for specified namespace and adapter pod.
- `./cdcsdac-cli.sh restream-all-objects -n <namespace> -p <pod>`             - Restream diff in all objects mappings between FMC and adapter for specified namespace and adapter pod.
- `./cdcsdac-cli.sh restream-all-objects-for-tenants -t "<tnt1>[, <tnt2>...]"`- Restream diff in all objects mappings between FMC and adapter for all adapters pods in specified tenants.
- `./cdcsdac-cli.sh get-diff-paying-tenants`                                  - Get diff in all objects mappings between FMC and adapter for all adapters pods in paying tenants.
