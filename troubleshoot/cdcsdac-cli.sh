#!/bin/bash

# The script is a cli tool for troubleshooting and collecting info from cloud CSDAC.

# returns "help" instructions
help() {
    cat <<EOF
Monitor and troubleshoot cloud CSDAC services.
Usage:
  $(basename $0) [COMMAND]
Commands:
  help                                                      - Get this help.
  list-namespaces                                           - Get list of namespaces with corresponding tenants.
  ts-gen <namespace>                                        - Generate troubleshoot bundle for provided tenant by its namespace.
  list-pods <namespace>                                     - Get list of pods for provided namespace.
  get-objects-fmc -n <namespace> -p <pod>                   - Get objects names from FMC for provided namespace and adapter pod.
  get-objects-adapter -n <namespace> -p <pod>               - Get objects names from adapter for provided namespace and adapter pod.
  get-object-fmc <object_name> -n <namespace> -p <pod>      - Get object mappings from FMC by provided object name for specified namespace and adapter pod.
  get-object-adapter <object_name> -n <namespace> -p <pod>  - Get object mappings from adapter by provided object name for specified namespace and adapter pod.
  get-object-diff <object_name> -n <namespace> -p <pod>     - Get diff in object mappings between FMC and adapter by provided object name for specified namespace and adapter pod.
  get-diff-all -n <namespace> -p <pod>                      - Get diff in all objects mappings between FMC and adapter for specified namespace and adapter pod.
  restream-object <object_name> -n <namespace> -p <pod>     - Restream diff in object mappings by provided object name for specified namespace and adapter pod.
  restream-all-objects -n <namespace> -p <pod>              - Restream diff in all objects mappings between FMC and adapter for specified namespace and adapter pod.
  get-diff-paying-tenants                                   - Get diff in all objects mappings between FMC and adapter for all adapters pods in paying tenants.
  restream-all-objects-for-tenants -t "<tnt1>[, <tnt2>...]" - Restream diff in all objects mappings between FMC and adapter for all adapters pods in specified tenants.
EOF
}

# get list of namespaces with corresponding tenants and payment type
list_namespaces() {
    printf "============= LIST OF NAMESPACES WITH PAYMENT ============= \n\n"
    kubectl get ns -o custom-columns="NAMESPACE:.metadata.name,TENANT:.metadata.annotations.muster\.cisco\.com/x-cdo-tenant-name,PAYMENT:.metadata.annotations.muster\.cisco\.com/x-cdo-tenant-pay-type"
}

# get objects diff for all adapters pods in paying tenants
get_diff_paying_tenants() {
    local paying_namespaces=''
    paying_namespaces=$(list_namespaces | grep " PAYING" | awk '{print $1}')
    for namespace in $paying_namespaces ; do
        local tenant_name
        tenant_name=$(kubectl get namespace "$namespace" -o=jsonpath='{.metadata.labels.muster\.cisco\.com/x-cdo-tenant-name}')
        echo "Tenant name: $tenant_name"
        echo "Namespace: $namespace"
        local adapter_pods=''
        adapter_pods=$(kubectl get pod -n $namespace | grep -E "fmce|cdofm" | awk '{print $1}')

        if [[ -z "$adapter_pods" ]]; then
            echo -e "\nAdapter pod: absent"
            echo -e "\n===================================================\n"
            continue
        fi

        for pod in $adapter_pods ; do
            echo "Adapter pod: $pod"
            get_diff_all -n $namespace -p $pod
            echo -e "\n===================================================\n"
        done
    done
}

# restream all objects for all adapter pods in specified tenants
restream_all_objects_for_tenants() {
    echo "Starting restream_all_objects_for_tenants function..."

    echo "Arguments: $@"
    parse_tenant_names "$@"
    echo "Parsed tenant names: $tenant_names"

    for tenant_name in $tenant_names ; do
        echo "Processing tenant: $tenant_name"

        echo "Listing namespaces..."
        list_namespaces_output=$(list_namespaces)

        echo "Raw namespaces output:"
        echo "$list_namespaces_output"

        local namespace

        namespace=$(list_namespaces | grep -w " $tenant_name " | awk '{print $1}')

        echo "Namespace for tenant '$tenant_name': $namespace"

        if [[ -z "$namespace" ]]; then
            echo -e "\nTenant with name $tenant_name is absent"
            echo -e "\n===================================================\n"
            continue
        fi

        local adapter_pods=""
        adapter_pods=$(kubectl get pod -n $namespace | grep -E "fmce|cdofm" | awk '{print $1}')

        echo "Adapter pods for namespace '$namespace': $adapter_pods"

        if [[ -z "$adapter_pods" ]]; then
            echo -e "\nAdapter pod: absent"
            echo -e "\n===================================================\n"
            continue
        fi

        for pod in $adapter_pods ; do
            echo -e "\nProcessing adapter pod: $pod in namespace: $namespace"
            restream_all_objects -n $namespace -p $pod
            echo -e "Restream command executed for pod: $pod\n"
            echo -e "\n===================================================\n"
        done
    done

    echo "Completed restream_all_objects_for_tenants function."
}

