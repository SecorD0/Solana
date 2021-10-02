#!/bin/bash
# Default variables
crit_load="90.00"
service_name="sard"
uninstall="false"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script creates service file which executes a restarting script every"
		echo -e "${C_LGn}5${RES} minutes. The restarting script automatically checks memory usage and if it is more"
		echo -e "than ${C_LGn}${crit_load}${RES}%, the script gently restarts the node"
		echo
		echo -e "${C_R}Creators aren't responsible for the script usage, so you use it at your own risk${RES}"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help               show the help page"
		echo -e "  -cl, --crit-load NUMBER   float or integer value of critical memory usage load"
		echo -e "  -sn, --service-name NAME  service file NAME (default is '${C_LGn}${service_name}${RES}')"
		echo -e "  -u,  --uninstall          uninstall the auto-restarting"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/auto_restarter.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-cl*|--crit-load*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		crit_load=`printf "%.2f" $(option_value "$1")`
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
	rm -rf "/etc/systemd/system/${service_name}.service" "${solana_dir}auto_restarter.sh"
	sudo systemctl daemon-reload
	printf_n "${C_LGn}Done!${RES}"
else
	if ! dpkg -s bc | grep -q "ok installed"; then
		sudo apt update
		sudo apt upgrade
		sudo apt install bc
	fi
	text="[Unit]
Description=Solana auto-restarter
After=network.target solana.service
RequiresMountsFor=${solana_dir}

[Service]
type=forking
User=$USER
ExecStartPre=`which wget` -qO ${solana_dir}auto_restarter.sh https://raw.githubusercontent.com/SecorD0/Solana/main/auto_restarter.sh
ExecStartPre=`which chmod` +x ${solana_dir}auto_restarter.sh
ExecStart=${solana_dir}auto_restarter.sh -cp "${crit_load}"
Restart=always
RestartSec=5m

[Install]
WantedBy=multi-user.target"
	file_text=`cat /etc/systemd/system/sard.service 2>/dev/null`
	if [ "$file_text" != "$text" ]; then
		printf_n "${C_LGn}Updating service file...${RES}"
		printf "$text" > "/etc/systemd/system/${service_name}.service"
		sudo systemctl daemon-reload
		sudo systemctl enable "$service_name"
		sudo systemctl restart "$service_name"
		printf_n "${C_LGn}Done!${RES}"
		return 0 2>/dev/null; exit 0
	fi
	load=`free | awk 'NR == 2 {printf("%.2f\n"), $3/$2*100}'`
	if [ `bc <<< "$crit_load<$load"` -eq "1" ]; then
		/root/.local/share/solana/install/active_release/bin/solana-validator --ledger $HOME/solana/ledger/ wait-for-restart-window && \
		sudo systemctl restart solana
	else
		printf_n "The load is within ${C_LGn}normal${RES} limits: ${C_LGn}%.2f${RES} p.c." "$load"
	fi
fi
