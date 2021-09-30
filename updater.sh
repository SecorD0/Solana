#!/bin/bash
# Default variables
current_version="false"
mainnet="false"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script unpdates Solana node"
		echo
		echo -e "${C_R}Creators aren't responsible for the script usage, so you use it at your own risk${RES}"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help             show the help page"
		echo -e "  -v,  --version VERSION  Solana node VERSION to update (default is ${C_LGn}current version${RES})"
		echo -e "  -cv, --current-version  show current version"
		echo -e "  -m,  --mainnet          use the script for mainnet node"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/updater.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0; exit 0
		;;
	-v*|--version*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		solana_version=`option_value "$1"`
		shift
		;;
	-cv|--current-version)
		current_version="true"
		shift
		;;
	-m|--mainnet)
		mainnet="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done
# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
# Actions
if [ "$mainnet" = "true" ]; then
	solana_version=`. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u https://www.validators.app/cluster-stats/mainnet`
else
	solana_version=`. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u https://www.validators.app/cluster-stats/testnet`
fi
if [ "$current_version" = "true" ]; then
	printf_n "$solana_version"
else
	if [ ! -f /etc/systemd/system/sstd.service ]; then
		sudo tee <<EOF >/dev/null /etc/systemd/system/sstd.service
[Unit]
Description=Solana System Tuning
After=network.target
Before=solana.service

[Service]
User=$USER
ExecStart=`command -v solana-sys-tuner` --user $USER
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
		/root/.local/share/solana/install/active_release/bin/solana-install init "v${solana_version}"
		/root/.local/share/solana/install/active_release/bin/solana-validator --ledger $HOME/solana/ledger/ wait-for-restart-window && \
		sudo systemctl stop solana && \
		sudo systemctl restart sstd && \
		sudo systemctl restart solana
	fi
fi