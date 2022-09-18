#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function _showHelp(){
  echo "Usage: ./npmtolwc.sh <comma-separated list of modules to import (no spaces)> <optional flags>"
  echo "Flags:"
  echo "-p <comma-separated list of npm packages to install (no spaces)>"
  echo "-l <name of the exported library>. Defaults to <package names separated by underscore and stripped of any alphanumeric characters. For eg: import d3-time,d3-scale will result in a library name of 'd3time_d3scale'. You will refer to the exported module in lwc as <exported library>.<exported module>"
  echo "-s <name of static resource file>. Defaults to '<exported library name><random number>'"
}

if [ $# -eq 0 ] ||  [ "${1:0:1}" == "-" ] #if there are no arguments or first arg starts with a hyphen(-)
then
  _showHelp
  exit 1
else
  importname="$1"
fi

dlpath="/tmp/npmdl" # Directory for storing temporary resources

packagename="$importname"
exportlibname="${1//,/_}"
exportlibname="${exportlibname//[^[:alnum:]_]/}"
resourcename="$exportlibname"$RANDOM

shift #Discard args already parsed before parsing optional flags

while getopts "s:p:l:" option;do
  case "$option" in
    s )#set static resource name
      resourcename="${OPTARG:-${resourcename}}"
      ;;
    p )#set name of module to import
      packagename="${OPTARG:-${packagename}}"
      ;;
    l )#set name of exported library
      exportlibname="${OPTARG:-${exportlibname}}"
      ;;
    \?)#set name of module to import
      echo "Invalid option"
      exit 1
      ;;
  esac
done

IFS="," read -ra packagenamesArr <<< "$packagename" # Read comma-separated package names into an array
IFS=" " packagenames=${packagenamesArr[@]} # Generate a space separated string of package names to be fed to 'npm install'

if [ ! -f "package.json" ]
then
  npm init -y
fi

echo "installing $packagenames"
npm install --save-dev $packagenames

if [ ! -d "node_modules/webpack" ] || [ ! -d "node_modules/webpack-cli" ]
then
  npm install --save-dev webpack@4 webpack-cli@4 # webpack 5 removed polyfills for core node modules
fi


if [[ ! -d "$dlpath" ]]; then
 mkdir "$dlpath" 
fi

# Download templates from github gist
curl -L https://gist.github.com/surajp/409425b479b706ad522f716db6498531/raw/bb5887e15db48858fed3af3c840e1a919c5bd6b0/index.js -o "$dlpath/index.js"
curl -L https://gist.github.com/surajp/409425b479b706ad522f716db6498531/raw/bb5887e15db48858fed3af3c840e1a919c5bd6b0/resource-meta.xml -o "$dlpath/resource-meta.xml"
curl -L https://gist.github.com/surajp/409425b479b706ad522f716db6498531/raw/bb5887e15db48858fed3af3c840e1a919c5bd6b0/webpack.config.js -o "$dlpath/webpack.config.js"

# here exportlibname refers to the name of the exported library by webpack. in our lwc we will have to refer to our function as
# <exportlibname>/<exportname>. 
sed "s/<libname>/$exportlibname/g" "$dlpath/webpack.config.js" > ./webpack.config.js
if [ ! -d "webpack-src" ]
then
  mkdir webpack-src
fi

> ./webpack-src/index.js #empty the file
# here importname can refers to the actual npm library name which we bring in using `require` command.
# or it can be a sub-library, used for tree-shaking
exportString=""
IFS="," read -ra imports <<< "$importname"
for lib in "${imports[@]}"
do
  import=${lib//[^[:alnum:]]/}
  echo "const $import = require(\"$lib\");" >> ./webpack-src/index.js
  exportString="$exportString$import,"
done
echo "export {${exportString::-1}}" >> ./webpack-src/index.js
npx webpack-cli
if [ ! -d "force-app/main/default/staticresources" ]
then
  mkdir -p "force-app/main/default/staticresources"
fi
cp ./dist/bundle.js "./force-app/main/default/staticresources/$resourcename"
cp "$dlpath/resource-meta.xml" "./force-app/main/default/staticresources/$resourcename.resource-meta.xml"
#sfdx force:source:push

echo 
echo 
echo 

echo "$(tput setaf 5)Static Resource named \"$resourcename\" has been generated. You may deploy this, load it in your LWC and refer to the modules as $exportlibname.<module name>. For example, $exportlibname.${exportString%%,*}"

