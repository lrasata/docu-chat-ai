# -------------------------
# ROUTE 53 ALIAS RECORD
# -------------------------
data "aws_route53_zone" "main" {
  name         = "epic-trip-planner.com" # UPDATE this to corresponding domain name, this has to be static to allow retrieval of the Route 53 Hosted Zone
  private_zone = false
}

resource "aws_route53_record" "cdn_alias_webapp" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.alt_domain_name
  type    = "A"

  alias {
    name                   = var.cdn_domain_name
    zone_id                = var.cdn_hosted_zone_id
    evaluate_target_health = false
  }
}