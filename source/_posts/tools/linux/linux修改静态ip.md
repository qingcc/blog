[TOC]

# 虚拟机设置ip并与宿主机、其他虚拟机ping通

虚拟机网络设置为NAT模式

```
vim /etc/sysconfig/network-scripts/ifcfg-eth0
# 修改
BOOTPROTO=static //之前为dhcp，动态分配ip
ONBOOT=yes #(是否激活网卡)
IPADDR=192.168.33.1 #(虚拟机静态ip地址，直接设置可能该ip已被占用，可以切换到root用户使用dhclient命令来生成1个静态ip，再在这里设置该ip)
NETMASTK=255.255.255.0 #(子网掩码)
NETWORK=192.168.0.1 #（默认网关，需要和宿主机的网关相同，否则该虚拟机无法访问外网）
DNS1=0.0.0.0 #(DNS服务器)
DNS2=8.8.8.8 #(DNS服务器)
```

重启网卡：

```
systemctl restart network
```

此时，该虚拟机应该可以正常访问外网并且可以和宿主机，其他如此设置的虚拟机相互ping通.

可以通过该设置，部署集群环境，用于集群开发测试等。