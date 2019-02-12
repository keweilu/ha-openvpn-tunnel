output "EIPAddress1" {
  value = "${aws_eip.EIPAddress1.public_ip}"
}

output "EIPAddress2" {
  value = "${aws_eip.EIPAddress2.public_ip}"
}