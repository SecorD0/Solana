#!/bin/bash
# Default variables
solana_version=""
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
		echo -e "  -v,  --version VERSION  Solana node VERSION to update (default is ${C_LGn}version used a large number of validators${RES})"
		echo -e "  -cv, --current-version  show current version"
		echo -e "  -m,  --mainnet          use the script for mainnet node"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/updater.sh - script URL"
		echo -e "https://t.me/OnePackage — noderun and tech community"
		echo
		return 0 2>/dev/null; exit 0
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
if [ ! -n "$solana_version" ] || [ "$current_version" = "true" ]; then
	if [ "$mainnet" = "true" ]; then
		solana_version=`. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/parsers/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u "https://www.validators.app/cluster-stats?locale=en&network=mainnet"`
	else
		solana_version=`. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/parsers/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u "https://www.validators.app/cluster-stats?locale=en&network=testnet"`
	fi
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
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
		sudo systemctl enable sstd
		sudo systemctl daemon-reload
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n sstd_log -v "sudo journalctl -f -n 100 -u sstd" -a
	fi
	current_version=`/root/.local/share/solana/install/active_release/bin/solana --version | grep -oPm1 "(?<=cli )([^%]+)(?= \()"`
	if dpkg --compare-versions "$current_version" "lt" "$solana_version"; then
		printf_n "${C_LGn}Updating the node...${RES}"
		/root/.local/share/solana/install/active_release/bin/solana-install init "v${solana_version}"
		/root/.local/share/solana/install/active_release/bin/solana-validator --ledger $HOME/solana/ledger/ wait-for-restart-window && \
		sudo systemctl stop solana && \
		sudo systemctl daemon-reload && \
		sudo systemctl restart sstd && \
		sudo systemctl restart solana && \
		printf_n "${C_LGn}Done!${RES}"
	else
		printf_n "${C_LGn}The node version is current!${RES}"
	fi
fi
