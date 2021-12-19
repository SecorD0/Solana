#!/bin/bash
# Default variables
function="install"
solana_version=""
mainnet="false"

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script performs many actions related to a Solana node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help             show the help page"
		echo -e "  -gv, --get-version      show current a node version"
		echo -e "  -up, --update           update the node"
		echo -e "  -v,  --version VERSION  the node VERSION to install/update (default is ${C_LGn}version used a large number of validators${RES})"
		echo -e "  -m,  --mainnet          use version getting and updating for a mainnet node"
		echo -e "  -un, --uninstall        uninstall the node (${C_LGn}doesn't delete $HOME/solana directory${RES})"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/multi_tool.sh — script URL"
		echo -e "https://teletype.in/@letskynode/Solana_part1_general — series of Russian-language articles on the Solana node"
		echo -e "https://t.me/letskynode — node Community"
		echo -e "https://teletype.in/@letskynode — guides and articles"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-gv|--get-version)
		function="get_version"
		shift
		;;
	-up|--update)
		function="update"
		shift
		;;
	-v*|--version*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		solana_version=`option_value "$1"`
		shift
		;;
	-m|--mainnet)
		mainnet="true"
		shift
		;;
	-un|--uninstall)
		function="uninstall"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
get_version() {
	if [ -n "$solana_version" ]; then
		printf_n "$solana_version"
	else
		if [ "$mainnet" = "true" ]; then
			. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/parsers/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u "https://www.validators.app/cluster-stats?locale=en&network=mainnet"
		else
			. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/parsers/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u "https://www.validators.app/cluster-stats?locale=en&network=testnet"
		fi
	fi
}
install() {
	printf_n "${C_LGn}Node installation...${RES}"
	sudo apt update
	sudo apt upgrade -y
	local solana_version=`get_version`
	if [ -n "$solana_version" ]; then
		local former_path="$PATH"
		. <(wget -qO- "https://release.solana.com/v${solana_version}/install")
		sed -i '0,/ PATH=/{/ PATH=/d;}' $HOME/.bash_profile
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n PATH -v "/root/.local/share/solana/install/active_release/bin:$former_path"
		printf_n "${C_LGn}Done!${RES}"
	else
		printf_n "${C_R}Couldn't get a current version! Specify it manually via -v option${RES}"
	fi
}
update() {
	local solana_version=`get_version`
	if [ -n "$solana_version" ]; then
		if [ ! -f /etc/systemd/system/sstd.service ]; then
			printf_n "[Unit]
Description=Solana System Tuning
After=network.target
Before=solana.service

[Service]
User=$USER
ExecStart=`which solana-sys-tuner` --user $USER
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/sstd.service
			sudo systemctl enable sstd
			sudo systemctl daemon-reload
			. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n sstd_log -v "sudo journalctl -fn 100 -u sstd" -a
		fi
		local current_version=`solana --version | grep -oPm1 "(?<=cli )([^%]+)(?= \()"`
		if dpkg --compare-versions "$current_version" "lt" "$solana_version"; then
			solana-validator --ledger $HOME/solana/ledger/ wait-for-restart-window && \
			sudo systemctl stop solana && \
			sudo systemctl daemon-reload && \
			sudo systemctl restart sstd && \
			sudo systemctl restart solana && \
			printf_n "${C_LGn}Done!${RES}"
		else
			printf_n "${C_LGn}The node version is current!${RES}\n"
		fi
	else
		printf_n "${C_R}Couldn't get a current version! Specify it manually via -v option${RES}"
	fi
}
uninstall() {
	rm -rf $HOME/.local/share/solana $HOME/.config/solana
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n PATH -v `echo "$PATH" | sed 's%/root/.local/share/solana/install/active_release/bin:%%'`
	printf_n "If there are no important files in the $HOME/solana directory, ${C_LGn}delete it yourself${RES}\n"
}

# Actions
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
$function
