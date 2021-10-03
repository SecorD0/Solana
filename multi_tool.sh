#!/bin/bash
# Default variables
type="install"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script has a set of functions to work with the Solana node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help       show the help page"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Solana/blob/main/multi_tool.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	*|--)
		break
		;;
	esac
done
# Actions
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
if [ "$type" = "hello" ]; then
	echo
else
	solana_version=`. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/parsers/xpath.sh) -x "normalize-space(/html/body/main/div[5]/div[2]/div/div/div/div[3]/div/text())" -u https://www.validators.app/cluster-stats/testnet`
	. <(wget -qO- "https://release.solana.com/v${solana_version}/install")
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n "PATH" -v "/root/.local/share/solana/install/active_release/bin:$PATH"
fi
echo -e "${C_LGn}Done!${RES}"
