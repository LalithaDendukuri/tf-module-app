locals {
  name_prefix = "${var.env}-${var.component}"
  tags        = merge(var.tags, { tf-module-name = "app" }, { env = var.env })
  policy_resources ="arn:aws:ssm:us-east-1:896540652966:parameter/docdb.dev.*"
}