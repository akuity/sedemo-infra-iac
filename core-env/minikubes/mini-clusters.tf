
locals {
  setup_minikube_command = <<EOT
/home/ubuntu/setup_minikube.sh \
--elastic-ip ${aws_eip.instance_elastic_ip[each.value].public_ip} \
--region ${each.value}
EOT
  minkube_regions = ["eu-central-1"]
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  for_each = toset(local.minkube_regions)
}

resource "aws_key_pair" "aws_keypair" {
  for_each = toset(local.minkube_regions)
  region      = each.value
  public_key = tls_private_key.private_key[each.value].public_key_openssh
}

resource "aws_security_group" "allow_kube_api_server" {
  for_each = toset(local.minkube_regions)
  region      = each.value
  name        = "${var.minikube_instance_name}-allow-kube-api-server"
  description = "Allow incoming K8S API Server traffic"
  ingress = [
    {
      description      = "allow ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "TCP"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "allow api server"
      from_port        = 8443
      to_port          = 8443
      protocol         = "TCP"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "allow all"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "allow_kube_api_server"
  }
}

resource "aws_security_group" "allow_additional_exposed_ports" {

  for_each = toset(local.minkube_regions)
  region      = each.value
  name        = "${var.minikube_instance_name}-allow-additional-exposed-ports"
  description = "Allow exposed ports from services"
  ingress = [
    for exposed_port in var.exposed_ports : {
      description      = "allow ports ${exposed_port.port}"
      from_port        = exposed_port.port
      to_port          = exposed_port.port
      protocol         = exposed_port.protocol
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

resource "aws_eip" "instance_elastic_ip" {
  for_each = toset(local.minkube_regions)
  region      = each.value
}

data "aws_ec2_instance_type" "this" {
  instance_type = "t3.small"
}


resource "aws_instance" "minikube_instance" {
  for_each = toset(local.minkube_regions)
  region      = each.value
  ami           = "ami-051eaec1417c5d4ae"
  instance_type = data.aws_ec2_instance_type.this.id
  key_name      = aws_key_pair.aws_keypair[each.value].key_name
  security_groups = [
    aws_security_group.allow_kube_api_server[each.value].name,
    aws_security_group.allow_additional_exposed_ports[each.value].name
  ]

  tags = {
    Name = var.minikube_instance_name
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.private_key[each.value].private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/scripts/setup_minikube.sh"
    destination = "/home/ubuntu/setup_minikube.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_minikube.sh",
      local.setup_minikube_command
    ]
  }
}

# resource "null_resource" "download_kubeconfig" {
#   depends_on = [
#     aws_instance.minikube_instance
#   ]
#   triggers = {
#     "timestamp" = timestamp()
#   }
#   provisioner "local-exec" {
#     command = "${path.module}/scripts/download_kubeconfig.sh \"$PRIVATE_KEY\" ubuntu ${aws_eip.instance_elastic_ip.public_ip} ${var.kubeconfig_output_location}"
#     environment = {
#       PRIVATE_KEY = tls_private_key.private_key.private_key_pem
#     }
#   }
# }

resource "aws_eip_association" "minikube_eip_assoc" {
  instance_id   = aws_instance.minikube_instance[each.value].id
  allocation_id = aws_eip.instance_elastic_ip[each.value].id
}

output "key_pair_private_key" {
  description = "Key pair for ${each.value} region"
  value     = tls_private_key.private_key[each.value].private_key_pem
  sensitive = true
}

output "minikube_public_ip" {
  description = "MiniKube instance public ip address for ${each.value} region"
  value       = aws_eip.instance_elastic_ip[each.value].public_ip
}