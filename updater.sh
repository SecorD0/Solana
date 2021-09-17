#!/bin/bash
# $1 - Solana version
if [[ $1 ]]; then
	solana_version=$1
else
	echo -e "\033[0;31mYou didn't specify a version\e[0m"
	exit 1
fi
if [ ! -f /etc/systemd/system/sstd.service ]; then
	sudo tee <<EOF >/dev/null /etc/systemd/system/sstd.service
[Unit]
Description=Solana System Tuning
After=network.target
Before=solana.service

[Service]
User=$USER
ExecStart=$(command -v solana-sys-tuner) --user $USER
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
	sudo systemctl enable sstd
	sudo systemctl daemon-reload
fi
if ! solana --version | grep -q $solana_version; then
	solana-install init "v$solana_version"
	solana-validator --ledger $HOME/solana/ledger/ wait-for-restart-window
	sudo systemctl stop solana
	sudo systemctl restart sstd
	sudo systemctl restart solana
fi
