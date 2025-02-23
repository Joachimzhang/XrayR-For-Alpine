#!/bin/sh

# 发送欢迎消息
echo "XrayR一键安装脚本"
echo "仅支持Alpine amd64架构"
echo "安装目录位于 /etc/XrayR"
echo "进程保活采用screen方式"
echo "请选择:"
echo "1:安装XrayR"
echo "2:卸载XrayR"
echo "3:启动XrayR"
echo "4:停止XrayR"
echo "5:重启XrayR"
echo "6:快速配置XrayR（实验性）"
echo "7:退出脚本"

# 检查脚本是否以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo "必须使用root用户运行此脚本！"
    exit 1
fi

# 定义安装XrayR的函数
install_xrayr() {
    # 检查一下必要的软件包是否安装
    if ! command -v sudo >/dev/null 2>&1; then
        apk add sudo
    fi
    if ! command -v wget >/dev/null 2>&1; then
        apk add wget
    fi
    if ! command -v curl >/dev/null 2>&1; then
        apk add curl
    fi
    if ! command -v unzip >/dev/null 2>&1; then
        apk add unzip
    fi
    if ! command -v screen >/dev/null 2>&1; then
        apk add screen
    fi
    
    # 检查 /etc/XrayR 目录是否存在
    if [ -d "/etc/XrayR" ]; then
        echo "已存在文件夹，可能已经安装过了XrayR"
        exit 1
    fi

    # 检查系统是否为Alpine
    if ! grep -qi "Alpine" /etc/os-release; then
        echo "请使用Alpine系统运行此脚本"
        exit 1
    fi

    # 检查系统架构是否为amd64
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "该脚本暂只支持amd64架构"
        exit 1
    fi

    # 切换到 /etc 目录
    cd /etc

    # 开始下载XrayR，先检测版本，再创建目录，再进行安装
    last_version=$(curl -Ls "https://api.github.com/repos/wyx2685/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$last_version" ]; then
        echo "检测 XrayR 版本失败，请稍后再试"
        exit 1
    fi

    mkdir XrayR
    cd XrayR
    wget -N --no-check-certificate "https://github.com/wyx2685/XrayR/releases/download/${last_version}/XrayR-linux-64.zip"
    unzip XrayR-linux-64.zip
    chmod 777 XrayR

    if [ $? -eq 0 ]; then
        echo "XrayR已安装完成，请先配置好配置文件后再启动"
    else
        echo "XrayR安装失败"
    fi

    exit 0
}

# 根据用户选择执行相应操作
read -p "请输入选项: " option

case "$option" in
    "1")
        install_xrayr
        ;;
    "2")
        if [ ! -d "/etc/XrayR" ]; then
            echo "你还未安装XrayR"
            exit 1
        fi

        screen -wipe
        screen -S xrayr -X quit
        rm -r /etc/XrayR

        echo "XrayR卸载成功"
        exit 0
        ;;
    "3")
        if [ ! -d "/etc/XrayR" ]; then
            echo "你似乎并未安装XrayR"
            exit 1
        fi

        if screen -list | grep -q "xrayr"; then
            echo "你已经启动过了XrayR"
            exit 1
        fi

        cd /etc/XrayR
        screen -dmS xrayr ./XrayR

        echo "XrayR启动成功"
        exit 0
        ;;
    "4")
        screen -wipe
        screen -S xrayr -X quit

        echo "XrayR停止成功"
        exit 0
        ;;
    "5")
        if [ ! -d "/etc/XrayR" ]; then
            echo "你似乎并未安装XrayR"
            exit 1
        fi
    
        screen -wipe
        screen -S xrayr -X quit
        cd /etc/XrayR
        screen -dmS xrayr ./XrayR
        
        echo "XrayR重启成功"
        exit 0
        ;;
    "6")
        if [ ! -d "/etc/XrayR" ]; then
            echo "你似乎并未安装XrayR"
            exit 1
        fi
        
        if [ ! -f "/etc/XrayR/config.yml" ]; then
            echo "XrayR配置文件不存在，你还没有安装XrayR或配置文件丢失！"
            exit 1
        fi
        
        echo "请注意，此为实验性功能，若出问题请手动修改配置文件"
        echo ""
        echo "面板类型默认设置为V2board，自动进行下一步"
        echo ""
        
        # 设定机场地址
        echo "设定机场地址"
        echo ""
        read -p "请输入你的机场地址:" apihost
        [ -z "${apihost}" ]
        echo "---------------------------"
        echo "您设定的机场网址为 ${apihost}"
        echo "---------------------------"
        echo ""
        
        
        # 设定API Key
        echo "设定与面板对接的API Key"
        echo ""
        read -p "请输入API Key:" apikey
        [ -z "${apikey}" ]
        echo "---------------------------"
        echo "您设定的API Key为 ${apikey}"
        echo "---------------------------"
        echo ""
    
        # 设置节点序号
        echo "设定节点序号"
        echo ""
        read -p "请输入V2Board中的节点序号:" node_id
        [ -z "${node_id}" ]
        echo "---------------------------"
        echo "您设定的节点序号为 ${node_id}"
        echo "---------------------------"
        echo ""

        # 选择协议
        echo "选择节点类型(默认Shadowsocks)"
        echo ""
        read -p "请输入你使用的协议(V2ray, Shadowsocks, Trojan):" node_type
        [ -z "${node_type}" ]
    
        # 如果不输入默认为Shadowsocks
        if [ ! $node_type ]; then 
        node_type="Shadowsocks"
        fi

        echo "---------------------------"
        echo "您选择的协议为 ${node_type}"
        echo "---------------------------"
        echo ""

        # 输入域名（Trojan证书申请）
        echo "输入你的域名（Trojan证书申请）"
        echo ""
        read -p "请输入你的域名(node.v2board.com)如无需证书请直接回车:" node_domain
        [ -z "${node_domain}" ]

        # 如果不输入默认为node1.v2board.com
        if [ ! $node_domain ]; then 
        node_domain="node.v2board.com"
        fi

        # 写入配置文件
        echo "正在尝试写入配置文件..."
        sed -i "s/PanelType:.*/PanelType: \"V2board\"/g" /etc/XrayR/config.yml
        sed -i "s,ApiHost:.*,ApiHost: \"${apihost}\",g" /etc/XrayR/config.yml
        sed -i "s/ApiKey:.*/ApiKey: ${apikey}/g" /etc/XrayR/config.yml
        sed -i "s/NodeID:.*/NodeID: ${node_id}/g" /etc/XrayR/config.yml
        sed -i "s/NodeType:.*/NodeType: ${node_type}/g" /etc/XrayR/config.yml
        sed -i "s/CertDomain:.*/CertDomain: \"${node_domain}\"/g" /etc/XrayR/config.yml
        echo ""
        echo "写入完成，正在尝试重启XrayR服务..."
        echo
        screen -wipe
        screen -S xrayr -X quit
        cd /etc/XrayR
        screen -dmS xrayr ./XrayR
        
        echo "XrayR服务已经完成重启，请愉快地享用！"
        echo
        exit 0
        ;;
    "7")
        echo "已退出脚本"
        exit 0
        ;;
    *)
        if [ -n "$option" ]; then
            echo "无效的选择"
        fi
        exit 1
        ;;
esac
