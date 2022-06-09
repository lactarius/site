#!/usr/bin/env bash
declare DEFAULTLOCATION="$HOME/.local/lib"
declare location="${1:-$DEFAULTLOCATION}"
declare profile="$HOME/.profile"

sed -i "/SITE/d" "$profile"
sed -i "/site.sh/d" "$profile"
mkdir -p "$location" && cp ./site.sh "$location" &&
	echo -e "# SITE helper load\n. $location/site.sh" >>"$profile" &&
  echo "Installed." || echo "Error - try it manually."
