#!/bin/bash
cd $(dirname "$0") || exit 1 

# ------------------------------------------------------------------------------------------------
# Turtle for iTerm - TURTLE.SH 
# ------------------------------------------------------------------------------------------------
#
# DESCRIPTION:  Turtle is a terminal session launcher for iTerm on Mac. It automates the process
#				of opening SSH session windows in iTerm to multiple servers in a customer
#				environment, as well as providing a variety of additional Hybris environment
#				management features.
#
#				See https://wiki.hybris.com/display/MSPIPS/Turtle+for+iTerm for more info.
#
# AUTHORS:		Goh Maehashi, Tom Kendall
#
# USAGE:		turtle  [-b browser] [-c connect] [-i info] [-j jump] [-l list]
#	      				[-r refresh] [-w wiki] [-y hosts] <customer_code> <environment>
#
# VERSION:	 	9.1 
# 
# ------------------------------------------------------------------------------------------------

#####################
#     Variables     #
#####################

# Command line arguments.
mode=$1
customer_code=$2
environment=$3
filename=$2_$3.env
param1=$1
param2=$2
param3=$3
param4=$4
param5=$5


# Enforce strict mode for the rest of the script.
set -euo pipefail

# Script variables.
app="[Turtle]"
scriptpath="$( cd "$(dirname "$0")" ; pwd -P )"
lineEnding=$'s/\r//'
backslash='s/\\//g'
numberRegex='^[0-9]+$'
leadingZeroes='s/^0*//'
fullfilepath=$scriptpath/env/$filename
numberOfParams=$#
fullcustomer=
fullenvironment=
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
cyan=`tput setaf 6`
orange=`tput setaf 208`
bold=`tput bold`
reset=`tput sgr0`
doneMessage=" done."

#####################
#     Functions     #
#####################

function swapMode {

	# Realign parameters if connect mode has been assumed.
	customer_code=$param1
	environment=$param2
	filename="$param1"_"$param2".env
	fullfilepath="$scriptpath/env/$filename"
	param5=$param4
	param4=$param3

}

function checkConfig {

	# Check that the wiki and hybris usernames are set.
	if [[ ( -z $wiki_username ) || ( -z $hybris_username ) ]]; then
		error "Please edit the CONFIG file and enter your hybris wiki credentials to begin using Turtle"
	fi

}

function getPassword {

	# If the user's wiki password hasn't been set (either from config or previous request), request it.	
	if [[ -z $wiki_password ]]; then
		echo -n "$app Please enter your Wiki Password..."
		read -s wiki_password
		echo "$doneMessage"
	fi

}

function downloadFile {
	
	# Ask the user for their password if it's not included in the script.
	getPassword

	echo "$app Connecting to environment repository..."

	# Defines the repository URL to utilise for the download.
	urlToDownload="https://wiki.hybris.com/download/attachments/201953962/$filename"

	# Download the files based on previously provided credentials. 
	curl -# -O -u$wiki_username:$wiki_password $urlToDownload
	
	# If curl was successful, i.e., if the previous operation was successful.
	if [ 0 -eq $? ]; then

		# Clear ugly hashes line.
		clearLastLine
		clearLastLine

		echo "$app File downloaded successfully."
	
		# Extract the first line to see if the response was a file or HTML page.
		firstLine=$(head -1 $filename)

		# If HTML page returned.
		if [ "$firstLine" == "<!DOCTYPE html>" ]; then
			
			# Delete the HTML response.
			rm $filename

			# Inform the user the download failed.
			error "Environment not found. Please ensure the syntax has been entered correctly"
	
		elif [[ $(cat "$filename" | sed $lineEnding) == *"Authentication Failure"* ]]; then

			# Delete the HTML response.
			rm $filename

			# Alert the user their credentials are wrong.
			error "The supplied wiki credentials were incorrect. Please try again"

		else

			# Move downloaded file to env folder.
			if ! [[ "$(pwd)" == "$scriptpath/env" ]]; then
				mv $filename "$scriptpath/env" 2>/dev/null
			fi

		fi

	else

		# Inform the user the download failed and exit with error.
		error "Download failed!"

	fi

}

function warn {

	# Display a warning but continue execution.
	echo "$app ${yellow}WARN: $1.${reset}"

}

function error {

	# Display an error and exit the program.
	echo "$app ${red}ERROR: $1 - aborting.${reset}"
	exit 1

}

function fileFromToday {

	# Check if the environment file was downloaded today.
	if [ $(stat -f "%Sm" -t "%d" $fullfilepath) == $(date +%d) ]; then
		echo "yes"
	else
		echo "no"
	fi

}

function getPropertyFromEnv {

	# Get property from Environment file.
	echo $(sed -n "s/^$1=//p" $fullfilepath | sed $lineEnding)

}

function getPropertyFromEnvFile {

	# Store filename in variable.
	inputFilepath=$2

	# Get property from provided Environment file.
	echo $(sed -n "s/^$1=//p" $inputFilepath | sed $lineEnding)

}

function getEnvironmentColour {
	
	# Extract environment from provided letter. Gets only the first character
	# incase numbered environments are supplied i.e. d2 q2 etc.
	firstEnvironmentLetter=${environment:0:1}

	# Check the extracted letter, and return the colour accordingly.
	case "$firstEnvironmentLetter" in
		"d")
			echo 'ANSI  color'
		;;
		"s"|"q")
			echo 'ANSI cyan color'
		;;
		"p")
			echo "ANSI red color"
		;;
		*)
			echo "ANSI bright blue color"
		;;
	esac
	
}

