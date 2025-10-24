locals {
  project = "edgebox"
}

provider "docker" {}

resource "docker_network" "edgebox" {
  name = "edgebox"
}

resource "docker_volume" "postgres_data" {
  name = "edgebox_postgres"
}

resource "docker_image" "edgebox_svc" {
  name = "edgebox/edgebox-svc:local"
  build {
    context    = "../edgebox-svc"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "peoplecounter" {
  name = "edgebox/peoplecounter:local"
  build {
    context    = "../peoplecounter"
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "postgres" {
  name    = "edgebox-postgres"
  image   = "postgres:16-alpine"
  restart = "unless-stopped"
  env = [
    "POSTGRES_USER=micro",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=microdb",
    "TZ=${var.timezone}"
  ]
  mounts {
    target = "/var/lib/postgresql/data"
    source = docker_volume.postgres_data.name
    type   = "volume"
  }
  networks_advanced {
    name = docker_network.edgebox.name
  }
}

resource "docker_container" "edgebox_svc" {
  name    = "edgebox-svc"
  image   = docker_image.edgebox_svc.name
  restart = "unless-stopped"
  env = [
    "SPRING_PROFILES_ACTIVE=compose",
    "SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/microdb",
    "SPRING_DATASOURCE_USERNAME=micro",
    "SPRING_DATASOURCE_PASSWORD=${var.postgres_password}",
    "LAN_HOST=${var.lan_host}"
  ]
  networks_advanced {
    name = docker_network.edgebox.name
  }
  depends_on = [docker_container.postgres]
}

resource "docker_container" "peoplecounter" {
  name    = "edgebox-peoplecounter"
  image   = docker_image.peoplecounter.name
  restart = "unless-stopped"
  env = [
    "DATABASE_URL=postgresql://micro:${var.postgres_password}@postgres:5432/microdb"
  ]
  networks_advanced {
    name = docker_network.edgebox.name
  }
  depends_on = [docker_container.postgres]
}
