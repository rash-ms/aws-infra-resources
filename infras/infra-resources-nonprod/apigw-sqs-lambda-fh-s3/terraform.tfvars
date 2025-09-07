account_id          = "273354624134"
region              = "us-east-1"
environment         = "dev"
notification_emails = ["adenijimujeeb@gamil.com"]
slack_channel_id    = "C07SSBH5A3A" # Change
slack_workspace_id  = "T03VAJN2485" # Get after authenticating with slack
stage_name          = "stg-api-v01"
userplatform_s3_bucket = {
  us = "byt-userplatform-dev-us"
  eu = "byt-userplatform-dev-eu"
  ap = "byt-userplatform-dev-ap"
}
route_path = {
  us = "cpp-us-interface"
  eu = "cpp-eu-interface"
  ap = "cpp-ap-interface"
}
