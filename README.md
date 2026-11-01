# CFH-DEVKIT 吊销名单（revocations）

这个仓库只放一个文件：`revocations.json` —— 钢四开发者套件的**激活码吊销名单**。

## 内容与安全

- `revoked` 数组里是被吊销的激活码 lid（泄露/退款时加入）；
- **这里没有任何机密**：lid 是已作废许可证的编号，公开无害；
- 签发私钥在本机 `secrets/`，**永远不会**出现在这个仓库。

## 日常维护（泄露发生时）

1. 本机执行：
   ```
   python sign_license.py --revoke <lid>
   python sign_license.py --export-revocations revocations.json
   ```
2. 把生成的 `revocations.json` 内容覆盖到本仓库同名文件，提交。
3. 客户下次启动程序时自动生效（有 5 秒超时，断网用本地缓存）。

> 格式：`{"updated": "...", "app": "CFH-DEVKIT", "revoked": ["lid", ...]}`
> 程序只读 `revoked` 数组，其余字段供人看。
