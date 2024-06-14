## TestNet 资产管理系统介绍
<div align="center">

简体中文 / [English](./README.md)

</div>
TestNet资产管理系统旨在提供全面、高效的互联网资产管理与监控服务，构建详细的资产信息库。该系统能够帮助企业安全团队或渗透测试人员对目标资产进行深入侦察和分析，提供攻击者视角的持续风险监测，协助用户实时掌握资产动态，识别并修复安全漏洞，从而有效收敛攻击面，提升整体安全防护能力。

### 目前功能

- [X] 项目管理
- [X] 资产管理（公司、域名、子域名、IP、端口、Web、API、漏洞、资产标签、黑名单等）
- [X] 资产导入导出
- [X] 高级搜索
- [X] 扫描脚本定制
- [X] 批量扫描 & 定时任务
- [X] 节点配置自定义

**自带工具的脚本，也可以根据需要加入其他工具：**

- [X] 子域名扫描（OneForAll、subfinder）
- [X] 端口扫描（Nmap、Naabu）
- [X] Web探测（Httpx）
- [X] 漏洞扫描（Nuclei）
- [X] DNS解析（CDN及存活判断）
- [X] 敏感目录扫描（DirSearch）
- [X] ICP备案查询
- [X] 0.zone API调用

#### 快速开始

### 1、 **快速安装**
### Linux和Mac

```bash
git clone https://github.com/testnet0/testnet.git
cd testnet && bash build.sh
```
稍等片刻，即可启动系统。默认访问端口为 `IP:80`
### Windows
 参考帮助文档

### 2、 **默认密码**
   - **安全测试**：`TestNet/TestNet123@`
   - **管理员**：`admin/123456`

### 3、系统界面
![](https://raw.githubusercontent.com/testnet0/testnet/main/doc/img/dashboard.png)

### 4、联系我们
- 微信群：
  ![](https://raw.githubusercontent.com/testnet0/testnet/main/doc/img/wechat.png)
### 详细文档链接

- [TestNet 资产管理系统帮助文档](https://www.yuque.com/testnet-niqki/etr5ls)