function loadSettings {

	# If the help file exists, print it to the terminal, otherwise exit in error.
	if [[ -a "$scriptpath/CONFIG" ]]; then
		source "$scriptpath/CONFIG"
	else
		error "Config file not found"
	fi

}

function printAllServers {

	# Print all servers in the server listing.
	if [ ! ${#serverListing[@]} -eq 0 ]; then
		echo "$app The discovered servers are as follows:"
		printf "$app %s\n" "${serverListing[@]#*=}"
	else
		echo "$app No servers were discovered."
	fi

}

function outputDashes {

	# Get the length of the string and add 2 to reach the end border
	length=$(($1 + 3))

	# Print dashes without newline.
	for ((i=0; i<=$length; i++)); do	
		echo -n "-"
	done

	# End with newline.
	echo

}

function printHeading {

	# Get the string passed to the function.
	input=$1

	# Calculate the size of the string
	size=${#input}

	# Print heading with dashes.
	outputDashes $size
	echo "| $1 |"
	outputDashes $size

}

function getDatacentreFromCode {

	# Switches the provided two letter datacentre code and expands accordingly.
	case "$1" in
		"fr")
			echo "Frankfurt"
		;;
		"ma")
			echo "Boston"
		;;
		*)
			echo "-1"
		;; 
	esac

}

function downloadFileIfDoesntExist {

	# If no environment was provided, assume production.
	if [[ -z $environment ]]; then
		environment="p"
		filename="$customer_code"_p.env
		fullfilepath=$scriptpath/env/"$customer_code"_p.env
	fi 

	# Download file if it doesn't exist or is outdated.
	if [ -a $fullfilepath ]; then
		isFileFromToday=$(fileFromToday)
		if [[ ( "$isFileFromToday" = "no" ) && ( true == $autoDailyRefresh ) ]]; then
			echo "$app Existing file outdated - downloading new env file."
			downloadFile
		fi
	else
		# File not found, warn and attempt to download.
		warn "File $fullfilepath not found"
		downloadFile
	fi

	# Extract and print full customer name and environment.
	fullcustomer=$(getPropertyFromEnv PROJECTNAME)
	fullenvironment=$(getPropertyFromEnv ENVIRONMENTTYPE)

}

