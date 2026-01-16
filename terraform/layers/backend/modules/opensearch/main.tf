locals {
  collection = "${var.environment}-${var.app_id}-collection"
}

resource "aws_opensearchserverless_collection" "opensearch_collection" {
  name = local.collection
  type = "VECTORSEARCH"
}

resource "aws_opensearchserverless_security_policy" "opensearch_encryption" {
  name = "${local.collection}-encryption"
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
  name = "${local.collection}-network"
  type = "network"

  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection}"]
    }]
    AllowFromPublic = true
  }])
}
