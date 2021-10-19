node_name = "consul-server"
bootstrap_expect = 3
server    = true
datacenter = "dc1"
data_dir   = "/opt/consul"
log_level  = "INFO"
retry_join = ["provider=aws tag_key=ConsulAutoJoin tag_value=auto-join"]
ui = true
addresses {
  http = "0.0.0.0"
}