function getRandomHostnameFromEnvFile {

	# Return a list of servers from the file - return the first result.
	grep_raw=$(grep -m 1 "SERVER1=$customer_code" $fullfilepath)

	# Remove the left site of the equals.
	temp_hostname=${grep_raw[@]#*=}

	# Return the result.
	echo "$temp_hostname"
}


function getCurrentVPNConnection {
	
	# Extract ppp0 address from ifconfig.
	ppp_array=(`ifconfig | awk '/ppp/{getline; print}' | awk '{print $2}'`)

	if [[ ${#ppp_array[@]} > 0 ]]; then
		for i in ${ppp_array[@]};do
			# Check IP range from extracted IP.
			if [[ $i == "10.17"* ]]; then
				echo "Boston VPN is running"
			elif [[ $i == "10.33"* ]]; then
				echo "Frankfurt VPN is running"
			else
				echo "-1"
			fi
		done
	else
		echo "No VPN Connected"		
	fi

}

function getDatacentreCodeFromHostname {

	# Store provided username in temporary variable.
	temp=$1

	# Get all characters after customer+env i.e. after 'vnx-p-'.
	tempDC=${temp#*-$environment-}

	# Clip all characters except the first two, which should always be the two letter datacentre code.
	tempDC=${tempDC:0:2}

	# Return the found datacentre code.
	echo $tempDC

}

function checkServertypeForWarn {

	# Capture function input into variable.
	passedServertype=$1

	# Array of current known server types.
	knownTypes=("adm" "app" "scan" "db" "dth" "dytc" "nfs" "repo" "sftp" "smtp" "srch" "web" "appall")

	# If the server type is not in the known types, display a warning.
	if ! [[ ${knownTypes[*]} =~ $passedServertype ]]; then
		warn "Provided servertype '$passedServertype' is not a known servertype"
	fi 

}

function checkEnvAge {
	
	# If the information file exists.
	if [[ -a $scriptpath/INFO ]]; then

		# Load the information file.
		source $scriptpath/INFO

		# Get the current day of the year.
		currentDate=$(date +%j)

		# If last updated more than seven days ago.
		if [[ ( $(($lastUpdated + 7)) -lt $currentDate ) && ( $autoDailyRefresh == false )  ]]; then
			warn "Your local env repository hasn't been updated in over 7 days. Consider running turtle -r"
		fi

	fi

}

function padZeros {

	input=$1
	length=${#input}

	# Output server number with zeroes prepended to align with three digit standard.
	case $length in
		1)
			echo "00$input"
		;;
		2)
			echo "0$input"
		;;
		3)
			echo "$input"
		;;
		*)
			echo "-1"
		;;
	esac

}

function parseServers {

	# Check the age of the environment repository.
	checkEnvAge

	# Source server type from supplied parameter.
	servertype=$param4

	# Capitalise server type (i.e. app to APP) for grepping.
	typeUppercase=$(echo $servertype | awk '{print toupper($0)}')

	# Warn if the servertype is not known.
	checkServertypeForWarn $servertype

	# Initialise purpose variable.
	purpose=

	# If appall declare purpose as such.
	if [[ $servertype == "appall" ]]; then
		purpose="appall"
	fi

	# If fifth parameter has been provided.
	if ! [[ -z "$param5" ]]; then

		# Display a warning if appall was selected and other parameters are listed.
		if [[ $servertype == "appall" ]]; then
			warn "All other parameters are ignored in appall mode"

		# If the fifth parameter is a singular number.
		elif [[ $param5 =~ $numberRegex ]]; then
			purpose="singular"

		# If the user has supplied a range.
		elif [[ ( ${param5:0:1} =~ $numberRegex ) && ( ${param5} == *"-"* ) ]]; then
			
			# Get the numbers before and after the range.
			rangeStart=${param5%-*}
			rangeEnd=${param5#*-}

			# Strip any potential zeroes.
			rangeStart=$(echo $rangeStart | sed $leadingZeroes)
			rangeEnd=$(echo $rangeEnd | sed $leadingZeroes)

			# Check that both sides of the hyphen are numbers.
			if [[ ( ! $rangeStart =~ $numberRegex ) || ( ! $rangeEnd =~ $numberRegex ) ]]; then
				error "Invalid range supplied. Please ensure the values provided are numbers and contain no extra characters"
			fi

			# If the first number is greater than or equal to the second number, invalid range has been supplied.
			if [[ $rangeStart -ge $rangeEnd ]]; then
				error "Invalid range supplied. Please ensure the numbers are valid and in sequential order"
			fi

			# Range pre-checks satisfied, declare range as purpose.
			purpose="range"

		else

			# Non standard fifth parameter provided, alert user and exit.
			error "Unknown fifth parameter"

		fi

	fi

	# No purpose has previously been provided, assume normal.
	if [[ -z $purpose ]]; then
		purpose="normal"
	fi

	# Switch purpose based on fourth parameter.
	case ${purpose} in
		"normal")

			# Set regex based on the user requested server type.
			regex=^NAME_"$typeUppercase"SERVER

			# Extract servers of server type using grep. Then remove line endings, sort, and strip duplicate values.
			serverListing=($(cat $fullfilepath | grep -E $regex | sed $lineEnding | sort -n | uniq)) || true

		;;
		"appall")

			# Set regex based on the user requested server type.
			regex=^NAME_APPSERVER

			# Extract servers of server type using grep. Then remove line endings, sort, and strip duplicate values.
			serverListing=($(cat $fullfilepath | grep -E $regex | sed $lineEnding | sort -n | uniq))

			# Find admin servers within the file.
			admServerListing=($((cat $fullfilepath | grep -E ^NAME_ADMSERVER | sed $lineEnding | sort -n | uniq) || true ))

			# If servers were found, append them to the current server listing.
			if ! [ ${#admServerListing[@]} -eq 0 ]; then
				serverListing=("${serverListing[@]}" "${admServerListing[@]}")
				servertype="app + adm"
			else
				warn "No admin servers were found"
				servertype="app"
			fi

		;;
		"singular")

			# Strip potential zeroes from parameter.
			param5=$(echo $param5 | sed $leadingZeroes)

			# Modify regex to only return server with specific number.
			regex=^NAME_"$typeUppercase"SERVER"$param5="

			# Extract servers of server type using grep. Then remove line endings, sort, and strip duplicate values.
			serverListing=($(cat $fullfilepath | grep -E $regex | sed $lineEnding | sort -n | uniq)) || true

			if ! [[ ${#serverListing[@]} -eq 0 ]]; then

				# Store the theoretical server number and returned server number in variables.
				theoreticalServerNumber=$(padZeros $param5)
				returnedServerNumber=$(echo $serverListing | grep -o "[0-9][0-9][0-9]")

				# Compare the theoretical and returned server numbers.
				if [[ "$theoreticalServerNumber" != "$returnedServerNumber" ]]; then
					error "There is a problem with this environment file. Turtle expected Server $theoreticalServerNumber, but encountered Server $returnedServerNumber. You will not be able to use Turtle to connect to singular nodes of this environment"
				fi

			fi

		;;
		"range")

			# Declare server listing variable to prevent strictness errors.
			serverListing=()
			tempListing=()

			# Begin loop from the beginning and ending values.
			for ((i=$rangeStart; i<=$rangeEnd; i++)); do

				# Set regex to contain server type and index.
				regex=^NAME_"$typeUppercase"SERVER"$i="

				# Store listing from grep in temp listing.
				tempListing=$(cat $fullfilepath | grep -E $regex | sed $lineEnding) || tempListing="0"

				# No servers found, break and allow script to return in error.
				if [[ "${tempListing:0:1}" == "0" ]]; then
					break
				fi

				# If server was found.
				if [[ ${#tempListing[@]} -ne 0 ]]; then

					# Store the theoretical server number and returned server number in variables.
					theoreticalServerNumber=$(padZeros $i)
					returnedServerNumber=$(echo $tempListing | grep -o "[0-9][0-9][0-9]") || true

					# Compare the theoretical and returned server numbers.
					if [[ "$theoreticalServerNumber" != "$returnedServerNumber" ]]; then
						error "There is a problem with this environment file. Turtle expected Server $theoreticalServerNumber, but encountered Server $returnedServerNumber. You will not be able to use Turtle to connect to a range of these servers"
					fi

				fi

				# If no servers exist already.
				if [ ${#serverListing[@]} -eq 0 ]; then

					# Initialise serverlisting with first values.
					serverListing=("${tempListing[@]}")

				else

					# If additional servers were found.
					if ! [ ${#tempListing[@]} -eq 0 ]; then

						# Append found servers to existing listing.
						serverListing=("${serverListing[@]}" "${tempListing[@]}")

					else

						# Show a warning if the supplied range is too large and break.
						warn "Provided range is greater than actual server count"
						break

					fi

				fi

			done

		;;
		*)
			# All other purpose possibilities - exit with error.
			error "Unable to calculate purpose"
		;;
	esac

	# Store count of serverlisting in variable for readability.
	foundServers=${#serverListing[@]}

	# Exit with errors if no servers were found.
	if [ $foundServers -eq 0 ]; then
    	error "No servers found"
	fi

	# Output the number of servers found. Calculate if greater than 1, therefore 's' is required.
	echo "$app $foundServers $servertype server$(calculateS $foundServers) found."

	# Extract server hostname from env file line entry. # i.e. extract text after equals. 
	for ((i=0; i<${#serverListing[*]}; i++)); do

		# Modify the server listing to only retrieve the hostname.
		serverListing[i]=${serverListing[i]#*=}

		# Remove hybrishosting for consistency.
		serverListing[i]=${serverListing[i]/\.hybrishosting\.com/}

	done

}

# Remove the last line from the console.
function clearLastLine {
	tput cuu 1 && tput el
}

function calculateS {

	# Store function inputs into variables.
	input=$1

	# If inputted string length is greater than one, output an "s".
	if [[ $input -ge 2 ]]; then
		echo "s"
	fi

}

function launchURLFromProperty {

	# Store function inputs into variables.
	property=$1
	servertype=$2
	askForConfirmation=$3

	# Get URL from the env file.
	urlToLaunch=$(getPropertyFromEnv $property | sed $backslash)

	# If URL is not null.
	if [[ -z $urlToLaunch ]]; then

		# URL is null, alert the user and exit.
		error "No suitable URL found"

	else

		# Clean URL and add HMC/HAC specific affects to sourced admin node.
		if [[ $servertype == "directhmc" ]]; then
			urlToLaunch=${urlToLaunch/\.hybrishosting\.com/}
			urlToLaunch="http://$urlToLaunch.hybrishosting.com:9001/hmc/hybris"
		elif [[ $servertype == "directhac" ]]; then
			urlToLaunch=${urlToLaunch/\.hybrishosting\.com/}
			urlToLaunch="http://$urlToLaunch.hybrishosting.com:9001/hac"
		elif [[ $servertype == "backoffice" ]]; then
			urlToLaunch=${urlToLaunch}
			urlToLaunch="http://$urlToLaunch/backoffice"
		fi

		# Extract URL and open the user wishes to open their browser.
		if [[ $askForConfirmation == "true" ]]; then
			read -s -n1 -r -p "$app URL found. Press any key to continue, or Ctrl+C to exit." key
			echo
		fi

		# Launch in the default browser. Mac only.
		open $urlToLaunch

	fi

}

function askEnv {

	# Get list of environment files for input customer.
	askEnvList=($(find $scriptpath/env -regex .*"$customer_code".* | grep -E -o "\w+\.env")) || askEnvList="false"

	# Get the customer's name from the file.
	customerName=$(getPropertyFromEnvFile PROJECTNAME $scriptpath/env/$askEnvList)
	echo "$app Select environment for $customerName:"

	if [[ "${#askEnvList[@]}" == "false" ]]; then
		echo "None lol"
		exit 0
	fi

	# Output list of matched files. 
	count=0
	for envFile in "${askEnvList[@]}"; do
		
		# Increment count.
		count=$((count+1))

		# Get proper environment name.
		tempEnv=$(getPropertyFromEnvFile ENVIRONMENTTYPE $scriptpath/env/$envFile)
		
		# Get environment number if applicable.
		envNumber=($(echo "$envFile" | grep -o "\d")) || envNumber=""
		
		# Output number and environment to the user.
		echo -e $count. $tempEnv $envNumber

	done

	# Ask the user which environment they would like to select.
	read -s -n1 id

	# If not a number, or not between range, output that this is incorrect.
	if [[ ( ! $id =~ $numberRegex ) || ( $id -lt 1 ) || ( $id -gt $count ) ]]; then
		error "Invalid page selected"
	else

		echo

		# Correct the index to zero based.
		arrayThingy=$(($id - 1))

		# Calculate environment, filename and full file path from input.
		environment="${askEnvList[arrayThingy]%.env*}"
		environment="${environment#*_}"
		filename="${askEnvList[arrayThingy]}"
		fullfilepath="$scriptpath/env/$filename"

	fi

}

function checkParams {

	# Store function inputs into variables.
	checkName=$1
	paramCountToCheck=$2
	strictMode=$3
	difference=$(($paramCountToCheck + 1))

	# If it must be a certain number of variables.
	if [[ $strictMode == "strict" ]]; then

		# If number of parameters not equal to required number.
		if [[ $numberOfParams -ne $difference ]]; then
			error "Incorrect number of parameters for $checkName mode. Run turtle --help for more info"
		fi

	else

		# If hasn't met minimum number of variables.
		if [[ $numberOfParams -lt $difference ]]; then
			error "Incorrect number of parameters for $checkName mode. Run turtle --help for more info"
		fi

	fi

}

function vpnCheck {

	mode=$1

	# Calculate datacentre from hostname and get name from shortcode.
	datacentreCode=$(getDatacentreCodeFromHostname $serverListing)
	datacentre=$(getDatacentreFromCode $datacentreCode)

	# Get the user's current VPN connection.
	currentVPN=$(getCurrentVPNConnection)

	# Exits if the user is not connected to any datacentres, or if they are connected to the wrong datacentre.
	if [[ ( "$datacentre" != "$currentVPN" ) && ( $ignoreVpnCheck != "true" ) ]]; then
		
		# Switch on whether or not the function is running in error or warn mode.
		case "$mode" in
			"error")
				error "Incorrect VPN detected. Please connect to $datacentre to continue"
			;;
			"warn")
				warn "Incorrect VPN detected. Please connect to $datacentre to ensure access these sites"
			;;
			*)
				error "No mode provided for VPN check. Assuming error"
			;;
		esac

	fi

}

function connectUsingAppleScript {

	# Ensure the user is connected to the right VPN and exit if not.
	vpnCheck error

	# Get the colour for the terminal window.
	colour=$(getEnvironmentColour)

	# Get OSX version.
	osxVersion=$(sw_vers -productVersion)

	# Calculate and store the number of servers in the server listing.
	numberOfServers=${#serverListing[@]}

	# Sort list if normal is selected.
	if [[ "$purpose" == "normal" ]];then
		IFS=$'\n' serverListing=($(sort <<<"${serverListing[*]}"))
		unset IFS
	fi

	# Warn if the user is about to connect to 10 or more servers.
	if [ $numberOfServers -ge 10 ]; then

		# Pause and ensure the user wants to continue.
		read -s -n1 -r -p "$app WARN: You are about to connect to $numberOfServers servers. Press any key to continue, or Ctrl+C to exit..." key
		echo

	fi

	# Create new window if set in settings.
	if [ true == $newWindowMode ]; then

		echo -n "[Turtle] Connecting..."

		# Open a new window.
		osascript $scriptpath/scripts/new_window.scpt $width $height

	else

		echo "[Turtle] Connecting..."

	fi

	# The following code is a 'workaround' due to the way Applescript has been changed in iTerm2 build 3.
	# Ideally, the colours would be passed to an existing script as a parameter (I could not get this to work),
	# and the AppleScript would be able to close the first created session. The workaround for this has been
	# to write the colour setting AppleScript within this bash script via the osa variables, and to create
	# separate scripts for when splits are and are not required.

	osa0='use AppleScript version "2.4"'
	osa1='tell application "iTerm"'
	osa2='tell the current session of the current window'
	osa3='end tell'

	# Launch window without splitting, and set the colour of the terminal.
	osascript $scriptpath/scripts/launch_without_split.scpt $hybris_username ${serverListing[0]}.hybrishosting.com
	
	# Clear the screen if requested via user settings.
	if [[ ( $clearAfterConnect == true ) && ( $newWindowMode == false ) ]]; then
		clear
	fi

	# Change screen colour if running a recent version of OSX.
	osascript -e "$osa0" -e "$osa1" -e "$osa2" -e  "set foreground color to $colour" -e "$osa3" -e "$osa3"

	# If more than one server was requested, launch these too.
	if [[ $numberOfServers -gt 1 ]]; then

		# Loop through all extracted servers and initiate their connection.
		for ((i=1; i<${#serverListing[*]}; i++)); do

			# Launch each new session and colour it accordingly.
			osascript $scriptpath/scripts/launch.scpt $hybris_username ${serverListing[i]}.hybrishosting.com

			# Change screen colour if running a recent version of OSX.
			osascript -e "$osa0" -e "$osa1" -e "$osa2" -e  "set foreground color to $colour" -e "$osa3" -e "$osa3"

		done

	fi

	# Only echo 'done' if new window mode is true to prevent bad label structure.
	if [ $newWindowMode == true ]; then
		echo "$doneMessage"
	fi

}

function runUsage {
	echo "Usage: turtle [-b browser] [-c connect] [-i info] [-j jump] [-l list] [-r refresh] [-w wiki] [-y hosts] <customer_code> <environment>"
	echo "Run turtle --help for more information."
	exit 0
}

function runHelp {

	# If the help file exists, print it to the terminal, otherwise exit in error.
	if [[ -a "$scriptpath/HELP" ]]; then
		cat $scriptpath/HELP
		exit 0
	else
		error "Help file not found"
	fi

}

function runBrowser {

	checkParams Browser 1 unstrict
	
	# Ensure that customer code and environments are provided.
	if [[ ( -z $environment ) ]]; then
		askEnv $customer_code
	fi

	downloadFileIfDoesntExist "silent"

	# Obtain a random host name in order to source the datacentre.
	serverListing=$(getRandomHostnameFromEnvFile)

	# Rename variable for readability.
	servertype=$param4

	# Check third parameter. If HAC/HMC specified, offer to launch the page's URL. If not, parse based on the environment provided.
	if [[ ( $servertype == "hac" ) || ( $servertype == "hmc" ) || ( $servertype == "backoffice" )||( $servertype == "store" ) || ( $servertype == "directhac" ) || ( $servertype == "directhmc" ) ]]; then
		
		# Switch servertype provided.
		case "$servertype" in
			"hac")
				property=ACURL
			;;
			"hmc")
				property=HMCURL
			;;
			"backoffice")
				property=BACKOFFICE_DOMAINS
			;;			
			"directhac"|"directhmc")
				property=NAME_ADMSERVER1
			;;
			"store")NAME_ADMSERVER1
				property=STOREURL
		esac

		launchURLFromProperty $property $servertype "true"

	else

		fullenvironment=$(getPropertyFromEnv ENVIRONMENTTYPE)
		
		# Show options to the user.
		echo "Which site would you like to open for $fullcustomer $fullenvironment?"
		echo "1) HAC page."
		echo "2) HMC page."
		echo "3) BackOffice page."
		echo "4) Storefront."
		echo "5) Direct HAC page from Admin server."
		echo "6) Direct HMC page from Admin server."

		# Read input from the user.
		read -s -n1 page

		# Translate number to os string.
		case $page in 
			1)
				servertype="hac"
				page="ACURL"
				;;
			2)
				servertype="hmc"
				page="HMCURL"
				;;
			3)
				servertype="backoffice"
				page="BACKOFFICE_DOMAINS"
				;;
				
			4)
				servertype="store"
				page="STOREURL"
				;;
			5)
				servertype="directhac"
				page=NAME_ADMSERVER1
				;;
			6)
				servertype="directhmc"
				page=NAME_ADMSERVER1
				;;
			*)
				page="-1"
				;;
		esac

		# If no OS selected, abort, else create the hosts file.
		if [[ "$page" == "-1" ]]; then
			error "Invalid page selected"
		else
			launchURLFromProperty $page $servertype "false"
		fi

	fi

	exit 0

}

function runInfo {

	checkParams Info 1 unstrict

	# Ensure that customer code and environments are provided.
	if [[ ( -z $environment ) ]]; then
		askEnv $customer_code
	fi

	downloadFileIfDoesntExist

	clear

	# Print domains heading.
	printHeading "INFO: $fullcustomer"

	echo "ENVIRONMENT=$fullenvironment"

	# Print whether the customer uses an open or closed model.
	model=$(grep -E 'OPENMODEL' $fullfilepath)
	model=${model/OPEN/}
	model=${model/false/Closed}
	model=${model/true/Open}
	echo $model

	# Print internal and external IP addresses.
	grep -E '^INTERNAL_IP|^EXTERNAL_IP' $fullfilepath | sort -r | tr , '\n'
	
	# Print frontoffice and backoffice domains.
	grep -E '^DOMAINS|^BACKOFFICE_DOMAINS' $fullfilepath | sort -r

	echo

	# Print servers heading.
	printHeading "SERVERS: $fullcustomer"

	# Get raw list of servers and IP addresses.
	rawListing=($(cat $fullfilepath | grep ^NAME | sed $lineEnding | sort -n | uniq))

	# Print total count of servers.
	printf "Total count: ${#rawListing[@]} \n\n"

	# Get raw list of servers from ENV file, with property and value.
	grep_type_listing=($(printf "%s\n" "${rawListing[@]%=*}"))

	# Remove "NAME_" from IP grep listing.
	grep_type_listing=($(printf "%s\n" "${grep_type_listing[@]#*NAME_}"))

	# Keep everything after the equals sign.
	rawListing=($(printf "%s\n" "${rawListing[@]#*=}"))

	# Remove hybris hosting from all sourced hostnames as this will be added later.
	rawListing=($(printf "%s\n" "${rawListing[@]/\.hybrishosting\.com/}"))

	for ((i=0; i<${#grep_type_listing[*]}; i++)); do	

		# Returns the server and IP e.g. ADMSERVER1
		serverTypeAndIP=$(cat $fullfilepath | grep ^${grep_type_listing[$i]}=)

		# Retrieve the server hostname.
		serverHostname=${rawListing[$i]}
		serverHostname=$(echo $serverHostname | tr 'a-z' 'A-Z')

		# Print the resulting entry, splitting the type and IP via a tab character.
		echo -e "$serverHostname   \t ${serverTypeAndIP/=/\t}"

	done

	echo
	exit 0

}

function runConnect {

	# Detect whether the user implied the connection by dropping the "c" parameter.
	if [[ $1 == "implied" ]]; then
		checkParams Connect 2 unstrict
		swapMode
	else
		checkParams Connect 3 unstrict
	fi

	downloadFileIfDoesntExist
	parseServers
	connectUsingAppleScript

}

function runRefresh {

	# Ask the user for their password if it's not included in the script.
	getPassword

	echo "$app Connecting to environment repository..."

	# Defines the repository URL to utilise for the download.
	urlToDownload="https://wiki.hybris.com/pages/downloadallattachments.action?pageId=201953962"

	# Download the files based on previously provided credentials.
	curl -# -L -u$wiki_username:$wiki_password $urlToDownload -o $scriptpath/env.zip
	
	# If curl was successful.
	if [ 0 -eq $? ]; then

		# Clear proceeding download lines.
		clearLastLine
		clearLastLine

		echo "$app Zip downloaded successfully."

		# Delete environment folder.
		rm -r $scriptpath/env

		# Recreate the environment folder.
		mkdir -p $scriptpath/env

		echo -n "$app Unzipping..."

		# Unzip the downloaded environments.
		unzip -q $scriptpath/env.zip -d $scriptpath/env

		# Delete the downloaded zip.
		rm $scriptpath/env.zip

		# Remove the 'last updated' file, then recreate with new date.
		rm $scriptpath/INFO
		echo "lastUpdated=$(date +%j)" > $scriptpath/INFO

		echo "$doneMessage"

		# Update 'Last Modified' dates to current system time.
		for f in "$scriptpath"/env/*; do
			touch "$f"
		done

		echo "$app All environments downloaded successfully."

		exit 0

	else

		# Inform the user the download failed and exit with error.
		error "Download failed"

	fi

}

function runHosts {

	# Show options to the user.
	echo "$app You have selected to generate a hosts file based on the environment files."
	echo "Please select an operating system to proceed:"
	echo "1) Mac"
	echo "2) Windows"
	echo "3) Linux"

	os=

	# Read input from the user.
	read -s -n1 os

	# Translate number to os string.
	case $os in 
		1)
			os="Mac"
			;;
		2)
			os="Windows"
			;;
		3)
			os="Linux"
			;;
		*)
			os="-1"
			;;
	esac

	# If no OS selected, abort, else create the hosts file.
	if [[ "$os" == "-1" ]]; then
		error "No OS selected"
	else
		# All parameters are 
		java -jar $scriptpath/hostbuilder.jar "$scriptpath/env/" $os
		echo "$app Your hosts file (`pwd`/hosts_new) for $os has been successfully generated and placed in the current terminal folder."
		exit 0
	fi

}

function runList {

	verboseList=""

	# Check if environment folder is empty.
	if ! [ "$(ls -A $scriptpath/env)" ]; then
		error "Env folder is empty. Run turtle -r to continue "
	elif [[ "$(ls -1 $scriptpath/env | wc -l)" -le 30 ]]; then
		warn "This is not a complete list of environments. Run turtle -r to ensure all enviroments are listed"
	else

		if [[ ( "$param2" == "v" ) || ( "$param2" == "-v" ) || ( "$param2" == "--verbose" ) ]]; then
			verboseList="true"
		fi

	fi

	# Initialise string which will be built in the for loop.
	buildString=""

	# Loop through each file in the environment folder.
	for entry in $(find $scriptpath/env -type f | grep '.env$')
	do
		
		# Get the filename without the path.
		customerFileName="${entry[@]##*/}"

		# Get the customer's name from the file.
		customerProjectName=$(getPropertyFromEnvFile PROJECTNAME $entry)

		# Get the Hybris Datacenters Info from the file.
		customerDatacents_Id=$(getPropertyFromEnvFile DATACENTERS_ID $entry)

		# Get the Hybris Version Info from the file.
		customerHybrisVersion=$(getPropertyFromEnvFile HYBRIS_VERSION $entry)

		

		# If the length of the customer's filename is >= 16.
		if [[ ${#customerFileName} -ge 16 ]]; then
			
			# Cut string and add elipsis.
			buildString="$buildString${customerFileName:0:15}... \t $customerProjectName \t \033[32m${customerDatacents_Id:4}\033[37m,$customerHybrisVersion\n"

		else

			# No elipsis required, add string as normal.
			buildString="$buildString$customerFileName \t\t $customerProjectName \t \033[32m${customerDatacents_Id:4}\033[37m,$customerHybrisVersion\n"

		fi

	done
	
	# Print the built string.
	echo -ne $buildString

	exit 0

}

function runJump {

	checkParams Jumpbox 1 strict
	passedDC=$customer_code

	# Switch on the inputted datacentre.
	case "$passedDC" in
		"ma")
			serverListing=("inf-p-ma-ljp-001")
		;;
		"fr")
			serverListing=("inf-p-fr-ljp-001")
		;;
		*)
			error "Unknown datacentre '$passedDC'. Options include 'ma' or 'fr'"
	esac

	# Jumpbox servers begin with inf, and their customer code is interpreted as such.
	customer_code="inf"

	# Jumpbox servers are implied to be used for production.
	environment="p"

	# Connect to server sourced from above switch.
	connectUsingAppleScript

}

function runWiki {

	checkParams Wiki 1 strict
	downloadFileIfDoesntExist

	# Replace spaces in the customer name with pluses for the URL.
	customerWithPluses="${fullcustomer//\ /+}"

	# Show options to the user.
	echo "Which wiki page would you like to open for $fullcustomer?"
	echo "1) Environment Page"
	echo "2) Test Results"
	echo "3) Project Page"
	echo "4) Automated Deployment Procedure"

	# Read input from the user.
	read -s -n1 page

	# Translate number to os string.
	case $page in 
		1)
			urlToLaunch="https://wiki.hybris.com/display/MSPIPS/$customerWithPluses"
			;;
		2)
			urlToLaunch="https://wiki.hybris.com/display/cstw/$customerWithPluses+Test+Results"
			;;
		3)
			urlToLaunch="https://wiki.hybris.com/display/MSS/$customerWithPluses+hCS"
			;;
		4)
			urlToLaunch="https://wiki.hybris.com/display/MSPIPS/Automated+Deployment+Procedure+-+$customerWithPluses"
			;;
		*)
			page="-1"
			;;
	esac

	# If no OS selected, abort, else create the hosts file.
	if [[ "$page" == "-1" ]]; then
		error "No page selected"
	else
		open $urlToLaunch
	fi

}

#information AD password, Files From and Files To used by runPush and runPull
function info {
	# Ensure the user is connected to the right VPN and exit if not.
	vpnCheck error
	echo Current Path: `pwd`
	read -r -p "AD Password:" -s passwd
	echo
	read -r -p "$app Please enter your SRC path [From]: " src_path
	read -r -p "$app Please enter your DESC path [To]:" desc_path	
	}

function runPushsync {

/usr/bin/expect <<EOF
set time 3
spawn rsync -avzIh --exclude=.\[!.\]* -e ssh --progress $src_path $hybris_username@$i.hybrishosting.com:${desc_path:-/home/$hybris_username/}
expect  {
	"*yes/no" { send "yes\r"; exp_continue }
	"password:" { send "$passwd\r"; exp_continue }
	}
EOF

}

function runPush {
	# Detect whether the user implied the connection by dropping the "c" parameter.
	if [[ $1 == "implied" ]]; then
		checkParams Push 2 unstrict
		swapMode
	else
		checkParams Push 3 unstrict
	fi

	downloadFileIfDoesntExist
	parseServers
	info

	# rsync files from local to remote 
    for i in ${serverListing[*]}; do
		runPushsync
	done
}

function runPullsync {

/usr/bin/expect <<EOF
spawn rsync -avzIh --exclude=.\[!.\]* -e ssh --progress $hybris_username@$i.hybrishosting.com:${src_path:-/home/$hybris_username/} ${desc_path:-./temp/$i/}
expect  {
	"*yes/no" { send "yes\r"; exp_continue }
	"password:" { send "$passwd\r"; exp_continue }
	}
catch wait reason

EOF

}

function runPull {
	# Detect whether the user implied the connection by dropping the "c" parameter.
	if [[ $1 == "implied" ]]; then
		checkParams Pull 2 unstrict
		swapMode
	else
		checkParams Pull 3 unstrict
	fi

	downloadFileIfDoesntExist
	parseServers
	info
	
	# rsync files from remote to local
    for i in ${serverListing[*]}; do
		runPullsync

	done
}



function sshCopyJobs {

/usr/bin/expect <<-EOF
set time 10
spawn ssh-copy-id -f $hybris_username@$i.hybrishosting.com
expect -re {
	"*yes/no" { send "yes\r"; exp_continue }
	"*password:" { send "$passwd\r" }
	}
EOF

}



function dc_start {
	case "$param2" in
		"ma"|"MA")			
			DC="209.202.160.253:10443"
			openfortivpn_up
		;;
		"fr"|"FR")
			DC="62.209.35.109:10443"
			openfortivpn_up
		;;		
		"all"|"ALL"|"All")
			DC="209.202.160.253:10443"
			openfortivpn_up
			DC="62.209.35.109:10443"
			openfortivpn_up
		;;		
		*)
			warn "Unknown DC '$DC'" 
		;;
	esac
}


