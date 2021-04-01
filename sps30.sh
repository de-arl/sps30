#!/bin/bash
#===============================================================================
#
#	       FILE: 	sps30.sh
#
#	      USAGE: 	./sps30.sh [options] [<arguments>]
#
#	DESCRIPTION: 	Command line tool to read 
#		     		    and log data of Sensirion SPS30
#		     		    Particulate Matter Sensor.
#
#	    OPTIONS: 	See function 'usage' below
#  REQUIREMENTS: 	Sensirion SPS30 Linux Kernel Driver
#		  		      https://github.com/Sensirion/linux-sps30
#	      NOTES: 	Function initialize_sensor expects SPS30 
#		         		connected to I2C1, change if necessary
#	     AUTHOR: 	Andreas Laible, a.laible@tum.de
#	    VERSION: 	1.1
#       CREATED: 	01.04.2021
#===============================================================================



#----------------------------------------------------------------------
# Case SIGHUP, SIGINT (ctrl+c) and SIGQUIT (ctrl+\) signals are traped, 
# cleanup and exit
#----------------------------------------------------------------------
trap "clear; exit 0" 1 2 3 



#----------------------------------------------------------------------
# Set default sensor read INTERVAL
#----------------------------------------------------------------------
INTERVAL=0



#----------------------------------------------------------------------
# Set path to SPS30 device
#----------------------------------------------------------------------
DEVICE_PATH="/sys/bus/iio/devices/iio:device0"



#----------------------------------------------------------------------
# Set path to initialize SPS30 as I2C device
#----------------------------------------------------------------------
I2C_BUS="/sys/class/i2c-adapter/i2c-1/new_device"



#===  FUNCTION  ================================================================
#	 NAME: usage
# DESCRIPTION: Diplay usage information
#   PARAMETER: ---
#===============================================================================
usage(){
	cat <<- EOT
		=========================  sps30.sh  ==========================
		USAGE: ./sps30.sh [options] [<arguments>]

		OPTIONS:
		-o LOGFILE	Log data to LOGFILE, comma separated csv
		-i INTERVAL	Sensor read INTERVAL in seconds, defaults to 60
		-v		Verbose mode
		-h		Help

		Command line tool to read and log data of
		Sensirion SPS30 Particulate Matter Sensor.
		===============================================================
		EOT
	exit 0
}    #------------  end of function usage  ------------



#===  FUNCTION  ================================================================
#	     NAME: initialize_sensor
# DESCRIPTION: Check if sensor is online, if not load modules
#	       and initialize device
#   PARAMETER: ---
#===============================================================================
initialize_sensor(){
	if [ -n "$MODE_VERBOSE" ]; then
		echo -e "Sensor initialization necessary, need root priviliges:"
	fi
	sudo modprobe industrialio
	sudo modprobe crc8
	sudo modprobe sps30
	sleep 5
	sudo echo sps30 0x69 | sudo tee "$I2C_BUS"	
	echo -e "Sensor initialized!\n'"
}    #------------  end of function initialize_sensor  ------------



#===  FUNCTION  ===============================================================
#	 NAME: read_sensor 
# DESCRIPTION: Read sensor data and store values in variables
#   PARAMETER: ---
#==============================================================================
read_sensor(){
	TIME_READ=$(date +"%Y-%m-%d %T")
	PM_1=$(cat "$DEVICE_PATH"/in_massconcentration_pm1_input);
	PM_2p5=$(cat "$DEVICE_PATH"/in_massconcentration_pm2p5_input);
	PM_4=$(cat "$DEVICE_PATH"/in_massconcentration_pm4_input);
	PM_10=$(cat "$DEVICE_PATH"/in_massconcentration_pm10_input);
}    #------------  end of function read_sensor  ------------



#===  FUNCTION  ================================================================
#	     NAME: display_output 
# DESCRIPTION: Display sensor data, refresh every $INTERVAL 
#   PARAMETER: ---
#===============================================================================
display_output(){
    if [ -n "$MODE_VERBOSE" ]; then
        clear
        echo "==============  SPS30 Particulate Matter Sensor  =============="
        time_info
		sensor_info
        echo "(Press ctrl+c to quit)"
        echo "==============================================================="
        tput cuu 15 # Move cursor 12 lines up
    else
		display_data
    fi

}    #------------  end of function display_output  ------------



#===  FUNCTION  ================================================================
#	     NAME: time_info 
# DESCRIPTION: Part of display_output, displays information about time schedule
#   PARAMETER: ---
#===============================================================================
time_info(){
	#---------------------------------------------------------------
	# Adapt output if -o is passed
	#---------------------------------------------------------------
	if [ -z "$MODE_LOG" ]; then
		printf " Read and display mode,\nno logging of data.\n"; 
	else 
		FILEPATH=$(realpath "$LOGFILE")
		echo -e " Data logging mode."
	printf "Data log file: %s\n" "$FILEPATH"; 
	fi
	printf "Last sensor read: %s\n" "$TIME_READ"
	printf "Next sensor read: %s\n" "$TIME_SCHEDULED"
}    #------------  end of function time_info  ------------ 




#===  FUNCTION  ================================================================
#	     NAME: sensor_info 
# DESCRIPTION: Part of display_output, displays sensor data
#   PARAMETER: ---
#===============================================================================
sensor_info(){
	printf "\v\tPM_1\t%.2f\n" "$PM_1" 
	printf "\tPM_2.5\t%.2f\n" "$PM_2p5"
	printf "\tPM_4\t%.2f\n" "$PM_4"
	printf "\tPM_10\t%.2f\n" "$PM_10"
	echo -e  "\vUNIT [PM_i] = 10E-06 g / m^3"
	echo "PM_i is the Concentration of atmospheric Particulate Matter,"
	echo "smaller than i micrometers in microgram per cubic meter."
}   #------------  end of function sensor_info  ------------



