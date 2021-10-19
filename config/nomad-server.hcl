# /etc/nomad.d/server.hcl

# data_dir tends to be environment specific.
data_dir = "/opt/nomad/data"

server {
  enabled          = true
  bootstrap_expect = 3
}

addresses {
  http = "0.0.0.0"
}
