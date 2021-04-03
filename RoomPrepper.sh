#!/bin/bash

# Usage: ./RoomPrepper.sh

# Setting colored output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# set variables and base folders

if [ -z "$RoomBASEDIR" ]; then
  echo 'Base Directoy not set'
  read -p 'Type in the Base Directory: ' RoomBASEDIR
  echo "export RoomBASEDIR=\"$RoomBASEDIR\"" >> ~/.bashrc; source ~/.bashrc
fi

#echo $RoomBASEDIR
ScriptDir="$(dirname $0)/RoomPrepper"
#echo $ScriptDir

#read -p 'Which platform are you using (THM / HTB / VULNHUB) ?: ' PLATFORM
platform_Selection(){
    echo 'Available platforms ...'
    echo '[1] - TryHackMe '
    echo '[2] - HackTheBox '
    echo '[3] - Vulnhub '
    echo '[4] - Change Base Directory'
    read -p 'Choose platform or cancel script: [1] [2] [3] [4] [E]xit: ' -a array
    for choice in "${array[@]}"; do
        case "$choice" in
            [1]* ) echo -e "Selected $choice for TryHackMe" ; PLATFORM=TryHackMe && break;;
            [2]* ) echo -e "Selected $choice for HackTheBox" ;  PLATFORM=HackTheBox&& break ;;
            [3]* ) echo -e "Selected $choice for Vulnhub" ;  PLATFORM=Vulnhub && break ;;
            [4]* ) read -p 'Type in the Base Directory: ' RoomBASEDIR;sed -i "/export RoomBASEDIR=/d" ~/.bashrc;echo "export RoomBASEDIR=\"$RoomBASEDIR\"" >> ~/.bashrc; source ~/.bashrc; platform_Selection ;;
            [Ee]* ) echo "exited by user" && exit 0;;
            * ) echo "404 - Option not found" && exit 0;;
        esac
    done
}
platform_Selection
PLATFORMDIR=$RoomBASEDIR/$PLATFORM
if [ ! -d "$PLATFORMDIR" ]; then
  mkdir $PLATFORMDIR
fi

read -p 'Enter the name of the machine (e.g. HackPark): ' HOST
BOXDIR_GLOBAL=$PLATFORMDIR/$HOST

read -p 'Type in the IP address for the machine (or) NO if a ip is not needed(e.g. 10.11.12.3): ' IP

if [ -x "$(command -v xclip)" ]; then
  echo -n $IP | xclip -selection clipboard
fi

clear

##########################
# Functions Area
##########################

#
# directory check 
#

f_DirectoryCheck(){

if test -d $BOXDIR_GLOBAL; then
	echo -e "${RED}Directory already exists !${NC}"
    read -p "Do you want to load existing notes? [y/n]" -n 1 -r 
    echo -e "\n"                
                    if [[ $REPLY =~ ^[Yy]$ ]]
                    then
                    sed -i "2c$IP" $BOXDIR_GLOBAL/notes.md
                    nano $BOXDIR_GLOBAL/notes.md && exit 0
                    
                    else
                    echo -e "\n" 
                    echo -e "${RED}###########${NC}"
                    echo -e "${RED}! WARNING !${NC}"
                    echo -e "${RED}###########${NC}"
                    echo -e "\n"

                    read -p "Do you want to delete the folders and start again? [y/n] " -n 1 -r 
                
                        if [[ $REPLY =~ ^[Yy]$ ]]
                        then
                        rm -rf $BOXDIR_GLOBAL
                        else
                        echo -e "${RED}Exiting....${NC}"
                        exit 0
                        fi
                    fi
fi
}

#
# nmap scan
#

f_NmapDefault(){

echo -e "\n"
echo -e "${YELLOW}--------------------------------${NC}"
echo -e "${YELLOW}-  Starting standard Nmap Scan -${NC}"
echo -e "${YELLOW}--------------------------------${NC}"
echo -e "\n"

sleep 2

if ! [ -x "$(command -v nmap)" ]; then
echo -e "\n"
echo -e "${RED}--------------------------------${NC}"
echo -e "${RED}-      nmap not installed      -${NC}"
echo -e "${RED}--------------------------------${NC}"
echo -e "\n"
exit 0
fi


nmap -sCV $IP -v -T5  -oA $BOXDIR_GLOBAL/nmap/initial


}

#
# Creating folder structure
#


f_CreateFolders(){

# Creating the folders
# ~/PLATFORM/
# ~/PLATFORM/HOSTNAME
# ~/PLATFORM/HOSTNAME/nmap
# ~/PLATFORM/HOSTNAME/log
# ~/PLATFORM/HOSTNAME/screenshots

echo -e "\n"
echo -e "${YELLOW}------------------------${NC}"
echo -e "${YELLOW}- Creating directories -${NC}"
echo -e "${YELLOW}------------------------${NC}"
echo -e "\n"

mkdir $BOXDIR_GLOBAL
echo "--> Folder for room $HOST created ..."
sleep 1
if [ "$IP" != "NO" ]; then
mkdir $BOXDIR_GLOBAL/nmap
echo "--> nmap folder created ..."
sleep 1
fi
mkdir $BOXDIR_GLOBAL/log
echo "--> log folder created ..."
mkdir $BOXDIR_GLOBAL/screenshots
echo "--> screenshots folder created ..."

}