# get general status for namespace
get_general_status() {
    local namespace=$1
    local status_log=$2
    echo "Collecting general status..."
    echo "Collecting info for namespace $namespace..."
    printf "========== NAMESPACE $namespace INFO=========\n" >> $status_log
    kubectl describe ns $namespace >> $status_log
    printf "\n\n===== LIST OF NAMESPACE PODS =====\n" >> $status_log
    kubectl get pod -n $namespace >> $status_log
    printf "\n\n===== LIST OF NAMESPACE ENTITIES STATUS=====\n" >> $status_log
    kubectl get muster -n $namespace >> $status_log
}

# collect logs and description for all pods of the provided namespace
get_pods_info() {
    local namespace=$1
    local ts_dir=$2
    echo "Collecting logs and descriptions..."
    local namespace_pods=''
    namespace_pods=$(kubectl get pod -n $namespace | awk '{if (NR>1) {print $1}}')
    mkdir -p $ts_dir/descriptions
    mkdir -p $ts_dir/logs
    mkdir -p $ts_dir/info
    for pod in $namespace_pods ; do
        # get pod description
        kubectl describe pod $pod -n $namespace > $ts_dir/descriptions/$pod.txt
        # get pod logs
        kubectl logs $pod -n $namespace > $ts_dir/logs/$pod.log
        # run `collect-info.sh` script for collecting additional info
        if kubectl exec -n $namespace $pod -- sh -c "[ -f /app/collect-info.sh ]" > /dev/null 2>&1 ; then
            kubectl exec -n $namespace $pod -- sh /app/collect-info.sh >> $ts_dir/info/$pod-collect-info.log 2>&1
            # collect saved_db info
            if kubectl exec -n $namespace $pod -- sh -c "[ -e /tmp/saved_db ]" ; then
                local db_resolved_path=$(kubectl exec -n $namespace $pod -- ls -l /tmp/saved_db | awk '{print $NF}')
                kubectl cp $namespace/$pod:$db_resolved_path $ts_dir/info/$pod-saved-db > /dev/null 2>&1
            fi
            # collect payload logs
	        if kubectl exec -n $namespace $pod -- sh -c "[ -e /tmp/payload_logs ]" > /dev/null 2>&1  ; then
                local paylad_resolved_path=$(kubectl exec -n $namespace $pod -- ls -l /tmp/payload_logs | awk '{print $NF}')
                kubectl cp $namespace/$pod:$paylad_resolved_path $ts_dir/info/$pod-payload_logs > /dev/null 2>&1
            fi
        fi
    done
}

# collect resource types info of the provided namespace into YAMLs files
get_resources_yamls() {
    local namespace=$1
    local ts_dir=$2
    local output_dir="$ts_dir/resource_types"
    echo "Collecting resource types info..."
    local resource_types_status="$output_dir/resource_types_collection.log"
    mkdir -p "$output_dir"
    local resource_types=''
    resource_types=$(kubectl api-resources --namespaced=true -o name)
    resource_types+=" "$(kubectl api-resources --namespaced=false -o name | grep "muster.cisco.com")

    for resource in $resource_types; do
        echo "Exporting $resource..."  >> $resource_types_status
        yaml_file="$output_dir/$resource.yaml"
        if [[ "$resource" == "secrets" ]]; then
            printf "Skipping $resource as it is in the skip list.\n\n" >> $resource_types_status
            continue
        fi
        # Try to get the resource and save to YAML file
        if kubectl get "$resource" -n "$namespace" -o yaml > "$yaml_file" 2>/dev/null; then
            # Check if the YAML file is empty and remove if so
            if grep -q "items: \[\]" "$yaml_file"; then
                printf "Skipping $resource due to empty items list.\n\n" >> $resource_types_status
                rm -f "$yaml_file"
            else
                printf "Exported $resource successfully.\n\n" >> $resource_types_status
            fi
        else
            printf "Skipping $resource due to MethodNotAllowed.\n\n"  >> $resource_types_status
            rm -f "$yaml_file"
        fi
    done
}

# generate troubleshoot bundle
ts_gen() {
    local namespace=$1
    if [ -z "$namespace" ] ; then
        echo "Please provide namespace. Use 'list-namespaces' command to get namespace by tenant name."
        exit 1
    elif ! kubectl get ns "$namespace" >/dev/null 2>&1; then
        echo "Namespace $namespace does not exist. Please provide correct namespace."
        exit 1
    fi
    echo "Generating troubleshoot bundle."
    echo
    echo "This may take a while.  Please be patient..."
    echo
    local current_time=$(date "+%Y.%m.%d-%H.%M.%S")
    echo "Start Time : $current_time"
    local ts_name="ts-bundle-$namespace-$current_time"
    local ts_dir=$(mktemp -d "/tmp/$ts_name-XXX")
    local status_log="$ts_dir/status.log"
    get_general_status $namespace $status_log

    # collect logs and description for each pod
    get_pods_info $namespace $ts_dir

    # collect info from resource types into YAMLs files
    get_resources_yamls $namespace $ts_dir

    local file_name="$ts_name.tar.gz"
    mv -f $ts_dir "/tmp/$ts_name"
    tar -czvf $file_name -C /tmp $ts_name > /dev/null 2>&1
    echo "Troubleshoot bundle $file_name generated."
    rm -rf "/tmp/$ts_name"
    echo "Finish Time : $(date "+%Y.%m.%d-%H.%M.%S")"
}

