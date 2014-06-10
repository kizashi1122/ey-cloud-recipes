# ===  COMMON SETTINGS (mainly used in recipe/default.rb)
#
default['elasticsearch']['version']           = "1.2.1"
default['elasticsearch']['checksum']          = "e89eef412d287768bea420812f6f9e05570cae76"

default['elasticsearch']['dir']               = "/usr/lib"
default['elasticsearch']['home']              = "/usr/lib/elasticsearch"
default['elasticsearch']['path']['conf']      = "/usr/lib/elasticsearch/config"
default['elasticsearch']['path']['plugins']   = "/usr/lib/elasticsearch/plugins"
default['elasticsearch']['path']['data']      = "/data/elasticsearch/data" # because /data mount on engineyard ec2 instances is persistent 
default['elasticsearch']['path']['logs']      = "/data/elasticsearch/logs" # ditto

default['elasticsearch']['bootstrap']['mlockall'] = ( node.memory.total.to_i >= 1048576 ? true : false )
default['elasticsearch']['limits']['memlock']     = 'unlimited'
default['elasticsearch']['limits']['nofile']      = '64000'

default['elasticsearch']['user']              = "elasticsearch"
default['elasticsearch']['group']             = "elasticsearch"

default['elasticsearch']['http']['port']      = 9200
default['elasticsearch']['cluster']['name']   = "elasticsearch"
default['elasticsearch']['node']['name']      = node.name

default['elasticsearch']['pid_file']          = "/var/run/elasticsearch.pid" 


# === ES_JAVA_OPTS SETTINGS (elasticsearch.in.sh)
#
allocated_memory = "#{(node.memory.total.to_i * 0.6 ).floor / 1024}m"
default['elasticsearch']['allocated_memory']  = allocated_memory
default['elasticsearch']['thread_stack_size'] = "256k"
default['elasticsearch']['env_options'] = ""

# === PRODUCTION SETTINGS (elasticsearch.yml)
#
default['elasticsearch']['index']['mapper']['dynamic']                       = true
default['elasticsearch']['action']['auto_create_index']                      = true
default['elasticsearch']['action']['disable_delete_all_indices']             = true
default['elasticsearch']['node']['max_local_storage_nodes']                  = 1

default['elasticsearch']['discovery']['zen']['ping']['multicast']['enabled'] = true
default['elasticsearch']['discovery']['zen']['minimum_master_nodes']         = 1
default['elasticsearch']['gateway']['type']                                  = 'local'
default['elasticsearch']['gateway']['expected_nodes']                        = 1


