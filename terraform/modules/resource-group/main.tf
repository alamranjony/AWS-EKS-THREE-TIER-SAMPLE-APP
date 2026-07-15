# AWS has no direct equivalent of an Azure "resource group" as a
# deployment scope - resources just exist in a region/account. The
# closest native construct is AWS Resource Groups: a tag-based, queryable
# view over resources that share a tag, used here so the whole platform
# can be seen/filtered/cost-tracked as one logical unit in the console
# (Resource Groups & Tag Editor) even though nothing is physically
# "contained" by it the way an Azure resource group contains resources.
resource "aws_resourcegroups_group" "this" {
  name = "${var.project_name}-${var.environment}-rg"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "project"
          Values = [var.project_name]
        },
        {
          Key    = "environment"
          Values = [var.environment]
        }
      ]
    })
  }

  tags = var.tags
}
