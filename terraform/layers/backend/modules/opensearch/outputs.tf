output "opensearch_collection_id" {
  description = "The ID of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.opensearch_collection.id
}

output "opensearch_collection_name" {
  description = "The name of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.opensearch_collection.name
}

output "opensearch_collection_arn" {
  description = "The ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.opensearch_collection.arn
}


output "opensearch_collection_endpoint" {
  value = aws_opensearchserverless_collection.opensearch_collection.collection_endpoint
}