resource "ionoscloud_user" "test_user" {
  first_name     = "Thorsten Test"
  last_name      = "User"
  email          = "thorstenfoltz@yahoo.de"
  password       = random_password.user_password.result
  administrator  = false
  force_sec_auth = false
  active         = true
  group_ids      = [ionoscloud_group.developer.id]
}