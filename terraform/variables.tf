variable "public_key_path" {
  description = "Calea catre cheia publica SSH"
  type        = string
  default     = "~/.ssh/id_rsa_aws.pub"
}
variable "environment" {
  description = "Mediul de deployment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Numele proiectului"
  type        = string
  default     = "AxgProject"
}

variable "my_ip" {
  type        = string
  description = "IP-ul meu"
}