function dc_stop {
	case "$param2" in
		"ma"|"MA")			
			DC="|grep 209.202.160.253"
			openfortivpn_down
		;;
		"fr"|"FR")
			DC="|grep 62.209.35.109"
			openfortivpn_down
		;;		
		"all"|"ALL"|"All")
			DC=""
			openfortivpn_down
		;;		
		*)
			warn "Unknown DC '$DC'" 
		;;
	esac
}


function openfortivpn_up {
	#trusted_cert=`echo $sudopwd|sudo -S openfortivpn $DC -u $hybris_username -p $pwd | grep trusted-cert | head -n 1 | awk -F "--" ' { print $2} '`  	
	trusted_cert=`sudo -S openfortivpn $DC -u $hybris_username -p $pwd | grep trusted-cert | head -n 1 | awk -F "--" ' { print $2} '` >/dev/null 
	#echo $sudopwd | sudo -S openfortivpn $DC -u $hybris_username -p $pwd --$trusted_cert &
	nohup sudo -S openfortivpn $DC -u $hybris_username -p $pwd --$trusted_cert >nohup.out 2>&1 &

}


function openfortivpn_down {

	ps -ef | grep openfortivpn $DC | grep -v grep | awk '{print $2}' | sudo xargs kill -9

	echo "VPN Shutdown"
	
}



