# 用來從訂閱 URL 生成 sing-box 訂閱的腳本集

- `update.sh` 用來更新訂閱並生成 `sing-box` 的出站配置，請把訂閱信息填到 `conf/subs.json`
- `test.sh` 使用訂閱名稱作為參數，測試訂閱中節點的 URL 延時，並保存在訂閱目錄下的`tested.txt`裡
- `chsing.sh｀ 從標準輸入讀取一個 sing-box 配置，將其出站與 `/etc/sing-box/config_base.json` 放入 `/etc/sing-box/config.json`，只起到切換出站的作用，改動配置則請改動模版文件

## 示例
```shell
$ ./update.sh all #先更新訂閱
$ ./test.sh XXXX #測試延遲
$ cat subs/ABC/DEF.json | sudo chsing #從寫好的模版生成配置文件
$ systemctl start sing-box #啓動 sing-box
```