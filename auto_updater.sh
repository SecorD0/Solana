#!/bin/bash
# Default variables
mainnet="false"
service_name="saud"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script creates service file which executes an updating script. The"
		echo -e "updating script automatically checks the version of Solana testnet/mainnet node every"
		echo -e "30 minutes and updates the node when a new version is released"
		echo
		echo -e "${C_R}Creators aren't responsible for the script usage, so you use it at your own risk${RES}"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,   --help               show the help page"
		echo -e "  -m,   --mainnet            use for mainnet node"
		echo -e "  -sn,  --service-name NAME  service file NAME (default is '${C_LGn}${service_name}${RES}')"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/auto_updater.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0; exit 0
		;;
	-m|--mainnet)
		mainnet="true"
		shift
		;;
	-sn*|--service-name*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		service_name=`option_value "$1"`
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
printf_n "${C_LGn}Service file creating...${RES}"
solana_dir=`cat /etc/systemd/system/solana.service | grep -oPm1 "(?<=--ledger )([^%]+)(?=ledger)"`
if [ "$mainnet" = "true" ]; then
	command="${solana_dir}updater.sh -m"
else
	command="${solana_dir}updater.sh"
fi
sudo tee <<EOF >/dev/null /etc/systemd/system/$service_name.service
[Unit]
Description=Solana auto-updater
After=network.target
Before=solana.service
RequiresMountsFor=${solana_dir}

[Service]
type=oneshot
User=$USER
ExecStartPre=`which wget` -qO ${solana_dir}updater.sh https://raw.githubusercontent.com/SecorD0/Solana/main/updater.sh
ExecStartPre=`which chmod` +x ${solana_dir}updater.sh
ExecStart=${command}
Restart=always
RestartSec=30m

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable "$service_name"
sudo systemctl daemon-reload
sudo systemctl restart "$service_name"
printf_n "${C_LGn}Done!${RES}"
