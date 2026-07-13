# ip

## 说明

多网卡的情况下，需要指定 ip

local_ip_v4 是 freeswitch 自动检测的，无法指定。

## 配置

```sh
/usr/local/etc/freeswitch/vars.xml
```

```xml
<X-PRE-PROCESS cmd="set" data="erlang_bind_ip=10.0.2.1"/>
<X-PRE-PROCESS cmd="set" data="domain=$${erlang_bind_ip}"/>
```

```sh
/usr/local/etc/freeswitch/sip_profiles/internal.xml
```

```xml
<param name="rtp-ip" value="$${erlang_bind_ip}"/>
<param name="sip-ip" value="$${erlang_bind_ip}"/>
```
