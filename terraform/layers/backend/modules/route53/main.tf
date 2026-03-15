
data "aws_route53_zone" "main" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.api_file_upload_domain_name
  type    = "A"

  alias {
    name                   = var.api_gateway_regional_domain_name
    zone_id                = var.api_gateway_regional_zone_id
    evaluate_target_health = false
  }
}
