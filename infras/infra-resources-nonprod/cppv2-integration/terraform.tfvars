account_id  = "273354624134"
region      = "us-east-1"
environment = "dev"
notification_emails = ["adenijimujeeb@gamil.com"]
slack_channel_id   = "C01ABCD2EFG"
slack_workspace_id = "T01ABCD2XYZ"
userplatform_s3_bucket = {
  us = "byt-userplatform-dev-us"
  eu = "byt-userplatform-dev-eu"
  ap = "byt-userplatform-dev-ap"
}
route_path = {
  us = "dev-us-collector"
  eu = "dev-emea-collector"
  ap = "dev-apac-collector"
}
# route_path          = ["dev-us-collector", "dev-emea-collector", "dev-apac-collector"]