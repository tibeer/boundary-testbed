resource "boundary_scope" "org2" {
  scope_id    = boundary_scope.global.id
  name        = "org2"
  description = "org2"
}

resource "boundary_scope" "org2_project_cloud" {
  name                     = "Cloud"
  description              = "Cloud"
  scope_id                 = boundary_scope.org2.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}


resource "boundary_role" "org2_anon_listing" {
  scope_id = boundary_scope.org2.id
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}

resource "boundary_role" "org2_admin" {
  scope_id       = "global"
  grant_scope_id = boundary_scope.org2.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.user : user.id],
    ["u_auth"]
  )
}

resource "boundary_role" "org2_project_admin" {
  scope_id       = boundary_scope.org2.id
  grant_scope_id = boundary_scope.org2_project_cloud.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.user : user.id],
    ["u_auth"]
  )
}
