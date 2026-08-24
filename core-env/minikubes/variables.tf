variable "common_tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
  default = {
    "cost_center"         = "sales"
    "owner"               = "eddie.webbinaro@akuity.io"
    "Team"                = "Sales Engineering"
    "iac"                 = "true"
    "critical_until"      = "2035-12-31"
    "data_classification" = "low"
    "purpose"             = "ARAD - Akuity Reference Architecture Demo"
  }
}

#
#. MiniKube Stuff
# Minikube is only used to make Aargo look bigger/busier in AKI and AKP
#

variable "minikube_instance_name" {
  default = "sedemo-minikube"
}

variable "exposed_ports" {
  type = list(object({
    port     = number
    protocol = string
  }))
  description = "Ports to expose from Minikube EC2 instance"
  default = [{
    port     = 80
    protocol = "tcp"
  }]

  validation {
    condition = var.exposed_ports == null ? true : (alltrue([
      for o in var.exposed_ports : contains(["tcp", "udp", "icmp", "all", "-1"], o.protocol)
    ]))
    error_message = "The exposed_ports[].prococol should one of: tcp, udp, icmp, all, -1."
  }

  validation {
    condition = var.exposed_ports == null ? true : (alltrue([
      for o in var.exposed_ports : can(tonumber(o.port))
    ]))
    error_message = "var.exposed_ports[].port should be a number"
  }
}