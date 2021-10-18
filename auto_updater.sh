#!/bin/bash
# Default variables
mainnet="false"
service_name="saud"
uninstall="false"
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
		echo -e "${C_LGn}30${RES} minutes and updates the node when a new version is released"
		echo
		echo -e "${C_R}Creators aren't responsible for the script usage, so you use it at your own risk${RES}"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help               show the help page"
		echo -e "  -m,  --mainnet            use for mainnet node"
		echo -e "  -sn, --service-name NAME  service file NAME (default is '${C_LGn}${service_name}${RES}')"
		echo -e "  -u,  --uninstall          uninstall the auto-updating"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/auto_updater.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
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
	-u|--uninstall)
		uninstall="true"
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
solana_dir=`cat /etc/systemd/system/solana.service | grep -oPm1 "(?<=--ledger )([^%]+)(?=ledger)"`
if [ "$uninstall" = "true" ]; then
	printf_n "${C_LGn}Uninstalling...${RES}"
	sudo systemctl stop "$service_name"
	rm -rf "/etc/systemd/system/${service_name}.service" "${solana_dir}updater.sh"
	sudo systemctl daemon-reload
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n "${service_name}_log" -d
	printf_n "${C_LGn}Done!${RES}"
else
	printf_n "${C_LGn}Service file creating...${RES}"
	if [ "$mainnet" = "true" ]; then
		command="${solana_dir}updater.sh -m"
	else
		command="${solana_dir}updater.sh"
	fi
	printf "[Unit]
Description=Solana auto-updater
After=network.target
Before=solana.service
RequiresMountsFor=${solana_dir}

[Service]
type=forking
User=$USER
ExecStartPre=`which wget` -qO ${solana_dir}updater.sh https://raw.githubusercontent.com/SecorD0/Solana/main/updater.sh
ExecStartPre=`which chmod` +x ${solana_dir}updater.sh
ExecStart=${command}
Restart=always
RestartSec=30m

[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/${service_name}.service"
	sudo systemctl daemon-reload
	sudo systemctl enable "$service_name"
	sudo systemctl restart "$service_name"
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n "${service_name}_log" -v "sudo journalctl -f -n 100 -u ${service_name}" -a
	printf_n "${C_LGn}Done!${RES}"
fi