#
# Check if user wants to do a Gobuster scan, otherwise skip this section.
#

read -p "Do you want to do a gobuster scan? " g_choice
if [[ $g_choice =~ ^[Yy]$ ]] 
    then
    read -p "What port do you want to scan? " R_PORT
    echo "Using SecLists Raft as default..."
    echo
    echo "Checking installation..."
    
    echo ""
    echo -e "\n"
    echo -e "${YELLOW}------------------------------------${NC}"
    echo -e "${YELLOW}-  Starting standard Gobuster Scan -${NC}"
    echo -e "${YELLOW}------------------------------------${NC}"
    echo -e "\n"
    
    if ! [ -x "$(command -v gobuster)" ]; then
        echo -e "\n"
        echo -e "${RED}------------------------------------${NC}"
        echo -e "${RED}-      Gobuster not installed      -${NC}"
        echo -e "${RED}------------------------------------${NC}"
        echo -e "\n"
        exit 0
    else
        echo "Making the directories..."
        sleep 1
        mkdir $BOXDIR_GLOBAL/gobusted
        echo "Creating SecLists to use..."
        sleep 1
        git clone https://github.com/danielmiessler/SecLists.git $BOXDIR_GLOBAL/gobusted/
        echo "Starting scan on http://$IP:$R_PORT..."
        sleep 2
        gobuster dir -u http://$IP:R_PORT -w $BOXDIR_GLOBAL/gobusted/Seclists/Discivery/Web-Content/raft-medium-directories-lowercase.txt
        
    fi
else
exit 0
fi

#
# Ping host to check if it is alive, if not (typo i.e.) try again with same or other IP
#


f_CheckHostConnectivity(){
echo -e  " \n"
echo -e "${YELLOW}-----------------------------${NC}"
echo -e "${YELLOW}- Checking Host Connectivity - ${NC}"
echo -e "${YELLOW}-----------------------------${NC}"
echo -e " \n"

if ping -q -c 1 -W 1 $IP >/dev/null; then

        echo -e "${GREEN}Host is reachable${NC}"
        echo -e "${GREEN}IP of host is: $IP${NC}"
        echo " "


    else

        echo -e "${RED}Host is NOT reachable${NC}"
        read -p 'Starting VPN Connection first or type in IP again and hit enter to continue (last value = '$IP') : ' IP2

        if test -z $IP2; then

            echo 'pinging IP -> ' $IP''
            if ping -q -c 1 -W 1 $IP >/dev/null;then
            echo -e "${GREEN}Host is reachable${NC}"
            echo " "
            else
                echo -e "${RED}Host is NOT reachable! exiting....${NC}"
                exit 0
            fi

        else
            echo 'pinging IP again -> ' $IP2''
            if ping -q -c 1 -W 1 $IP2 >/dev/null ; then
                echo -e "${GREEN}Host is reachable${NC}"
                IP=$IP
                 echo " "

            else
                
                read -p "Still not reachable. Proceed with scan anyway? [y/n]  " -n 1 -r
                echo    # (optional) move to a new line
                    if [[ ! $REPLY =~ ^[Yy]$ ]]
                    then
                     echo " "
                    else
                    echo -e "${RED}Host is NOT reachable! exiting....${NC}"
                    exit 0
                    fi
            fi
        fi
fi

}

#
# Create new notes and fill with content of template
#

f_CreateNotes()
{
echo -e "\n"
echo -e "${YELLOW}-------------------------------${NC}"
echo -e "${YELLOW}- Creating notes for the box  -${NC}"
echo -e "${YELLOW}-------------------------------${NC}"
echo -e "\n"

sleep 1
if [ "$IP" != "NO" ]; then
echo "--> Grep TCP and UDP Ports"
egrep "tcp|udp" $BOXDIR_GLOBAL/nmap/initial.nmap >> fillin.txt
sleep 1
fi

echo "--> Set Hostname"
echo -e "[Host]" >> $BOXDIR_GLOBAL/notes.md
echo -e "$HOST \n" >> $BOXDIR_GLOBAL/notes.md

sleep 1

echo "--> import remaining template and files"
if [ "$IP" != "NO" ]; then
cat fillin.txt >> $BOXDIR_GLOBAL/notes.md
fi
cat $ScriptDir/notes_template.md >> $BOXDIR_GLOBAL/notes.md
cp $ScriptDir/createLists.sh $BOXDIR_GLOBAL
chmod +x $BOXDIR_GLOBAL/createLists.sh
}


#
#
#  calling functions
#
#

f_DirectoryCheck

f_CreateFolders
sleep 1
if [ "$IP" != "NO" ]; then
f_CheckHostConnectivity
sleep 1
f_NmapDefault
sleep 4
fi
f_CreateNotes
sleep 1

if [ "$IP" != "NO" ]; then
echo "--> Cleaning files"
rm fillin.txt
fi

echo -e "\n"
echo -e "${GREEN}FINISHED!${NC}"

exit 0