#===  FUNCTION  ================================================================
#	     NAME: log_output 
# DESCRIPTION: Append sensor data and time to LOGFILE as csv
#	       TIME,PM_1,PM_2p5,PM_4,PM_10
#   PARAMETER: ---
#===============================================================================
log_output(){
	DATA=$(printf ",%.2f,%.2f,%.2f,%.2f\n" "$PM_1" "$PM_2p5" "$PM_4" "$PM_10") 
	echo "$TIME_READ""$DATA">> "$LOGFILE" 
}   #------------  end of function log_output  ------------



#===  FUNCTION  ================================================================
#	     NAME: display_data
# DESCRIPTION: Display sensor data and time as csv
#	       TIME,PM_1,PM_2p5,PM_4,PM_10
#   PARAMETER: ---
#===============================================================================
display_data(){
	DATA=$(printf " %.2f %.2f %.2f %.2f\n" "$PM_1" "$PM_2p5" "$PM_4" "$PM_10") 
	echo "$TIME_READ""$DATA"
}   #------------  end of function display_data  ------------



#===  FUNCTION =================================================================
#        NAME: confirm_file
# DESCRIPTION: Check if $LOGFILE passed to skript exists,
#              if so, ask confirmation to write to
#===============================================================================
confirm_file(){
	#-------------------------------------------------------------------
	# Test loop wether file exists, runs until valid new filename is
	# provided or user confirms to continue
	#-------------------------------------------------------------------
	while [ -e "$LOGFILE" ]; do
		#-----------------------------------------------------------
		# Choose way of action depending wether existing input 
		# is directory or file.
		#-----------------------------------------------------------
		if [ -d "$LOGFILE" ]; then
			printf "%s is a directory.\n" "$LOGFILE"
            read -r -p "Enter new filename (ctrl+c to quit): " LOGFILE;
		else
			printf "%s exists.\n" "$LOGFILE"
			#---------------------------------------------------
			# Ask for confirmation to continue case file exists 
			# and handle user input
			#---------------------------------------------------
			read -r -p "Continue anyway? (y/n) " ANSWER
			case $ANSWER in 
				[yY]* ) break
						;;
				[nN]* ) read -r -p "Enter new filename (ctrl+c to quit): " LOGFILE;
						;;
				* )		echo "Invalid option, exiting."
						exit 0
						;;
			esac
		fi
	done
}    #------------  end of function confirm_file  ------------



#===  FUNCTION  ================================================================
#	     NAME: init 
# DESCRIPTION: Set operation mode and variables depending on
#	       options passed to the script
#   PARAMETER: All options passed to the skript 
#              are passed to init
#===============================================================================
init(){
	#---------------------------------------------------------------------
	# check which options are passed to the script
	#---------------------------------------------------------------------
	while getopts ":o:i:vh" OPT; do
		case "$OPT" in
			o) MODE_LOG=1
			   #---------------------------------------------------------
			   # Execute function "usage" if 
			   # option "-o" is passed without argument, 
		   	   # else set LOGFILE
			   #---------------------------------------------------------
			   if [ -z "$OPTARG" ]; then usage; else LOGFILE="$OPTARG"; fi
			   ;;
		   	i) #---------------------------------------------------------
			   # Execute function "usage" if 
			   # option "-i" is passed without argument, 
		   	   # else set INTERVAL
			   #---------------------------------------------------------
			   if [ -z "$OPTARG" ]; then usage; else INTERVAL="$OPTARG"; fi
		  	   ;;
			v) MODE_VERBOSE=1
			   ;;
			h) usage 
			   ;;
			?) usage
			   ;;
		esac; done
}    #------------  end of function init  ------------




#===  FUNCTION  ================================================================
#	     NAME: main 
# DESCRIPTION: Run the program 
#   PARAMETER: All options passed to the skript 
#              are passed to main
#===============================================================================
main(){
	init "$@";
	#---------------------------------------------------------------------------
	# Executes function "confirm_file" if script is invoked with -o and 
	# file passed as argument exists.
	#---------------------------------------------------------------------------
	if [ -n "$MODE_LOG" ] && [ -e "$LOGFILE" ]; then confirm_file; fi
	if [ -n "$MODE_VERBOSE" ]; then echo "Initializing..."; fi
	#---------------------------------------------------------------------------
	# Checks wether SPS30 device is initialized already, 
	# if not, executes function "initialize_sensor"
	#---------------------------------------------------------------------------
	if [[ ! -d "/sys/bus/iio/devices/iio:device0" ]]; then initialize_sensor; fi
	#---------------------------------------------------------------------------
	# Endless loop, executes functions "read_sensor" and 
	# "display_output" [and "log_output", if -o is passed to the script] 
	# then waits for $INTERVAL seconds.
	#---------------------------------------------------------------------------
	while true; do
		read_sensor
		if [ -n "$MODE_VERBOSE" ]; then tput cuu 1; tput el; fi
		TIME_SCHEDULED=$(date +"%Y-%m-%d %T" --date "now $INTERVAL seconds")
		display_output
		if [ -n "$MODE_LOG" ]; then log_output; fi
		sleep "$INTERVAL"
	done
}    #------------  end of function main  ------------



#-----------------------------------------------------------------------------
# Execute function "main" with all options and arguments passed to the script
#-----------------------------------------------------------------------------
main "$@"

exit 0 
