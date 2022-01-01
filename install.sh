#!/usr/bin/env bash
declare DEFAULTLOCATION="$HOME/.local/lib"
declare location="${1:-$DEFAULTLOCATION}"

mkdir -p "$location" && cp ./site.sh "$location" \
	&& echo -e "\n. $location/site.sh" >> "$HOME/.profile" \
	&& echo "Installed." || echo "Error - try it manually."
