docker exec -it kylinV10 /bin/bash # 进入kylin容器内部，执行bash命令

docker run -d --name kylinV10 kylinv10/kylin:b09 tail -f /dev/null #创建并启动kylinV10容器，并让容器持续运行


#docker destop Engine的daemon.json配置文件内容如下：
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1ms.run"
  ]
}

