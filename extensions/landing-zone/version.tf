terraform {
  required_version = ">= 1.3.0, < 1.6.0"
  required_providers {
    # Locking into an exact version for a deployable architecture
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.57.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
}
