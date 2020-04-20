### 关掉sudo的密码
先修改默认编辑器为vim（默认为nano）:
```
sudo update-alternatives --config editor
```
输入vim对应的序号回车即可
打开 visudo:
```
sudo visudo
```
找到
```
%sudo   ALL=(ALL:ALL) ALL
```
修改为
```
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```
这样所有sudo组内的用户使用sudo时就不需要密码了.