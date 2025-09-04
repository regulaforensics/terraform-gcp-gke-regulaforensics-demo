variable "project_id" {
  type        = string
  description = "Id of your project"
}

variable "region" {
  type        = string
  description = "The region to host the cluster in (optional if zonal cluster / required if regional)"
}

variable "regional" {
  type        = bool
  description = "Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!)"
  default     = false
}

variable "zones" {
  type        = list(string)
  description = "Zones to deploy cluster"
}

variable "name" {
  type        = string
  description = "Name of your cluster"
}

variable "master_authorized_networks" {
  type = list(map(string))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Open for all"
    }
  ]
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Whether the master's internal IP address is used as the cluster endpoint"
  default     = false
}

variable "enable_private_nodes" {
  type        = bool
  description = "Whether nodes have internal IP addresses only"
  default     = true
}

variable "subnet_private_access" {
  type        = bool
  description = "When enabled, VMs in this subnetwork without external IP addresses can access Google APIs and services by using Private Google Access"
  default     = true
}

variable "subnet_ip_range" {
  type        = string
  description = "The range of IP addresses belonging to this subnetwork secondary range. Provide this property when you create the subnetwork. Ranges must be unique and non-overlapping with all primary and secondary IP ranges within a network. Only IPv4 is supported"
  default     = "10.1.0.0/28"
}

variable "secondary_ip_ranges" {
  description = "An array of configurations for secondary IP ranges for VM instances contained in this subnetwork. The primary IP of such VM must belong to the primary ipCidrRange of the subnetwork. The alias IPs may belong to either primary or secondary ranges"
  type        = list(map(string))
  default = [{
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/14"
    },
    {
      range_name    = "k8s-service-range"
      ip_cidr_range = "10.52.0.0/20"
  }]
}

variable "node_count" {
  type        = string
  description = "The number of nodes in the nodepool when autoscaling is false. Otherwise defaults to 1. Only valid for non-autoscaling clusters"
  default     = 1
}

variable "disk_size_gb" {
  type        = string
  description = "Size of the disk attached to each node, specified in GB. The smallest allowed disk size is 10GB"
  default     = "100"
}

variable "disk_type" {
  type        = string
  description = "Type of the disk attached to each node"
  default     = "pd-standard"
}

variable "machine_type" {
  type        = string
  description = "The name of a Google Compute Engine machine type"
  default     = "e2-standard-4"
}

variable "spot" {
  type        = bool
  description = "A boolean that represents whether the underlying node VMs are spot"
  default     = true
}

variable "enable_docreader" {
  description = "Deploy Docreader helm chart"
  type        = bool
  default     = false
}

variable "docreader_values" {
  description = "Docreader helm values"
  type        = string
  default     = ""
}

variable "docreader_license" {
  description = "Docreader Regula license file"
  type        = string
  default     = ""
}

variable "enable_faceapi" {
  description = "Deploy Faceapi helm chart"
  type        = bool
  default     = false
}

variable "faceapi_values" {
  description = "Faceapi helm values"
  type        = string
  default     = ""
}

variable "face_api_license" {
  description = "Faceapi Regula license file"
  type        = string
  default     = ""
}
