# kgetall
A bash script with performs the following:
  - kinfo: Get all info for a specific namespace
  - kexec: perform a specific exec function
  - kterm: terminate the specific namespace hanging resources

## Requirements
Only tested on a Ubuntu 22.04.3 LTS, should work with any linux distro as long as `kubectl`, `xargs`, `awk`, `grep`, and `shift` are all installed.
I use k3s, but it should work with k8s.
Client Version: v1.28.5
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.5+k3s1

## Usage
Best used when added to an alias. 
1. Clone the repository or download the script.
2. Save the script into your desired folder `/home/<user>/kube_scripts.sh`
3. Edit your desired .bashrc, .profile, etc. file and add `source /home/<user>/kube_scripts.sh`
4. Reload your current terminal.

### Exmaples
These examples work assuming you made an alias that points to the script, otherwise you have to run it direclty using ./kube_scripts.sh <function> <arguments>


1. Get all api-resources which returns a list of all resources available within an environment. 
`kube_scripts -a kinfo <namespace> (optional) <resource1> <resource2> ... <resource n>`
  - `kgetall -a kinfo -n authentik-dev`
2. Get the usage of the script `kube_scripts -a usage`
3. Kill all stuck terminating namespaces `kube_scripts -a kterms <namespace>`
  - `kgetall -a kterm -n authentik-dev`
4. Exec a specific pod `kube_scripts -a kexec -n namespace -p pod -d command (OPTIONAL: -c containerName, -s selector, -l shell)` 
  - `kgetall -a kexec -d env -n authentik-dev -p authentik-deployment-dev-v1-6cb4dcd7ff-ddbhv -h /bin/sh`

Get a specific namespaces specific rsources. Returning a list of the resources specified for that namespace. 
1. Namespace can be empty providing default or your current context, or have a specific namespace.
2. Resources can be anything including certificates, pods, etc.
`kube_scripts kgetall <namespace> <resource1> <resource2>`

## Changes
Feel free to change the custom-columns to what you want. I didn't need to have the ips and such so I left them out.
