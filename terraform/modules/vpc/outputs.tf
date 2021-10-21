output vpc_id {
  value = aws_vpc.vpc.id
}

output private_subnet_ids {
  value = "${tolist([element(aws_subnet.private.*.id, 1), element(aws_subnet.private.*.id, 2), element(aws_subnet.private.*.id, 3)])}" 
}

output public_subnet_ids {
  value = "${tolist([element(aws_subnet.public.*.id, 1), element(aws_subnet.public.*.id, 2), element(aws_subnet.public.*.id, 3)])}" 
}
