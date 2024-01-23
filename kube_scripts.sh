#! /bin/bash
kgetall() {
  if [ -z "$1" ]; then
    printf 'This command requires 1 argument. (NS)\n'
    usage
  fi  
  local namespace="$1"
  shift
  local resource_types=("$@")
  local headers_printed=false

  if [ ${#resource_types[@]} -eq 0 ]; then
    kubectl api-resources --verbs=list --namespaced -o name  | xargs -n 1 kubectl get --namespace="$namespace" -o custom-columns=RESOURCE:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace | awk '/RESOURCE/ && !header_printed {print; header_printed=1} !/RESOURCE/ && header_printed'

  else
    for resource_type in "${resource_types[@]}"; do
        if kubectl api-resources --verbs=list --namespaced -o name | grep -q -w "$resource_type"; then
          kubectl get "$resource_type" --namespace="$namespace" --ignore-not-found=true --no-headers="$headers_printed" -o custom-columns=RESOURCE:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace | awk '{printf "%-15s %-30s %-15s\n", $1, $2, $3}'
        else
          echo "Resource type '$resource_type' not found."
        fi
        headers_printed=true
    done
  fi
}

#Will not work if not in Terminiating state
ktermns(){
  if [ -z "$1" ]; then
    printf 'This command requires 1 argument (NS)\n'
    usage
  fi  
  kubectl get namespace "$1" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \ | kubectl replace --raw /api/v1/namespaces/$1/finalize -f -
}

#Performs exec on specific pod, option for specific container
function kexec() {
    if [ -z "$1" ]; then
      printf 'This command requires at least 3 arguments (POD NS SHELL)\n'
      usage
    elif [ "$#" -lt  3 ]; then
      echo "$0 $1 $2 $3 $4 $#"
      printf 'This command requires at least 3 arguments (POD NS SHELL)\n'
      usage
    fi

    if [ "$#" -eq "3" ]; then
      kubectl exec -it pod/"$1"  -n "$2" -- $3
    else
      kubectl exec -it pod/"$1" -c $4 -n "$2" -- $3
    fi
}

#Prints help info
usage(){
  printf 'To use pick from the following functions. Please note, arguement order matters: \n'
  printf '\tkgetall\t-\tGet all resources from the functions within the specified namespace.\tArguments: Namespace\n'
  printf '\tktermns\t-\tTerminate a namespace from stuck "TERMINIATING" status.\t\t\tArguments: Namespace\n'
  printf '\tkexec\t-\tRun an exec shell in a specified pod.\t\t\t\t\tArguments: Namespace Pod Shell (OPTIONAL: Container)\n'
  printf '\tusage\t-\tPrints this help screen.\n'
  exit 1
}



# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  usage
fi
