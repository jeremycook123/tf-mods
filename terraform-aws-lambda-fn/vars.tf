variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.13)."
  type        = string
  validation {
    condition     = can(regex("^\\w+\\d*(?:\\.\\d+)?$", var.runtime))
    error_message = "runtime must be a valid Lambda runtime string like python3.13."
  }
}

variable "filename" {
  description = "Path to the deployment package ZIP file."
  type        = string
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = null
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Amount of memory in MB for the function."
  type        = number
  default     = 128
}

variable "architectures" {
  description = "Instruction set architecture for your function (e.g., [\"x86_64\"] or [\"arm64\"])."
  type        = list(string)
  default     = ["x86_64"]
}

variable "environment_variables" {
  description = "Environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda layer ARNs to attach."
  type        = list(string)
  default     = []
}

variable "dead_letter_target_arn" {
  description = "ARN of an SQS queue or SNS topic for dead-letter queue."
  type        = string
  default     = null
}

variable "vpc_config" {
  description = "VPC config for the Lambda, if it should run in a VPC."
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  default = null
}

variable "ephemeral_storage_size_mb" {
  description = "Ephemeral storage (/tmp) size in MB, 512–10240."
  type        = number
  default     = null
}

variable "publish" {
  description = "Whether to publish a new version with each update."
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this function. Use null for unreserved."
  type        = number
  default     = null
}

variable "tracing_mode" {
  description = "Tracing mode for AWS X-Ray (Active or PassThrough)."
  type        = string
  default     = "PassThrough"
  validation {
    condition     = contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "tracing_mode must be either Active or PassThrough."
  }
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

# Role inputs: either supply role_arn OR let module create one
variable "role_arn" {
  description = "Existing IAM role ARN for the Lambda. If null, the module creates one."
  type        = string
  default     = null
}

variable "role_name" {
  description = "Custom name for the role created by this module. Ignored if role_arn is provided."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}
