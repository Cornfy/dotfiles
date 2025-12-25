# MTP.yazi

一个 Yazi 插件，用于管理 MTP 设备。

![screenshot.png](./screenshot.png "screenshot")

## 特性

-   在 Yazi 中列出已连接的 MTP 设备。
-   直接从 Yazi 挂载和卸载设备。
-   挂载后自动跳转到设备目录。

## 依赖

-   `gvfs`: 用于通过 `gio` 命令提供 MTP 支持。

## 安装

1.  将 `mtp.yazi` 文件移动到您的 Yazi 插件目录中。例如：
    ```sh
    cp -rp /path/to/mtp.yazi ~/.config/yazi/plugins/mtp.yazi
    ```

2.  在您的 `keymap.toml` 文件中添加一个按键绑定来调用此插件。

    ```toml
    # -----------------------------------------------------
    # plugin - mtp
    [[mgr.prepend_keymap]]
    on   = [ "M", "M" ]
    run  = "plugin mtp"
    desc = "MTP devices manager"
    ```

## 使用方法

启动插件后，您可以使用以下按键：

| 按键            | 功能           |
| --------------- | -------------- |
| `<Esc>` / `q`      | 退出插件       |
| `<Down>` / `j`     | 向下移动光标   |
| `<Up>` / `k`       | 向上移动光标   |
| `<Enter>` / `<Right>` / `l` | 进入已挂载的设备 |
| `m`             | 挂载设备       |
| `u`             | 卸载设备       |
