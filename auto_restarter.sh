#!/bin/bash
# Default variables
crit_percent="90.00"
service_name="sard"
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
		echo -e "than ${C_LGn}${crit_percent}${RES}%, the script gently restarts the node"
		echo
		echo -e "${C_R}Creators aren't responsible for the script usage, so you use it at your own risk${RES}"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help                 show the help page"
		echo -e "  -cp, --crit-percent NUMBER  float or integer value of critical percentage of memory usage"
		echo -e "  -sn, --service-name NAME    service file NAME (default is '${C_LGn}${service_name}${RES}')"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/auto_restarter.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0
		;;
	-cp*|--crit-percent*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		crit_percent=`printf "%.2f" $(option_value "$1")`
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
if ! dpkg -s bc | grep -q "ok installed"; then
	sudo apt update
	sudo apt upgrade
	sudo apt install bc
fi
if [ ! -f /etc/systemd/system/$service_name.service ] || ! cat /etc/systemd/system/$service_name.service | grep -q "$crit_percent"; then
	solana_dir=`cat /etc/systemd/system/solana.service | grep -oPm1 "(?<=--ledger )([^%]+)(?=ledger)"`
	sudo tee <<EOF >/dev/null /etc/systemd/system/$service_name.service
[Unit]
Description=Solana auto-updater
After=network.target
RequiresMountsFor=${solana_dir}

[Service]
type=oneshot
User=$USER
ExecStartPre=`which wget` -qO ${solana_dir}auto_restarter.sh https://raw.githubusercontent.com/SecorD0/Solana/main/auto_restarter.sh
ExecStartPre=`which chmod` +x ${solana_dir}auto_restarter.sh
ExecStart=${solana_dir}auto_restarter.sh -cp "${crit_percent}"
Restart=always
RestartSec=5m

[Install]
WantedBy=multi-user.target
EOF
	sudo systemctl enable "$service_name"
	sudo systemctl daemon-reload
	sudo systemctl restart "$service_name"
	return 0
fi
if [ `bc <<< "$crit_percent<$(free | awk 'NR == 2 {printf("%.2f\n"), $3/$2*100}')"` -eq "1" ]; then
	"`which solana-validator`" --help
	"`which solana-validator`" --ledger $HOME/solana/ledger/ wait-for-restart-window
fi
