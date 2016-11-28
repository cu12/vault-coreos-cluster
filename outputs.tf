output "bastion.public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "vault.private_ip" {
  value = "${aws_instance.vault.0.private_ip}"
}

output "elb.dns_name" {
  value = "${aws_elb.vault.dns_name}"
}
