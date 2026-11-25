terraform {
  required_version = ">= 1.15.0"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 3.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace_v1" "mongodb" {
  metadata {
    name = "mongodb"
  }
}

resource "helm_release" "mongodb" {
  name = "mongodb"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "mongodb"
  namespace = kubernetes_namespace_v1.mongodb.metadata[0].name
  version = "0.0.2"

  wait = true
  wait_for_jobs = true

  values = [
    yamlencode({
      persistence = {
        var = {
          size = "16Gi"
        }
      }
    })
  ]
}