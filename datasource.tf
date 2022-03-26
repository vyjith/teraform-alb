data "aws_route53_zone" "selected" {
  name         = "vyjithks.tk."
  private_zone = false
}

output "zone" {

value = data.aws_route53_zone.selected.id

}
