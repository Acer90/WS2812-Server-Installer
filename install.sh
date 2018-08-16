#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
bold=$(tput bold)
normal=$(tput sgr0)
default_folder='/ws2812-server'
install_service=False
w_dir=$PWD

printf "Start Installion?[y/${bold}n${normal}]: "
read install

if [ "$install" = "y" ] 
then
	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Start installing WS2812-Server${NC} \n"
	
	while true; do
		printf "Set Install-Directory:[${bold}$PWD$default_folder${normal}]: "
		read install_dir

		if [ "$install_dir" = "" ] 
		then 
			install_dir="$PWD$default_folder"
			sudo mkdir "$install_dir"
			break
		elif [ -d "$install_dir" ] && [ -x "$install_dir" ];
		then
			install_dir="$install_dir"
			break
		else
			now="$(date +"%T.%N")"
			printf "${bold}$now${normal} - ${RED}${bold}Directory not found, or you don\'t have Premission for this Directory!${normal}${NC} \n"
		fi
	done
	
	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Install-Directory set to: ${bold}$install_dir${normal}${NC} \n"

	if [ -d "$install_dir" ]; 
	then 
		printf "${RED}Waring Install-Directory? already exist! Remove Directory?[y/${bold}n${normal}]${NC}: "
		read install_dir_del
		if [ "$install_dir_del" = "y" ] 
		then
			rm -Rf $install_dir
			now="$(date +"%T.%N")"
			printf "${bold}$now${normal} - ${GREEN}Directory remove: (${bold}$install_dir${normal})${NC} \n"
			
		else
			printf "${bold}${RED}INSTALLATION STOPPED!(Directory must be empty!)${NC}${normal} \n"
			exit
		fi
	fi

	while true; do
		printf "Install as Service:[${bold}y/n${normal}]: "
		read install_as_service

		if [ "$install_as_service" = "y" ] 
		then 
			install_service=True
			break
		elif [ "$install_as_service" = "n" ] 
		then
			install_service=False
			break
		fi
	done	

	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Updateing Package-Lists${NC} \n"
	#sudo apt-get update
	
	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Installing the following Packages: ${bold}build-essential python python-pip python-dev unzip wget scons swig git${normal}${NC} \n"
	sudo apt-get -y install build-essential python python-pip python-dev unzip wget scons swig git

	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Installing WS281X Library${NC} \n"
	cd $w_dir
	rm master.zip
	sudo rm -rf rpi_ws281x-master
	wget https://github.com/jgarff/rpi_ws281x/archive/master.zip
	unzip -o master.zip
	cd rpi_ws281x-master
	#sudo scons
	cd python
	#sudo python setup.py install

	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Installing pigpio Library${NC} \n"
	cd $w_dir
	rm pigpio.zip
	sudo rm -rf PIGPIO
	wget abyz.me.uk/rpi/pigpio/pigpio.zip
	unzip pigpio.zip
	cd PIGPIO
	#make
	#sudo make install
	
	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Installing ${bold}gitpython${normal}${NC} \n"
	sudo pip install --upgrade gitpython

	printf "${bold}$now${normal} - ${GREEN}Clone Git Repository (${bold}https://github.com/Acer90/PI-WS2812-Server.git${normal})${NC} \n"
	now="$(date +"%T.%N")"	
	sudo git clone https://github.com/Acer90/PI-WS2812-Server.git $install_dir

	now="$(date +"%T.%N")"
	printf "${bold}$now${normal} - ${GREEN}Run Python-Setupfile (${bold}setup.py${normal})${NC} \n"
	cd $install_dir
	chmod 755 setup.py
	chmod 755 run.py
	sudo python setup.py INSTALL

	if [ $install_service ]
	then
		now="$(date +"%T.%N")"
		printf "${bold}$now${normal} - ${GREEN}Installing Service (${bold}ws2812-server${normal})${NC} \n"
		printf "[Unit]
Description=Python WS2812-Server
After=syslog.target

[Service]
Type=simple
WorkingDirectory=$install_dir
ExecStart=/usr/bin/python "$install_dir/run.py" ASSERVICE
SyslogIdentifier=ws2812-server
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/ws2812-server.service
		
		sudo chmod 644 /lib/systemd/system/ws2812-server.service
		sudo systemctl daemon-reload
		sudo systemctl enable ws2812-server.service
		sudo systemctl start ws2812-server.service

	fi
else
	printf "${bold}${RED}INSTALLATION STOPPED!${NC}${normal} \n"
	exit
fi