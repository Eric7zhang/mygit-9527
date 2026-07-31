export REDIS_PASSWORD=C1bsfm_A

docker run -d \
--name redis1 \
-p 16379:6379 \
-e REDIS_PASSWORD=${REDIS_PASSWORD} \
redis:latest \
redis-server \
--requirepass ${REDIS_PASSWORD} \
--masterauth ${REDIS_PASSWORD} \
--cluster-enabled yes \
--cluster-node-timeout 5000 \
--appendonly yes

docker run -d \
--name redis2 \
-p 26379:6379 \
-e REDIS_PASSWORD=${REDIS_PASSWORD} \
redis:latest \
redis-server \
--requirepass ${REDIS_PASSWORD} \
--masterauth ${REDIS_PASSWORD} \
--cluster-enabled yes \
--cluster-config-file nodes.conf \
--cluster-node-timeout 5000 \
--appendonly yes

docker run -d \
--name redis3 \
-p 36379:6379 \
-e REDIS_PASSWORD=${REDIS_PASSWORD} \
redis:latest \
redis-server \
--requirepass ${REDIS_PASSWORD} \
--masterauth ${REDIS_PASSWORD} \
--cluster-enabled yes \
--cluster-config-file nodes.conf \
--cluster-node-timeout 5000 \
--appendonly yes

docker run -d \
--name redis4 \
-p 46379:6379 \
-e REDIS_PASSWORD=${REDIS_PASSWORD} \
redis:latest \
redis-server \
--requirepass ${REDIS_PASSWORD} \
--masterauth ${REDIS_PASSWORD} \
--cluster-enabled yes \
--cluster-config-file nodes.conf \
--cluster-node-timeout 5000 \
--appendonly yes


docker run -d \
--name redis5 \
-p 56379:6379 \
-e REDIS_PASSWORD=${REDIS_PASSWORD} \
redis:latest \
redis-server \
--requirepass ${REDIS_PASSWORD} \
--masterauth ${REDIS_PASSWORD} \
--cluster-enabled yes \
--cluster-config-file nodes.conf \
--cluster-node-timeout 5000 \
--appendonly yes

docker run -d \
--name redis6 \
-p 16380:6379 \
-e REDIS_PASSWORD=${REDIS_PASSWORD} \
redis:latest \
redis-server \
--requirepass ${REDIS_PASSWORD} \
--masterauth ${REDIS_PASSWORD} \
--cluster-enabled yes \
--cluster-config-file nodes.conf \
--cluster-node-timeout 5000 \
--appendonly yes


docker exec -it redis1 redis-cli -a C1bsfm_A
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
127.0.0.1:6379> config get cluster-enabled
1) "cluster-enabled"
2) "yes"


for i in redis1 redis2 redis3 redis4 redis5 redis6; do
  echo -n "$i -> "
  docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i
done
redis1 -> 172.18.0.2
redis2 -> 172.18.0.3
redis3 -> 172.18.0.4
redis4 -> 172.18.0.5
redis5 -> 172.18.0.6
redis6 -> 172.18.0.7


docker exec -it redis1 bash
redis-cli -a ${REDIS_PASSWORD} --cluster create \
172.17.0.2:6379 \
172.17.0.5:6379 \
172.17.0.4:6379 \
172.17.0.6:6379 \
172.17.0.7:6379 \
172.17.0.8:6379 \
--cluster-replicas 1

Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 172.18.0.6:6379 to 172.18.0.2:6379
Adding replica 172.18.0.7:6379 to 172.18.0.3:6379
Adding replica 172.18.0.5:6379 to 172.18.0.4:6379
M: 5dfd59213c9af1b694075d2d048275ce9845b9ea 172.18.0.2:6379
   slots:[0-5460] (5461 slots) master
M: 361024df53ea5e60be7e6ebbbcc6355e11af7246 172.18.0.3:6379
   slots:[5461-10922] (5462 slots) master
M: 8cf25f6ca8d62d55d0ee9515ee3430d09b3e9e38 172.18.0.4:6379
   slots:[10923-16383] (5461 slots) master
S: 1926ce4ca7d73370bfce3a590be26c179b3ee24d 172.18.0.5:6379
   replicates 8cf25f6ca8d62d55d0ee9515ee3430d09b3e9e38
S: af18bfa807a5b590702447b9eb370acd9e1197ef 172.18.0.6:6379
   replicates 5dfd59213c9af1b694075d2d048275ce9845b9ea
S: 18e88dffd0409535eaac2012bd85978862b314b1 172.18.0.7:6379
   replicates 361024df53ea5e60be7e6ebbbcc6355e11af7246
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
.
>>> Performing Cluster Check (using node 172.18.0.2:6379)
M: 5dfd59213c9af1b694075d2d048275ce9845b9ea 172.18.0.2:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: 361024df53ea5e60be7e6ebbbcc6355e11af7246 172.18.0.3:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: 8cf25f6ca8d62d55d0ee9515ee3430d09b3e9e38 172.18.0.4:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 18e88dffd0409535eaac2012bd85978862b314b1 172.18.0.7:6379
   slots: (0 slots) slave
   replicates 361024df53ea5e60be7e6ebbbcc6355e11af7246
S: 1926ce4ca7d73370bfce3a590be26c179b3ee24d 172.18.0.5:6379
   slots: (0 slots) slave
   replicates 8cf25f6ca8d62d55d0ee9515ee3430d09b3e9e38
S: af18bfa807a5b590702447b9eb370acd9e1197ef 172.18.0.6:6379
   slots: (0 slots) slave
   replicates 5dfd59213c9af1b694075d2d048275ce9845b9ea
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.



