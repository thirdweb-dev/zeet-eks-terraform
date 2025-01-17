provider "kubernetes" {
  config_path = "~/.kube/config" # Update if using a specific KUBECONFIG
}

resource "kubernetes_secret" "pgbouncer_config" {
  metadata {
    name      = "pgbouncer-config"
    namespace = "default" # Change if using a different namespace
  }

  data = {
    "pgbouncer.ini" = <<EOT
[databases]
your_database_name = host=${var.db_host} port=${var.db_port} dbname=${var.db_name}

[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = 0.0.0.0
listen_port = ${var.db_port}
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 200
default_pool_size = 40
EOT

    "userlist.txt" = <<EOT
"${var.db_user}" "${var.db_password_hashed}"
EOT
  }
}

resource "kubernetes_deployment" "pgbouncer" {
  metadata {
    name      = "pgbouncer"
    namespace = "default" # Change if using a different namespace
    labels = {
      app = "pgbouncer"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "pgbouncer"
      }
    }

    template {
      metadata {
        labels = {
          app = "pgbouncer"
        }
      }

      spec {
        container {
          name  = "pgbouncer"
          image = "edoburu/pgbouncer:latest"

          port {
            container_port = 5432
          }

          env {
            name  = "DB_HOST"
            value = var.db_host
          }

          env {
            name  = "DB_PORT"
            value = var.db_port
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name  = "DB_PASSWORD"
            value = var.db_password
          }

          volume_mount {
            name       = "pgbouncer-config"
            mount_path = "/etc/pgbouncer"
          }
        }

        volume {
          name = "pgbouncer-config"

          secret {
            secret_name = kubernetes_secret.pgbouncer_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pgbouncer" {
  metadata {
    name      = "pgbouncer"
    namespace = "default" # Change if using a different namespace
  }

  spec {
    selector = {
      app = "pgbouncer"
    }

    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

variable "db_host" {
  description = "Database host"
}

variable "db_port" {
  description = "Database port"
  default     = "5432"
}

variable "db_user" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
}

variable "db_password_hashed" {
  description = "Database password in MD5 hashed form"
}

variable "db_name" {
  description = "Database name"
}

output "pgbouncer_service_ip" {
  value = kubernetes_service.pgbouncer.metadata[0].name
}
