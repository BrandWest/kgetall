#! /bin/bash
kgetall() {
  local namespace="$1"
  shift
  local resource_types=("$@")
  local headers_printed=false

  if [ ${#resource_types[@]} -eq 0 ]; then
    kubectl api-resources --verbs=list --namespaced -o name  | xargs -n 1 kubectl get --namespace="$namespace" -o custom-columns=RESOURCE:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace | awk '/RESOURCE/ && !header_printed {print; header_printed=1} !/RESOURCE/ && header_printed'

  else
    for resource_type in "${resource_types[@]}"; do
        if kubectl api-resources --verbs=list --namespaced -o name | grep -q -w "$resource_type"; then
          kubectl get "$resource_type" --namespace="$namespace" --ignore-not-found=true --no-headers="$headers_printed" -o custom-columns=RESOURCE:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace
        else
          echo "Resource type '$resource_type' not found."
        fi
        headers_printed=true
    done
  fi
}
