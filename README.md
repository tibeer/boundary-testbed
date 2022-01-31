# Boundary Testbed

## Requirements

- An up to date version of docker
- `ansible-galaxy collection install community.docker`

## How to get started

Step 1: Start containers (watch out for the comma)

```sh
pushd deploy_boundary_server
ansible-playbook -u ubuntu -i <ip>, setup.yaml
popd
```

Step 2: Configure Boundary

```sh
pushd configure_boundary_server
export BOUNDARY_ADDR=http://<ip>:9200
terraform init
terraform apply -auto-approve
# confirm variable prompt by pressing return without entering data
popd
```