function runVpn {
	# 
	checkParams Vpn 2 strict
	mode=$param3
 

	case "$mode" in
		"start")
#			read -r -p "Sudo Password:" -s sudopwd
#			echo
			read -r -p "VPN RSA Password:" -s pwd
			echo			
			dc_start
								

		;;
		"stop")
			dc_stop
			
		;;	
		"restart")
			dc_stop
			
		;;	
		"status")
			getCurrentVPNConnection
			
		;;		
		*)
			warn "Unknown DC '$DC'" 
		;;
	esac
}

function runSettings {
	
	# Edit settings using editor outlined in config file, otherwise use vim as default.
	if ! [[ -z $defaultEditor ]]; then
		$defaultEditor $scriptpath/CONFIG
	else
		warn "No default editor found - assuming vim"
		vim $scriptpath/CONFIG
	fi

	echo "$app Settings changed successfully."

	exit 0
}

#####################
#       Main        #
#####################

# Load user settings and abort if they cannot be found.
loadSettings

# If no parameters provided.
if [[ ( $numberOfParams -eq 0 ) ]]; then
	runUsage
else

	# Show help screen if requested by the user, or settings.
	case "$mode" in
		"h"|"-h"|"--help")
			runHelp
		;;
		"s"|"-s"|"--settings")
			runSettings
		;;
	esac

fi

# Check that all required settings are provided.
checkConfig

# Create environment folder if it doesn't already exist.
mkdir -p $scriptpath/env

# Switch for modes.
case "$mode" in
	"b"|"-b"|"--browser")
		runBrowser
	;;
	"i"|"-i"|"--info")
		runInfo
	;;
	"c"|"-c"|"--connect")
		runConnect "normal"
	;;
	"r"|"-r"|"--refresh")
		runRefresh
	;;
	"y"|"-y"|"--hosts")
		runHosts
	;;
	"l"|"-l"|"--list")
		runList
	;;
	"j"|"-j"|"--jump")
		runJump
	;;
	"w"|"-w"|"--wiki")
		runWiki
	;;
	"push"|"-push"|"--push")
	    runPush "normal"
	;;
	"pull"|"-pull"|"--pull")
	    runPull "normal"
	;;
	"vpn"|"-vpn"|"--vpn")
	    runVpn  
	;;
	*)
		warn "Unknown mode '$mode' - assuming Connect"
		runConnect "implied"
	;;
esac

exit 0
