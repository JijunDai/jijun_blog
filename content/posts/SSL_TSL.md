---
title: "SSL TSL"
author: "Jijun Dai"
date: 2022-12-10T02:35:45-05:00
categories:
- Development
tags:
- security
---

#### SSL/TLS

[openssl](http://www.openssl.org/docs/apps/openssl.html) 工具的 `s_client` 命令会查看 Wikipedia 的服务器证书信息。它指定端口 443，因为这是 HTTPS 的默认端口。该命令将 `openssl s_client` 的输出发送到 `openssl x509`，后者将根据 [X.509 标准](http://en.wikipedia.org/wiki/X.509)设置证书相关信息的格式。具体而言，该命令会请求主题（包含服务器名称信息）和颁发机构（用来标识 CA）。

```
    $ openssl s_client -connect wikipedia.org:443 | openssl x509 -noout -subject -issuer
    subject= /serialNumber=sOrr2rKpMVP70Z6E9BT5reY008SJEdYv/C=US/O=*.wikipedia.org/OU=GT03314600/OU=See www.rapidssl.com/resources/cps (c)11/OU=Domain Control Validated - RapidSSL(R)/CN=*.wikipedia.org
    issuer= /C=US/O=GeoTrust, Inc./CN=RapidSSL CA
```

看到证书是由 RapidSSL CA 为与 *.wikipedia.org 匹配的服务器颁发的。

```text
我们假设A与B通信，A是SSL客户端，B是SSL服务器端，加密后的消息放在方括号[]里，以突出明文消息的区别。双方的处理动作的说明用圆括号（）括起。
```

```
A：我想和你安全的通话，我这里的对称加密算法有DES,RC5,密钥交换算法有RSA和DH，摘要算法有MD5和SHA。
B：我们用DES－RSA－SHA这对组合好了。这是我的证书，里面有我的名字和公钥，你拿去验证一下我的身份（把证书发给A）。目前没有别的可说的了。
A：（查看证书上B的名字是否无误，并通过手头早已有的CA的证书验证了B的证书的真实性，如果其中一项有误，发出警告并断开连接，这一步保证了B的公钥的真实性）产生一份秘密消息，这份秘密消息处理后将用作加密密钥，加密初始化向量和hmac的密钥。将这份秘密消息-协议中称为per_master_secret-用B的公钥加密，封装成称作ClientKeyExchange的消息。由于用了B的公钥，保证了第三方无法窃听）
我生成了一份秘密消息，并用你的公钥加密了，给你（把ClientKeyExchange发给B）
注意，下面我就要用加密的办法给你发消息了！
（将秘密消息进行处理，生成加密密钥，加密初始化向量和hmac的密钥）
[我说完了]
B：（用自己的私钥将ClientKeyExchange中的秘密消息解密出来，然后将秘密消息进行处理，生成加密密钥，加密初始化向量和hmac的密钥，这时双方已经安全的协商出一套加密办法了）
注意，我也要开始用加密的办法给你发消息了！
[我说完了]
A: [我的秘密是…]
B: [其它人不会听到的…]
```

#### How to create a self-signed SSL Certificate

##### **Step 1: Generate a Private Key**

The **openssl** toolkit is used to generate an **RSA Private Key** and **CSR (Certificate Signing Request)**. It can also be used to generate self-signed certificates which can be used for testing purposes or internal usage.

The first step is to create your RSA Private Key. This key is a 2048 bit RSA key which is encrypted using Triple-DES and stored in a PEM format so that it is readable as ASCII text.

`openssl genrsa -des3 -out server.key 2048`

##### **Step 2: Remove Passphrase from Key**

**It is possible to remove the Triple-DES encryption from the key**, thereby no longer needing to type in a pass-phrase. If the private key is no longer encrypted, it is critical that this file only be readable by the root user!

```
cp server.key server.pass.key
openssl rsa -in server.pass.key -out server.key
```

##### **Step 3: Generate a CSR (Certificate Signing Request)**

Once the private key is generated a Certificate Signing Request can be generated. The CSR is then used in one of two ways. Ideally, the CSR will be sent to a Certificate Authority, such as Thawte or Verisign who will verify the identity of the requestor and issue a signed certificate. **The second option is to self-sign the CSR, which will be demonstrated in the next section**.

During the generation of the CSR, you will be prompted for several pieces of information. These are the X.509 attributes of the certificate. One of the prompts will be for "Common Name". It is important that this field be filled in with the ***fully qualified domain name***(FQDN) of the server to be protected by SSL. If the website to be protected will be **mtl-w-0012599.mgcorp.co**, then enter mtl-w-*0012599.mgcorp.co* at this prompt.

`openssl req -new -key server.key -out server.csr -subj "/C=CA/ST=QC/L=mtl/O=mg/OU=p1/CN=mtl-w-0012599.mgcorp.co"`

| segment | meaning                         | example  |
| :------ | :------------------------------ | :------- |
| /C=     | Country                         | CN       |
| /ST=    | State or Province               | Shanghai |
| /L=     | Location or City                | Shanghai |
| /O=     | Organization                    | cetc     |
| /OU=    | Organization Unit               | wlst     |
| /CN=    | (Common Name) domain name or IP | wlst.com |

##### **Step 4: Generating a Self-Signed Certificate**

`openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt`

##### **Step 5:  Test**

If there is no DNS service, modify hosts file first.

`https://mtl-w-0012599.mgcorp.co`
