# Tools to use Sensirion SPS30 Particulate Matter sensor with Raspberry Pi
## sps30.sh
### Description
This script is a command line tool to read and display data from the Sensirion SPS30 Particulate Matter sensor.
### Requirements
Before you can use this tool to read data from the sensor, you have to install the driver provided by the manufacturer: [linux-sps30](https://github.com/Sensirion/linux-sps30).
### Installation
Written in pure bash, **sps30.sh** does not need to be installed. You only have to make it executable, then you can run the tool.  
'''
sudo chmod +x sps30.sh
./sps30.sh
'''
### Usage
#### Read sensor and display data
To display data, run:  
'''
./sps30.sh
''' 
#### Read sensor and log data
To log sensor data to a file in csv format, invoke the tool like this:  
'''
./sps30.sh -o path/to/your/logfile.csv
'''
#### Set sensor read interval
The default interval for the tool to wait between sensor reads is 60 seconds.  
To change the interval, invoke the tool like this:  
'''
./sps30.sh -i 30
'''
#### Quiet Mode
In quiet mode, sensor data is not displayed:  
'''
./sps30.sh -q
'''
## sps30_service.sh, sps30.service and sps30.timer
The script **sps30_logger.sh** provides functionality to read and
log data from SPS30 Particulate Matter sensor on a given time interval
to a given logfile. It is intended to be used with systemd. This way, 
logging data from SPS30 can be automated easily. **sps30.service** and 
**sps30.timer** are systemd unit files to run **sps30_logger.sh** with 
systemd.  
### How it works
Basically **sps30_logger.sh** reads the sensor and logs the data to 
a logfile. Although you can run it manually it is intended to be used
with systemd. Therefore it is started with **sps30.service**. 
**sps30_logger.sh** provides two operating modes. The loop mode is
intended to read and log sensor data in short intervals. In this mode
the service starts the logger on boot time once and the logger runs 
continously.
The oneshot mode is intended to read and log sensor data in long time 
intervals. In this scenario the systemd timer frequently runs the 
systemd service which spawns the logger. Each time the service is 
activated by the timer, it starts the logger which reads and logs sensor
data once and exits. This way of operation reduces energy and CPU usage.
### Usage
You have to provide the systemd service with the correct 
path to the script. Then you can copy the service and timer unit to 
the systemd directory and activate the service or the timer. 
__Provide the systemd service with the actual path to **sps30_logger.sh**.__ 
In the service file **sps30.service** edit line 8:
'''
ExecStart=/path/to/git/sps30/sps30_service.sh
'''
Then copy the **sps30.service** and **sps30.timer** to the systemd directory:
'''
sudo cp sps30.service /etc/systemd/system
sudo cp sps30.timer /etc/systemd/system
'''
If you want to read the sensor in short time intervals, use the service without 
the timer. In **sps30_logger.sh** line 89 set the mode and in line 95 set 
the data log interval in seconds:
'''
MODE="loop"
INTERVAL=3
'''
Then activate the service:
'''
sudo systemctl enable sps30.service
sudo systemctl start sps30.service
'''
If you want to log the data in long intervals, to minimize CPU time and 
safe energy, use **sps30_logger.sh** with **sps30.timer**. Edit 
**sps30_service.sh** and set in line 89:
'''
MODE="oneshot"
'''
Set the log interval in line 6 of the timer file **sps30.timer** 
(10 minutes in the example):
'''
OnUnitActiveSec=10min
'''
Then start the timer.
'''
sudo systemctl enable sps30.timer
sudo systemctl start sps30.timer
'''
**Usage information for sps30.service and sps30.timer is also 
provided within sps30_logger.sh**
# Information
Feel free to contact me if you have questions. Contact information
is provided in the scripts.
                                            de-arl,      Munich 2021-04-13
