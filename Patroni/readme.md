sudo apt update
sudo hostnamectl set-hostname nodeN #N=Node Numbers, Like Node-1, Node-2 etc
sudo apt install net-tools

# Installing postgresql 15 in Ubuntu 22.04 LTS

sudo apt update
sudo apt upgrade
sudo apt install dirmngr ca-certificates software-properties-common apt-transport-https lsb-release curl -y
curl -fSsL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /usr/share/keyrings/postgresql.gpg > /dev/null
echo deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main | sudo tee /etc/apt/sources.list.d/postgresql.list
echo deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg-snapshot main | sudo tee /etc/apt/sources.list.d/postgresql.list
sudo apt update
sudo apt install postgresql-client-15 postgresql-15
systemctl status postgresql

# Further Process

sudo systemctl stop postgresql
sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/
apt -y install python3 python3-pip
sudo apt install python3-testresources
sudo pip3 install --upgrade setuptools 
apt-get -y install python3-psycopg2
sudo pip3 install patroni
sudo pip3 install python-etcd

# Setup etcdnode [etcd VM]

sudo apt update
sudo hostnamectl set-hostname etcdnode
sudo apt install net-tools
sudo apt -y install etcd

#setup etcd proxy [HAPROXY VM]

sudo apt update
sudo hostnamectl set-hostname haproxynode
sudo apt install net-tools
sudo apt -y install haproxy

#Configure etcd on the etcdnode: 
sudo nano /etc/default/etcd

ETCD_LISTEN_PEER_URLS="http://<etcdnode_ip>:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://<etcdnode_ip>:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://<etcdnode_ip>:2380"
ETCD_INITIAL_CLUSTER="default=http://<etcdnode_ip>:2380,"
ETCD_ADVERTISE_CLIENT_URLS="http://<etcdnode_ip>:2379"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

---
ETCD_LISTEN_PEER_URLS="http://172.16.2.120:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://172.16.2.120:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.16.2.120:2380"
ETCD_INITIAL_CLUSTER="default=http://172.16.2.120:2380,"
ETCD_ADVERTISE_CLIENT_URLS="http://172.16.2.120:2379"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
---


sudo systemctl restart etcd 
sudo systemctl status etcd
curl http://<etcdnode_ip>:2380/members

#Configure Patroni on the node-1, on the node-2 and on the node-3:
sudo nano /etc/patroni.yml
---
scope: postgres
namespace: /db/
name: node-1

restapi:
    listen: <nodeN_ip>:8008
    connect_address: <nodeN_ip>:8008

etcd:
    host: <etcdnode_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <node1_ip>/0 md5
  - host replication replicator <node2_ip>/0 md5
  - host replication replicator <node3_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: <nodeN_ip>:5432
  connect_address: <nodeN_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: ************
    superuser:
      username: postgres
      password: ************
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

---

sudo mkdir -p /data/patroni

sudo chown postgres:postgres /data/patroni

sudo chmod 700 /data/patroni 

sudo vi /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ

#Start Patroni service on the node1, on the node2 and on the node3
sudo systemctl start patroni
sudo systemctl status patroni