list_pods() {
    local namespace=$1
    if [ -z "$namespace" ] ; then
        echo "Please provide namespace."
        exit 1
    fi
    kubectl get pod -n $namespace
}

# Function to parse named options (-n <namespace>, -p <pod>)
parse_named_options() {
    namespace=""
    pod=""

    OPTIND=1  # Reset OPTIND for getopts to start fresh
    while getopts ":n:p:" opt; do
        case $opt in
        n)
            namespace=$OPTARG
            ;;
        p)
            pod=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            return 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            return 1
            ;;
        esac
    done

    if [[ -z "$namespace" || -z "$pod" ]]; then
        echo "Both -n <namespace> and -p <pod> are required. Use 'list-namespaces' and 'list-pod' commands to get namespace and pod."
        return 1
    fi

    echo "Namespace: $namespace"
    echo "Pod: $pod"
}

# Function to parse tenant names (-t <tenant_names>)
parse_tenant_names() {
    tenant_names=""
    local help_text="Usage: -t \"tenant1, tenant2, tenant3\""

    while getopts "t:" option; do
        case $option in
            t)
            tenant_names=$(echo "$OPTARG" | tr -d ",")
            ;;
            *)
            echo $help_text
            exit 1
            ;;
        esac
    done

    # Check if tenant_names variable is not empty
    if [ -z "$tenant_names" ]; then
        echo "No tenants provided. $help_text"
        exit 1
    fi
}

# Get objects from the FMC
get_objects_fmc() {
    parse_named_options "$@"
    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager get_objects SOURCE_FMC"
}

# Get objects from the Adapter
get_objects_adapter() {
    parse_named_options "$@"
    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager get_objects SOURCE_ADAPTER"
}

# Get object mappings from the FMC
get_object_fmc() {
    local obj_name=$1
    if [ -z "$obj_name" ] ; then
        echo "Please provide object name."
        exit 1
    fi
    shift
    parse_named_options "$@"

    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager get_object $obj_name SOURCE_FMC"
}

# Get object mappings from the Adapter
get_object_adapter() {
    local obj_name=$1
    if [ -z "$obj_name" ] ; then
        echo "Please provide object name."
        exit 1
    fi
    shift
    parse_named_options "$@"

    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager get_object $obj_name SOURCE_ADAPTER"
}

# Get object diff between FMC and Adapter records
get_object_diff() {
    local obj_name=$1
    if [ -z "$obj_name" ] ; then
        echo "Please provide object name."
        exit 1
    fi
    shift
    parse_named_options "$@"

    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager get_diff $obj_name"
}

# Get all objects diff using adapter
get_diff_all() {
    parse_named_options "$@"
    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager get_diff_all"
}

# Restream object diff to FMC from Adapter records
restream_object() {
    local obj_name=$1
    if [ -z "$obj_name" ] ; then
        echo "Please provide object name."
        exit 1
    fi
    shift
    parse_named_options "$@"

    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager restream_object $obj_name"
}

restream_all_objects() {
    parse_named_options "$@"
    kubectl exec -n $namespace $pod -- sh -c "muster_adapter_data_manager restream_all_objects"
}

##### main() #####
case $1 in
    help | "") help ;;
    list-namespaces) list_namespaces ;;
    get-diff-paying-tenants) get_diff_paying_tenants ;;
    restream-all-objects-for-tenants)
        shift
        restream_all_objects_for_tenants "$@"
        ;;
    ts-gen) ts_gen "$2" ;;
    list-pods) list_pods "$2" ;;
    get-objects-fmc)
        shift
        get_objects_fmc "$@"
        ;;
    get-objects-adapter)
        shift
        get_objects_adapter "$@"
        ;;
    get-object-fmc)
        shift
        get_object_fmc "$@"
        ;;
    get-object-adapter)
        shift
        get_object_adapter "$@"
        ;;
    get-object-diff)
        shift
        get_object_diff "$@"
        ;;
    get-diff-all)
        shift
        get_diff_all "$@"
        ;;
    restream-object)
        shift
        restream_object "$@"
        ;;
    restream-all-objects)
        shift
        restream_all_objects "$@"
        ;;
    *)
        echo "Unknown command: $1"
        echo
        help
        exit 1
        ;;
esac
exit 0
