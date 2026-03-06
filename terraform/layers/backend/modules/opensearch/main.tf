locals {
  collection = "${var.environment}-${var.app_id}"
}

resource "aws_opensearchserverless_collection" "opensearch_collection" {
  name = local.collection
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.opensearch_encryption,
    aws_opensearchserverless_security_policy.opensearch_network
  ]
}

resource "aws_opensearchserverless_security_policy" "opensearch_encryption" {
  name = local.collection
  type = "encryption"

  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection}"]
    }]
    AWSOwnedKey = true
  })
}


resource "aws_opensearchserverless_security_policy" "opensearch_network" {
  name = local.collection
  type = "network"

  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection}"]
    }]
    AllowFromPublic = true
  }])
}

# Data access policy for Lambda execution roles
resource "aws_opensearchserverless_access_policy" "opensearch_data_access" {
  name = local.collection
  type = "data"

  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index"
        Resource     = ["index/${local.collection}/*"]
        Permission = [
          "aoss:CreateIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ]
      },
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection}"]
        Permission   = ["aoss:DescribeCollectionItems"]
      }
    ]
    Principal = ["*"]
  }])
}
