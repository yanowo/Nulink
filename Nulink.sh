#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

# Generate Geth Account
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.23-d901d853.tar.gz

tar -xvzf geth-linux-amd64-1.10.23-d901d853.tar.gz

cd geth-linux-amd64-1.10.23-d901d853/

./geth account new --keystore ./keystore
sleep 5
echo -e "\e[1;32m \e[0m\e[1;36m${CYAN} 保存好你的地址和密码 ${NC}\e[0m"
echo -e "\e[1;32m \e[0m\e[1;36m${CYAN} 保存好你的秘钥和路径 ${NC}\e[0m"
sleep 5

# Install docker

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Pull the latest NuLink image

docker pull nulink/nulink:latest
cd /root
mkdir nulink
cp /root/geth-linux-amd64-1.10.23-d901d853/keystore/* /root/nulink
chmod -R 777 /root/nulink

# Initiate Worker
read -r -p "您的NULINK存储密码.请务必记住此密码以供将来访问 : " NULINK_KEYSTORE_PASSWORD
sleep 0.5
export NULINK_KEYSTORE_PASSWORD=$NULINK_KEYSTORE_PASSWORD
sleep 0.5
read -r -p "您的员工帐户密码.请务必记住此密码以供将来访问 : " NULINK_OPERATOR_ETH_PASSWORD
sleep 0.5
export NULINK_OPERATOR_ETH_PASSWORD=$NULINK_OPERATOR_ETH_PASSWORD
sleep 0.5
echo " 您的密钥库路径 "
filename=$(basename ~/geth-linux-amd64-1.10.23-d901d853/keystore/*)
export filename1=$filename
sleep 1
echo "复制您的密钥库 "
evm=$(grep -oP '(?<="address":")[^"]+' ~/geth-linux-amd64-1.10.23-d901d853/keystore/*)
wallet='0x'$evm
export wallet1=$wallet
sleep 1

# 节点配置部署

docker run -it --rm \
-p 9151:9151 \
-v /root/nulink:/code \
-v /root/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
nulink/nulink nulink ursula init \
--signer keystore:///code/$filename1 \
--eth-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
--network horus \
--payment-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
--payment-network bsc_testnet \
--operator-address $wallet1 \
--max-gas-price 10000000000

#加载节点

docker run --restart on-failure -d \
--name ursula \
-p 9151:9151 \
-v /root/nulink:/code \
-v /root/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
-e NULINK_OPERATOR_ETH_PASSWORD \
nulink/nulink nulink ursula run --no-block-until-ready

echo '=============================== 安装完成 ==============================='
echo 启动节点: docker restart ursula
echo 检查日志 :docker logs -f ursula
