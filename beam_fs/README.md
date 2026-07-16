# readme

## 说明

实现的是 freeswitch 的逻辑转到 elixir

## 用法

启动

```sh
pkill -f freeswitch
freeswitch -nc -nonat
```

sip 用户登录

id 要和 username 对应

```sh
pjsua --local-port=6000 \
  --id sip:1000@10.0.2.222 \
  --registrar sip:10.0.2.222:5060 \
  --realm 10.0.2.222 \
  --username 1000 --password 123456

pjsua --local-port=6001 \
  --id sip:1001@10.0.2.222 \
  --registrar sip:10.0.2.222:5060 \
  --realm 10.0.2.222 \
  --username 1001 --password 123456
```

打电话

```sh
# 手动拨号
pjsua
# 在 1000 里：
# 给 1001 打电话
按 m, 输入 sip:1001@10.0.2.222
# 挂断
按 h
```
