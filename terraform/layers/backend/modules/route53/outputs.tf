output "route53_record_fqdn" {
  description = "FQDN of the Route 53 record"
  value       = aws_route53_record.api.fqdn
}

output "route53_zone_id" {
  description = "ID of the Route 53 zone"
  value       = data.aws_route53_zone.main.zone_id
}