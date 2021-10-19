node_name  = "consul-client"
server     = false
datacenter = "dc1"
data_dir   = "/home/consul/data"
log_level  = "INFO"
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"172.31.0.0/8\" | attr \"address\" }}"
retry_join = ["provider=aws tag_key=ConsulAutoJoin tag_value=auto-join"]
service {
  id      = "dns"
  name    = "dns"
  tags    = ["primary"]
  address = "localhost"
  port    = 8600
  check {
    id       = "dns"
    name     = "Consul DNS TCP on port 8600"
    tcp      = "localhost:8600"
    interval = "10s"
    timeout  = "1s"
  }
}
