variable "ACCESS_KEY" {
  type      = string
  sensitive = true
  default   = "YOUR_AWS_ACCESS_KEY_ID"
}

variable "SECRET_KEY" {
  type      = string
  sensitive = true
  default   = "YOUR_AWS_SECRET_ACCESS_KEY"
}

variable "TOKEN" {
  type    = string
  default = "YOUR_AWS_SESSION_TOKEN"
}

variable "EC2_KEY" {
  type    = string
  default = "YOUR_KEY_PAIR_NAME"
}

variable "IAM_ROLE_ARN" {
  type    = string
  default = "YOUR_LAB_ROLE_ARN"
# Example arn: arn:aws:iam::138734174841:role/LabRole
}

variable "DB_NAME" {
  type    = string
  default = "smart_feed"
}

variable "DB_USERNAME" {
  type    = string
  default = "admin_user"
}

variable "DB_PASSWORD" {
  type    = string
  default = "qYUxs1Y6b1I7JNGqR5u33z$"
}

variable "TWITTER_TOKEN" {
  type    = string
  default = "AAAAAAAAAAAAAAAAAAAAAFc8hwEAAAAADxwoCsAIq6HRvst2LQPd8HCaptI%3DCk7QmMpBuwc60mkAgmWhLLVUK3nRo8Pc9UfybMK3SrzDB9QXUV"
}

variable "LAMBDA_KEY" {
  type    = string
  default = "90xblPS7jTC4JFK"
}