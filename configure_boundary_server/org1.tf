resource "boundary_scope" "org1" {
  scope_id    = boundary_scope.global.id
  name        = "org1"
  description = "org1"
}

resource "boundary_auth_method" "org1_password" {
  name        = "org1_password_auth"
  description = "Password auth method for org1"
  type        = "password"
  scope_id    = boundary_scope.org1.id
}

resource "boundary_account" "org1_user" {
  for_each       = var.users
  name           = each.key
  description    = "User account for ${each.key}"
  type           = "password"
  login_name     = lower(each.key)
  password       = "test123."
  auth_method_id = boundary_auth_method.org1_password.id
}

resource "boundary_user" "org1_user" {
  for_each    = var.users
  name        = each.key
  description = "User resource for ${each.key}"
  account_ids = [boundary_account.org1_user[each.value].id]
  scope_id    = boundary_scope.org1.id
}

resource "boundary_scope" "org1_project_bms" {
  name                     = "Bare Metal Servers"
  description              = "Bare Metal Servers"
  scope_id                 = boundary_scope.org1.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_role" "org1_anon_listing" {
  scope_id = boundary_scope.org1.id
  grant_strings = [
    "id=*;type=*;actions=*" # allow everything, admin account for org
    #"id=*;type=auth-method;actions=list,authenticate",
    #"type=scope;actions=list",
    #"id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}

resource "boundary_role" "org1_admin" {
  scope_id       = "global"
  grant_scope_id = boundary_scope.org1.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.org1_user : user.id],
    ["u_auth"]
  )
}

resource "boundary_role" "org1_project_admin" {
  scope_id       = boundary_scope.org1.id
  grant_scope_id = boundary_scope.org1_project_bms.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.org1_user : user.id],
    ["u_auth"]
  )
}

resource "boundary_host_catalog" "org1_hosts" {
  name        = "hosts"
  description = "Hosts targets"
  type        = "static"
  scope_id    = boundary_scope.org1_project_bms.id
}

resource "boundary_host" "localhost" {
  type            = "static"
  name            = "via-ssh"
  description     = "Localhost host"
  address         = "81.163.192.30"
  host_catalog_id = boundary_host_catalog.org1_hosts.id
}

# Target hosts available on localhost: ssh and postgres
# Postgres is exposed to localhost for debugging of the 
# Boundary DB from the CLI. Assumes SSHD is running on
# localhost.
resource "boundary_host_set" "local" {
  type            = "static"
  name            = "local"
  description     = "Host set for local servers"
  host_catalog_id = boundary_host_catalog.org1_hosts.id
  host_ids        = [boundary_host.localhost.id]
}

resource "boundary_target" "ssh" {
  type                     = "tcp"
  name                     = "ssh"
  description              = "SSH server"
  scope_id                 = boundary_scope.org1_project_bms.id
  session_connection_limit = -1
  session_max_seconds      = 28800
  default_port             = 22
  host_set_ids = [
    boundary_host_set.local.id
  ]
}
