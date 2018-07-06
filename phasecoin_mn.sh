echo "=================================================================="
echo "phasecoin MN Install"
echo "=================================================================="

#read -p 'Enter your masternode genkey you created in windows, then hit [ENTER]: ' GENKEY

echo "Installing packages and updates..."
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install nano -y
sudo apt-get install pwgen -y
sudo apt-get install dnsutils -y
sudo apt-get install software-properties-common -y
sudo apt-get install build-essential libtool autotools-dev pkg-config libssl-dev -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install libevent-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install autoconf -y
sudo apt-get install automake -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

echo "Packages complete..."

WALLET_VERSION='2.0.0'
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PORT='17817'
RPCPORT='17866'
PASSWORD=`pwgen -1 20 -n`
if [ "x$PASSWORD" = "x" ]; then
    PASSWORD=${WANIP}-`date +%s`
fi

#begin optional swap section
echo "Setting up disk swap..."
free -h
sudo fallocate -l 4G /swapfile
ls -lh /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h
echo "SWAP setup complete..."
#end optional swap section

wget https://github.com/phaseproject/phase/releases/download/2.1.0.2/phase_2.1.0_linux.tar.gz

rm -rf phase
tar -zxvf phase_2.1.0_linux.tar.gz
mv phase_2.1.0_linux phase

echo "Loading and syncing wallet"

echo "If you see *error: Could not locate RPC credentials* message, do not worry"
~/phase/phase-cli stop
sleep 10
echo ""
echo "=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT 5 MINUTES UNTIL YOU SEE THE RELOADING WALLET MESSAGE"
echo "=================================================================="
echo ""
~/phase/phased -daemon
sleep 250
~/phase/phase-cli stop
sleep 20

cat <<EOF > ~/.phasecore/phase.conf
rpcuser=phasecoin
rpcpassword=${PASSWORD}
EOF

echo "Reloading wallet..."
~/phase/phased -daemon
sleep 30

echo "Making genkey..."
GENKEY=$(~/phase/phase-cli masternode genkey)

echo "Mining info..."
~/phase/phase-cli getmininginfo
~/phase/phase-cli stop

echo "Creating final config..."

cat <<EOF > ~/.phasecore/phase.conf
rpcuser=phasecoin
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
server=1
daemon=1
listen=1
rpcport=${RPCPORT}
port=${PORT}
externalip=$WANIP
maxconnections=256
masternode=1
masternodeprivkey=$GENKEY
addnode=80.211.25.138
addnode=104.10.207.74
addnode=24.228.90.13
EOF

#echo "Setting basic security..."
#sudo apt-get install systemd -y
#sudo apt-get install fail2ban -y
#sudo apt-get install ufw -y
#sudo apt-get update -y

#fail2ban:
#sudo systemctl enable fail2ban
#sudo systemctl start fail2ban

#add a firewall
#sudo ufw default allow outgoing
#sudo ufw default deny incoming
#sudo ufw allow ssh/tcp
#sudo ufw limit ssh/tcp
#sudo ufw allow 17866/tcp
#sudo ufw allow 17817/tcp
#sudo ufw logging on
#sudo ufw status
#echo y | sudo ufw enable
#echo "Basic security completed..."

echo "Restarting wallet with new configs, 30 seconds..."
~/phase/phased -daemon
sleep 30

echo "Installing sentinel..."
cd /root/.phasecore
sudo apt-get install -y git python-virtualenv

sudo git clone https://github.com/phaseproject/phase_sentinel.git

cd phase_sentinel

export LC_ALL=C
sudo apt-get install -y virtualenv

virtualenv ./venv
./venv/bin/pip install -r requirements.txt

echo "phase_conf=/root/.phasecore/phase.conf" >> /root/.phasecore/phase_sentinel/sentinel.conf

echo "Adding crontab jobs..."
crontab -l > tempcron
#echo new cron into cron file
echo "* * * * * cd /root/.phasecore/phase_sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> tempcron
echo "@reboot /bin/sleep 20 ; /root/phase/phased -daemon &" >> tempcron

#install new cron file
crontab tempcron
rm tempcron

SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py
echo "Sentinel Installed"

echo "phase-cli getmininginfo:"
~/phase/phase-cli getmininginfo

sleep 15

echo "Masternode status:"
~/phase/phase-cli masternode status

echo "If you get \"Masternode not in masternode list\" status, don't worry, you just have to start your MN from your local wallet and the status will change"
echo ""
echo "INSTALLED WITH VPS IP: $WANIP:$PORT"
sleep 1
echo "INSTALLED WITH MASTERNODE PRIVATE GENKEY: $GENKEY"
sleep 1
echo "rpcuser=phasecoin"
echo "rpcpassword=$PASSWORD"
