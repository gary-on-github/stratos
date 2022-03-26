#!/bin/bash
# Testnets.io
sudo apt update -y < "/dev/null"
sudo apt install curl -y < "/dev/null"
title="Stratos Manager"
version="Version 1.0"

function show_title {
  clear 
  # todo - only curl this once. 
  curl -s testnets.io/core/logo.sh | bash # grab testnets.io ascii logo
  printf "\n\u001b[33;1m$title - $version\e[0m\n\n"  
}

function show_feedback {
  echo -e "> \u001b[32;1m$feedback\e[0m\n"
}

prompt='Select:'
options=(
    "Stratos Testnet Installation"
    "Check Wallet"
    "Node Status"
    "Journalctl"
    "Stop Stratos Service"
    "Start Stratos Service"
    "Quit"
)

function node_install  { 

sudo rm -rf /usr/local/go
curl https://dl.google.com/go/go1.17.linux-amd64.tar.gz | sudo tar -C /usr/local -zxvf -

cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

source $HOME/.profile
sleep 1
read -p "Please enter your node ID: " node_id
echo 'Your node ID is : ' $node_id
echo 'export node_id='$node_id >> $HOME/.bash_profile
read -p "Please enter your wallet name : " wallet_name
echo 'Your wallet name is : ' $wallet_name
echo 'export node_id='$wallet_name >> $HOME/.bash_profile
source $HOME/.bash_profile

cd "$HOME" || exit
wget https://github.com/stratosnet/stratos-chain/releases/download/v0.7.0/stchaincli
wget https://github.com/stratosnet/stratos-chain/releases/download/v0.7.0/stchaind
sudo chmod +x stchaincli
sudo chmod +x stchaind

echo 'export PATH="$HOME:$PATH"' >> ~/.profile
source ~/.profile

./stchaind init $node_id

wget https://raw.githubusercontent.com/stratosnet/stratos-chain-testnet/main/tropos-3/genesis.json
wget https://raw.githubusercontent.com/stratosnet/stratos-chain-testnet/main/config.toml

mv config.toml $HOME/.stchaind/config/
mv genesis.json $HOME/.stchaind/config/

sed -i "s/"node"/$node_id/g" "$HOME/.stchaind/config/config.toml"


cd $HOME
echo '{ "height": "0", "round": "0", "step": 0 }' > .stchaind/data/priv_validator_state.json

peers="a97214289b659dca9db98963959bde117851b485@52.194.30.100:26656,92c6a339999d0ab972698f6c28b69dd134c3a834@75.119.146.247:26656,90c18307c235c456ebdc127b98de503b30994599@54.189.208.239:26656"

sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.stchaind/config/config.toml

./stchaincli keys add $wallet_name --hd-path "m/44'/606'/0'/0/0" --keyring-backend=test  
echo "Please make a note of your mnemonic and press enter once to continue"

sudo tee <<EOF >/dev/null /etc/systemd/system/stratos.service
[Unit]
Description=Stratos Chain Node
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/stchaind start --home=$HOME/.stchaind
Restart=on-failure
RestartSec=3
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
EOF

sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable stratos.service
sudo systemctl start stratos.service
echo "Stratos Testnet Instalation has Finished & Started"

}
function check_wallet   { 
cd "$HOME" || exit
source $HOME/.bash_profile
./stchaincli keys show $wallet_name --keyring-backend=test 
read -p "Press enter once to continue "
}
function node_status   { 
cd "$HOME" || exit
./stchaincli status --chain-id=tropos-2
read -p "Press enter once to continue "
}
function check_journalctl {
sudo journalctl -u stratos.service -f 
}
function stop_stratos_service { 
sudo systemctl stop stratos.service
echo "stratos Service Stoped"
sleep 1
}
function start_stratos_service   { 
sudo systemctl start stratos.service
echo "Stratos Service Started"
sleep 1
}
function quit          { 
  echo -e "Exiting ... " ; exit 
}
function not_option    { 
  echo -e "That is not an option" 
}

# set new prompt, newline is needed here. 
PS3="
$prompt" 

function show_menu {
  select option in "${options[@]}"; do
    case $REPLY in 
       1 ) node_install             ; break ;;
       2 ) check_wallet             ; break ;;
       3 ) node_status              ; break ;;
       4 ) check_journalctl         ; break ;;
       5 ) stop_stratos_service     ; break ;;
       6 ) start_stratos_service    ; break ;;
       7 ) quit                     ; break ;;
       * ) not_option               ; break ;;
    esac
  done
}

# do it once/first without feedback, 
show_title
show_menu 

while ( true ) do 
  
  sleep 2 
  show_title
  show_feedback
  show_menu  
  
done
