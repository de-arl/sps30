# Tools to use Sensirion SPS30 Particulate Matter sensor with Raspberry Pi
## sps30.sh
### Description
This script is a command line tool to read and display data from the Sensirion SPS30 Particulate Matter sensor.
### Requirements
Before you can use this tool to read data from the sensor, you have to install the driver provided by the manufacturer: [linux-sps30](https://github.com/Sensirion/linux-sps30).
### Installation
Written in pure bash, _sps30.sh_ does not need to be installed. You only have to make it executable, then you can run the tool.
```
# chmod +x sps30.sh
$ ./sps30.sh
```
### Usage
#### Read sensor and display data
To display data, run:
```
$ ./sps30.sh
```
Verbose mode:
'''
$ ./sps30.sh -v
'''
### Example output
Normal mode:
'''
2021-04-01 18:19:20 4.06 4.42 4.43 4.44
'''
(date time PM_1 PM_2.5 PM4 PM10)
```
==============  SPS30 Particulate Matter Sensor  ==============
 Data logging mode.
Data log file: /path/to/logfile.csv
Last sensor read: 2021-03-14 20:55:53
Next sensor read: 2021-03-14 20:56:08
	PM_1	2.82
	PM_2.5	3.00
	PM_4	2.99
	PM_10	2.97
UNIT [PM_i] = 10E-06 g / m^3
PM_i is the Concentration of atmospheric Particulate Matter,
smaller than i micrometers in microgram per cubic meter.
(Press ctrl+c to quit)
===============================================================
```
#### Read sensor and log data
To log sensor data to a file in csv format, invoke the tool like this:
```
$ ./sps30.sh -o path/to/your/logfile.csv
```
#### Set sensor read interval
The default interval for the tool to wait between sensor reads is 60 seconds.
To change the interval, invoke the tool like this:
```
$ ./sps30.sh -i 30
```

------------------------------------------------------------------


## sps30_service.sh, sps30.service and sps30.timer
The script _sps30_logger.sh_ provides functionality to read and
log data from SPS30 Particulate Matter sensor on a given time interval
to a given logfile. It is intended to be used with systemd. This way,
logging data from SPS30 can be automated easily. _sps30.service_ and
_sps30.timer_ are systemd unit files to run _sps30_logger.sh_ with
systemd.
### How it works
Basically _sps30_logger.sh_ reads the sensor and logs the data to
a logfile. Although you can run it manually it is intended to be used
with systemd. Therefore it is started with _sps30.service_.
_sps30_logger.sh_ provides two operating modes. The loop mode is
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
**Provide the systemd service with the actual path to _sps30_logger.sh_.**
In the service file _sps30.service_ edit line 8:
```
ExecStart=/path/to/git/sps30/sps30_service.sh
```
Then copy the _sps30.service_ and _sps30.timer_ to the systemd directory:
```
# cp sps30.service /etc/systemd/system
# cp sps30.timer /etc/systemd/system
```
If you want to read the sensor in short time intervals, use the service without
the timer. In _sps30_logger.sh_ line 89 set the mode and in line 95 set
the data log interval in seconds:
```
MODE="loop"
INTERVAL=3
```
Then activate the service:
```
# systemctl enable sps30.service
# systemctl start sps30.service
```
If you want to log the data in long intervals, to minimize CPU time and
safe energy, use _sps30_logger.sh_ with _sps30.timer_. Edit
_sps30_service.sh_ and set in line 89:
```
MODE="oneshot"
```
Set the log interval in line 6 of the timer file _sps30.timer_
(10 minutes in the example):
```
OnUnitActiveSec=10min
```
Then start the timer.
```
# systemctl enable sps30.timer
# systemctl start sps30.timer
```
**Usage information for sps30.service and sps30.timer is also
provided within sps30_logger.sh**
# Information
Feel free to contact me if you have questions. Contact information
is provided in the scripts.
                                            de-arl,      Munich 2021-04-13
