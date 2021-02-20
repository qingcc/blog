# OOM killer(Out Of Memory killer)
linux下，正在运行的go程序有时会出现被系统kill的情况，出现该现象的原因是：
**程序内存上限超出后被kill掉**

 `Linux` 内核有个机制叫<font color=red>OOM killer(Out Of Memory killer)</font>，
 该机制会监控那些占用内存过大，尤其是瞬间占用内存很快的进程，然后防止内存耗尽而自动把该进程杀掉。
 
 查看被系统Kill掉的进程需要借助系统日志信息进行查看, 通常是查看`/var/log/messages` 系统日志文件
 若`/var/log/message` 文件不存在，则修改`/etc/rsyslog.d/50-default.conf` 文件 
 将  
 `#       mail,news.none          -/var/log/messages`  
 该行的`#`号删除，保存重启就会将对应的系统日志记录到`/var/log/messages`文件