terraform {
  required_version = ">= 1.0.0"
  required_providers {
    # Locking into an exact version for a deployable architecture
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.70.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
  }
}
