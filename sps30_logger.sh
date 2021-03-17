#!/bin/bash
#===============================================================================
#
#	       FILE: 	sps30_service.sh
#
#	      USAGE: 	To use with systemd:
#               Invoke the script with the corresponding 
#               systemd service unit: sps30.service
#               or use the corresponding systemd timer unit: sps30.timer
#
#               To run with systemd and use sps30.service and sps30.timer, 
#               YOU MUST EDIT sps30.service, 
#               search for the line 
#               ExecStart=/path/to/sps30_service.sh
#               and set the correct path to the script file! Then copy
#               timer and service to systemd directory:
#               # cp sps30.service /etc/systemd/system
#               # cp sps30.timer /etc/systemd/system
#
#               To run always on boot (set MODE="loop", see below):
#                # cp sps30.service /etc/systemd/system
#                # systemctl enable sps30.service
#                # systemctl start sps30.service
#
#               To run with timer (set MODE="oneshot", see below):
#                # systemctl enable sps30.timer
#                # systemctl start sps30.timer
#               
#               To stop and disable service:
#                # systemctl stop sps30.service
#                # systemctl disable sps30.service
#               To stop and disable timer:
#                # systemctl stop sps30.timer
#                # systemctl disable sps30.timer
#               To check status:
#                # systemctl status sps30.service
#                # systemctl status sps30.timer
#               For more options see 
#               $ man (5) systemd
#
#               To run as a daemon:
#               setsid ./sps30_service.sh >/dev/null 2>&1 < /dev/null &
#
#	DESCRIPTION: 	Bash script to use with corresponding systemd service
#               sps30.service or systemd timer sps30.timer
#               or to run as daemon to read 
#		     		    and log data of Sensirion SPS30
#		     		    Particulate Matter Sensor.
#								Appends data as csv to logfile like this:
#								TIME,PM_1,PM_2p5,PM_4,PM_10
#
#	    OPTIONS: 	Set the LOGFILE variable
#               Set the data log INTERVAL variable
#               Set the operating MODE variable
#
#REQUIREMENTS: 	Sensirion SPS30 Linux Kernel Driver
#		  		      https://github.com/Sensirion/linux-sps30
#
#	      NOTES: 	If you intend to log sensor data with large time interval,
#               set MODE to oneshot and trigger systemd service unit 
#               sps30.service with corresponding sps30.timer, this safes
#               energy and system ressources.
#               To set data log interval if used with the systemd timer
#               edit sps30.timer, search for the line 
#               OnUnitActiveSec=10min
#               
#               
#		        
#	     AUTHOR: 	Andreas Laible, a.laible@tum.de
#	    VERSION: 	1.0
#     CREATED: 	13.03.2020
#===============================================================================


#-------------------------------------------------------------------------------
# Set path to logfile here, data is appended only
#-------------------------------------------------------------------------------
LOGFILE=""$HOME"/sps30_logfile.csv"


#-------------------------------------------------------------------------------
# Set operation mode:
# Set MODE="oneshot" to run in combination with systemd timer
# If MODE="oneshot", script reads data once, logs data to file and exits
#
# Set MODE="loop" to run the script with the systemd service without timer.
# MODE="loop" activates endless loop: read data, log data, wait for INTERVAL 
#-------------------------------------------------------------------------------
MODE="loop"


#-------------------------------------------------------------------------------
# Set data log interval in seconds, set 0 for maximum frequency
#-------------------------------------------------------------------------------
INTERVAL=1


#-------------------------------------------------------------------------------
# Set path to SDS30 device
#-------------------------------------------------------------------------------
DEVICE_PATH="/sys/bus/iio/devices/iio:device0";


#-------------------------------------------------------------------------------
# Set I2C bus here
#-------------------------------------------------------------------------------
INSTANTIATE_I2C_DEVICE="/sys/class/i2c-adapter/i2c-1/new_device"


#-------------------------------------------------------------------------------
# Load modules and instantiate SPS30 device, if necessary
#-------------------------------------------------------------------------------
initialize_device(){
if [[ ! -d "$DEVICE_PATH" ]]; then
 sudo modprobe industrialio;
 sudo modprobe crc8;
 sudo modprobe sps30;
 sleep 3 # Without adequate time delay here, the following command fails
 echo sps30 0x69 | sudo tee "$INSTANTIATE_I2C_DEVICE";
fi
}


#===  FUNCTION  ================================================================
#        NAME: log_data_loop
# DESCRIPTION: Reads SPS30 sensor and appends data to logfile in an endless loop
#   PARAMETER: ---
#===============================================================================
log_data_loop(){ 
while true; do
 TIME=$(date +"%Y-%m-%d %T"); # Set time format here (see man date)
 PM_2p5=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm2p5_input)
 PM_1=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm1_input)
 PM_4=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm4_input)
 PM_10=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm10_input)
 DATA=$(printf "%.2f,%.2f,%.2f,%.2f\n" "$PM_1" "$PM_2p5" "$PM_4" "$PM_10") 
 echo "$TIME","$DATA" >> "$LOGFILE"
 sleep "$INTERVAL" 
done
} #------------  end of function log_data_loop  ------------


#===  FUNCTION  ================================================================
#        NAME: log_data_oneshot
# DESCRIPTION: Reads SPS30 sensor and appends data to LOGFILE
#   PARAMETER: ---
#===============================================================================
log_data_oneshot(){
 TIME=$(date +"%Y-%m-%d %T"); # Set time format here (see man date)
 PM_2p5=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm2p5_input)
 PM_1=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm1_input)
 PM_4=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm4_input)
 PM_10=$(cat /sys/bus/iio/devices/iio:device0/in_massconcentration_pm10_input)
 DATA=$(printf "%.2f,%.2f,%.2f,%.2f\n" "$PM_1" "$PM_2p5" "$PM_4" "$PM_10") 
 echo "$TIME","$DATA" >> "$LOGFILE"
} #------------  end of function log_data_oneshot  ------------

#===  FUNCTION  ================================================================
#        NAME: main
# DESCRIPTION: Run either data logging loop or log data once depending on MODE
#   PARAMETER: ---
#===============================================================================
main(){
 initialize_device;
 if [ $MODE == "loop" ]; 
  then log_data_loop;
 elif [ $MODE == "oneshot" ];
  then log_data_oneshot;
 else
  echo -e "Invalid mode set, must set MODE to \"loop\" or \"oneshot\"" 
 fi
} #------------  end of function main  ------------ 

#-------------------------------------------------------------------------------
# Run
#-------------------------------------------------------------------------------
main;
exit 0 
