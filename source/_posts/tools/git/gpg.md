#gpg

[原文链接](https://blog.ichr.me/post/use-gpg-verification-in-github/)

GPG的功能十分丰富，一般主要是用它来对Git中的commit进行签名验证。
需要做的事情也不算太复杂：

1. 生成自己的GPG密钥
2. 关联GPG公钥与Github账户
3. 设置利用GPG私钥对commit进行签名
4. 可选步骤：信任Github的GPG密钥

## 安装GPG
由于我的目的是在Git中使用GPG，而Windows版本的Git发行包中，已经包含了可用的GPG命令行。
判断方法也很简单，打开Git Bash，输入gpg --version，可以看到类似的GPG版本信息：

```shell script
gpg --version
```

不过需要说明的是，如果所安装的Git版本比较久远（比如我一开始所用的Git发行包是2017年的），
那么很可能其包含的GPG版本过低，影响后续的操作，建议直接更新所安装的Git发行。

## 生成自己的GPG密钥
打开Git Bash，运行`gpg --full-generate-key`，根据提示，输入相应的个人信息
（**需要注意的是邮箱必须要使用在Github中验证过的邮箱**）、自定义密钥参数、设置私钥密码等等，
即可生成自己的GPG密钥。（补充说明，使用`gpg --gen-key`亦可生成密钥，但是会略去自定义密钥参数
的步骤，对于一般场合的使用问题不大。）

输出结果的末尾大致如下：
```shell script
# output
gpg: key 9547D1DFE3A6578A marked as ultimately trusted
gpg: directory '/c/Users/Administrator/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/c/Users/Administrator/.gnupg/openpgp-revocs.d/BE28B8CE7247FBE00F3794B59547D1DFE3A6578A.rev'
public and secret key created and signed.

pub   rsa2048 2021-03-24 [SC] [expires: 2023-03-24]
      BE28B8CE7247FBE00F3794B59547D1DFE3A6578A
uid                      QingTian <qingcc0503@163.com>
sub   rsa2048 2021-03-24 [E] [expires: 2023-03-24]
```
需要记下的，是上述输出信息中的密钥ID：`BE28B8CE7247FBE00F3794B59547D1DFE3A6578A` 
或者`9547D1DFE3A6578A`，后者是前者的简短形式。

当然，如果没有及时将其记下也不要紧，可以运行`gpg --list-keys`，列出本地存储的所有GPG密钥信息，大致如下：
```shell script
$ gpg --list-keys
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2023-03-24
/c/Users/Administrator/.gnupg/pubring.kbx
-----------------------------------------
pub   rsa2048 2021-03-24 [SC] [expires: 2023-03-24]
      BE28B8CE7247FBE00F3794B59547D1DFE3A6578A
uid           [ultimate] QingTian <qingcc0503@163.com>
sub   rsa2048 2021-03-24 [E] [expires: 2023-03-24]
```
稍微解读一下这些结果：

- `pub`其后的是该密钥的公钥特征，包括了密钥的参数（加密算法是rsa，长度为2048，生成于2019-08-04，用途是Signing和Certificating，一年之后过期）以及密钥的ID。
- `uid`其后的是生成密钥时所输入的个人信息。
- `sub`其后的则是该密钥的子密钥特征，格式和公钥部分大致相同（E表示用途是Encrypting）。

关联GPG公钥与Github账户
还记得在上一步中记下的密钥ID吗？现在，我们需要根据这个ID来导出对应GPG密钥的公钥字符串。
继续在Git Bash中，运行命令`gpg --armor --export {key_id}`:

```shell script
$ gpg --armor --export BE28B8CE7247FBE00F3794B59547D1DFE3A6578A
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGBa+lIBCACV3TiKzHxsmIvOpp+KygWhl95YFPJUPov57s3JH604vt2S1CmA
a4fvcixqQuz2bdVr7K75ca5RxX15A1ow9G5i6ZruO4Mi+MXWARzgAUyZmmenAR2G
6wbl4TYzVu3MEXXtoN5pxQQ/UmlhbKFi2WscNEnBYUzc6pougaMejOL6QpkM5XaU
aDmFrctWjjwPWdzbrv4ggLWOPm/ckquPQGxLs00wpBGMMyuuoe5qPyAaNLEdRgOs
+mB3H37C7MikLtyDw6qUE+kZ5ctaT4GobcLcFnOLrxU+/FTir3cOkBNQUyO8Yuh1
gGRl/vFUS8DuYQbChCpLlK7R6VV85zOcOrnRABEBAAG0HVFpbmdUaWFuIDxxaW5n
Y2MwNTAzQDE2My5jb20+iQFUBBMBCAA+FiEEvii4znJH++APN5S1lUfR3+OmV4oF
AmBa+lICGwMFCQPCZwAFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AACgkQlUfR3+Om
V4oFTwf+I8I0Fo5m+tP9mjWZc/1+dHo7F/UTp7lfzyFcJoUXCQG+Q0NIrqX5L5jt
KSaT9qlbH/TAg0ENMFhHxRJz/ckq3EPVfv78a+7l7IFrJmM3Y8M7UlLh5W2yYMQh
DB9rOnLH2VDVt2R/zRszp9bYSZLk3Z1smogR/s9JC0lANhBP+6NUcICXMzzCjojx
J2lGfZb53jw+jIMBUk84WkFReCc+31EY+Z7XsbpO/UIPI4OixbVNUxhpre0t8RZP
pRdIeVXXRuLYngwyKN6O+ZwLk+MwCk8Sjfz7KkUhUiYZ7wp66F6ByAZ7S761lr7C
+TwL59sDPMf8jIEEY6XZlG7vAe4X5rkBDQRgWvpSAQgA2XNFzBX0orU6XvGXjAjp
WAE1x9dsws1r4E87BPCTtrbDKbSu1Wh3eIVh3yISBAsugF5UHcY8eFZVrJBrPgph
VxEms54urEtXobitsV24WrXHRR6m+pRJHApSZDS9uI74Ae7fWc+zvaezQSTY6E2R
ubn8sDlrP1Fv31B0mvsPdeQuObUwaGA6KUBV2NjqbwbAUIuv0YM1hsu2txjCGFXj
e9G77B02msM+yXXsbv4lAWmdebj+chux9MH1e1jeZXbz9hwZANAwIHUK1POI+qMz
bMUbJ33CgYcmUIYrdoF4yRSTelLNpqzs83hZB1Ne6KJosRkSaNypTYbP+apBijhz
VQARAQABiQE8BBgBCAAmFiEEvii4znJH++APN5S1lUfR3+OmV4oFAmBa+lICGwwF
CQPCZwAACgkQlUfR3+OmV4oybAf/eeA7W213x6lrBSIHxL3XXzFNKaGYqkt4R9WY
bkXMCDVMyssbWjag5RT8lmjAQwrBMrufum/+5G322/s7iIQ/8utYPbZ5nK7f8V/6
b5NMek1DyPnVtMGTD1ulvF5vbxqQuAlQk2ehMNefnNvCgL8l5MJRagh8jA4Fygay
Y6YdxBwQeLgIwrHKt6kRi7fDyQujswB+pGi1FpjFK9e5nukg+NxxAgGW17/hpi9Y
tYznCwG29RcaDZacgsfq87w9+uluLxx4soXmU7NQ9uxpC1PFmdMA/r1LkuE+VsXs
E4qTr89gHy49P1B5f8EaaCOVbC0ApZW2UoTFuXeWIwCuqdNoHA==
=ESel
-----END PGP PUBLIC KEY BLOCK-----
```
然后，在Github的SSH and GPG keys中，新增一个GPG key，内容即是上述命令的输出结果。

再次提醒，GPG密钥中个人信息的邮箱部分，必须使用在Github中验证过的邮箱，否则添加GPG key会提示未经验证。

## 利用GPG私钥对Git commit进行签名
首先，需要让Git知道签名所用的GPG密钥ID：
```shell script
git config --global user.signingkey {key_id}
```
然后，在每次commit的时候，加上-S参数，表示这次提交需要用GPG密钥进行签名：
```shell script
git commit -S -m "..."
```
如果觉得每次都需要手动加上-S有些麻烦，可以设置Git为每次commit自动要求签名：
```shell script
git config --global commit.gpgsign true
```
但不论是否需要手动加上-S，commit时皆会弹出对话框，需要输入该密钥的密码，以确保是密钥拥有者本人操作。

输入正确密码后，本次commit便被签名验证，push到Github远程仓库后，即可显示出Verified绿色标记

## 密钥的导入与导出
如果你有多台设备使用需求，使用同一个 GPG key 会免去许多不必要的麻烦。

### 以文件形式导出
上面导入 GitHub 的时候介绍了可以将公 / 私钥打印到终端里，自然也是可以以文件形式保存下来，方便转移。

在终端中输入命令：
```shell script
gpg --armor --output GPGtest_pub.gpg --export {key ID}
gpg --armor --output GPGtest-sec.gpg --export-secret-key {key ID}
```
这样你就在终端的启动路径下得到了两个 GPG 文件，请妥善保管。

### 从 GPG 文件中导入
如果你手头上有 GPG 文件，导入也颇为简单。终端中输入：
```shell script
gpg --import GPGtest_pub.gpg
gpg --allow-secret-key-import --import GPGtest-sec.gpg
```
注意将文件名和路径改为自己的。

## 信任Github的GPG密钥
其实当你完成上面步骤后已经能十分灵活地使用 GPG 了。但是一些在网页端的操作是由 GitHub 代之签名的，这些操作我们还是无法确定其真实性。

这时候我们需要上传并信任 GitHub 密钥。
```shell script
curl https://github.com/web-flow.gpg | gpg --import
```
然后当然是选择相信他~（用自己的签名为其验证）
```shell script
gpg --sign-key {key ID}
```
这样你在网页端进行的操作也都是经过验证的了。（但是你的 GitHub 账号密码泄露了就……）


一番操作后，你的 Commit 终于得到了 Verified 标记，他人想伪造你也变得不再那么可信了。
但是 GPG 能做到的远不止如此，还有许多功能值得我们去学习、去深究。