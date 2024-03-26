#! /bin/bash
# set -x

kinfo() {
  local namespace=$1
  echo $namespace
  if [ -z $namespace ]; then
    printf 'This command requires 1 argument. (NS)\n'
    usage
  fi  
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
  local namespace=$1

  if [ -z "$1" ]; then
    printf 'This command requires 1 argument (NS)\n'
    usage
  fi  
  kubectl get namespace "$namespace" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \ | kubectl replace --raw /api/v1/namespaces/$namespace/finalize -f -
}

#Performs exec on specific pod, option for specific container
kexec() {
    # 
  local command=$1 
  local container=$2
  local originalPodName=$3
  local selector=$4
  local namespace=$5    
  local shell=$6


  if [ -z "$1" ]; then
    printf 'This command requires at least 3 arguments (POD NS command optional: container, selector, shell)\n'
    usage
  elif [ "$#" -lt  3 ]; then
    printf 'This command requires at least 3 arguments (POD NS command, optional: container, selector, shell)\n'
    usage
  fi


  if [[ $originalPodName != *"pod/"* ]]; then
    podName="pod/$originalPodName"
  fi

  if [ -z $shell ]; then
    shell=/bin/sh
  fi

  if [[ -z $selector ]] && [[  -z $container ]]; then
    kubectl exec -it "$podName"  --namespace $namespace -- $shell -c "$command"
  elif [[ -z $selector ]]; then
    kubectl exec -it $podName --container $container -n $namespace -- $shell -c "$command"
  else
    pod=$(kubectl get pod -l app="$selector" -n $namespace -o jsonpath="{.items[0].metadata.name}")
    kubectl exec $pod --container $container -n $namespace -- $shell -c "$command"
  fi
}

#Prints help info
usage(){
  printf 'Usage:'
  printf '\t-a\tSelect which function to use\n'
  printf '\t\t\tkinfo\t- Get all resources from the functions within the specified namespace.\tArguments: Namespace\n'
  printf '\t\t\tktermns\t- Terminate a namespace from stuck "TERMINIATING" status.\t\t\tArguments: Namespace\n'
  printf '\t\t\tkexec\t- Run an exec shell in a specified pod.\t\t\t\t\tArguments: Namespace Pod Command (OPTIONAL: Container Name, Selector, Shell)\n'
  printf '\t\t\tusage\t- Prints this help screen.\n'
  printf '\t-c\tThe container name\n'
  printf '\t-l\tSelect the shell (default: /bin/sh)\n'
  printf '\t-n\tSelect the namespace\n'
  printf '\t-p\tSelect the pod name\n'
  printf '\t-s\tSelect the selector name (app only)\n'
  printf '\n'
  printf 'Examples:\n'
  printf 'Use kexec with a command, namespace, pod name, and shell type:\n\tkgetall -a kexec -d env -n authentik-dev -p authentik-deployment-dev-v1-6cb4dcd7ff-ddbhv -h /bin/sh\n'
  printf 'Use kinfo to get all resources in a ns:\n\tkgetall -a kinfo -n authentik-dev\n'
  printf 'Use kterm to delete all hanging processes in a namespace:\n\tkgetall -a kterm -n authentik-dev'
  exit 1
}

while getopts "a:c:d:n:p:s:l:h:" opt; do
  case $opt in
    # echo $opt
    a)
        action="$OPTARG"
        ;;
    c)
        container="$OPTARG"
        ;;
    d)
        command="$OPTARG"
        ;;
    l)
        shell="$OPTARG"
        ;;
    n)
        namespace="$OPTARG"
        ;;
    p)
        podName="$OPTARG"
        ;;
    s)
        selector="$OPTARG"
        ;;
    h)
        usage
        ;;
  esac
done

if [[ -z "$action" ]]; then
  echo "Option -a is a requirement"
elif [[ $action ]]; then
  case $action in
    "kinfo")
      if [[ -z "$action" ]] || [[ -z "$namespace" ]]; then
        printf "Options -a, -n, are mandatory for action kinfo\n\n"
        usage
      fi
      $action "$namespace"
      ;;
    "kterm")
      if [[ -z "$action" ]] || [[ -z "$namespace" ]]; then
        printf "Options -a, -n, are mandatory for action kterm\n\n"
        usage
      fi      
      $action "$namespace"
      ;;
    "kexec")
      if [[ -z "$action" ]] || [[ -z "$podName" ]] || [[ -z "$namespace" ]]; then
        printf "Options -a, -p, -n, are mandatory for action kexec\n\n"
        usage
      fi
      $action "$command" "$container" "$podName" "$selector" "$namespace" "$shell"
      ;;
    "usage")
      usage
      ;;
    *)
      printf "Invalid option -a.\n"
      usage
      ;;
  esac
fi
