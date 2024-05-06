#!/bin/sh
# SSHFS Wizzard for macOS
# By Grego Dadone (https://github.com/gregodadone)

# Functions
showHelp() {
	read -r -d '' help <<-EOF
	Usage:\n\tsshfs-wizzard [options]\nOPTIONS\n
	\t-c, --connect <server>\tConnects to known server\n
	\t-l, --list\t\tList known servers\n
	\t-u, --umount\t\tUnmount currently mounted server\n
	\t-h, --help\t\tDisplays help
	EOF
	
	echo $help	
}

serverWizzard() {
	is_ok="n"
	while [[ $is_ok == "n" ]] || [[ $is_ok == "N" ]]; do
	    serverDataEntry
	    echo "Command is: $command"
	    read -p "Is it ok? (Y/n): " is_ok
	    is_ok=${is_ok:-Y}
	    if [[ $is_ok != "n" ]] || [[ $is_ok != "N" ]]; then
	    	saveServer
	   	    connectToServer
	   	fi
	done
}

serverDataEntry() {
	read -p "Enter server: " server
	while [[ $server == "" ]]; do
		read -p "Enter server: " server
	done

	read -p "Enter port (default 22): " port
	port=${port:-22}

	read -p "Enter user: " user
	while [[ $user == "" ]]; do
		read -p "Enter user: " user
	done

	read -p "Enter default remote folder (default /): " folder
	folder=${folder:-/}

	read -p "Enter name for this server: " ovolname
	ovolname=${ovolname:-SFTP_Server}

	command="sshfs $user@$server:$folder /Users/$USER/mnt -ovolname=$ovolname"
}

createFolderIfNotExists() {
	if ! [ -d /Users/$USER/.sshfs ]; then
		mkdir /Users/$USER/.sshfs
	fi
}

saveServer() {
	createFolderIfNotExists
	echo "$server;$port;$user;$folder" > /Users/$USER/.sshfs/$ovolname
}

readServer() {
	createFolderIfNotExists
	ovolname=$2
	if [ -f /Users/$USER/.sshfs/$ovolname ]; then
		server=$(cat /Users/$USER/.sshfs/Pop | cut -d ';' -f 1)
		port=$(cat /Users/$USER/.sshfs/Pop | cut -d ';' -f 2)
		user=$(cat /Users/$USER/.sshfs/Pop | cut -d ';' -f 3)
		folder=$(cat /Users/$USER/.sshfs/Pop | cut -d ';' -f 4)

		connectToServer
	else
		echo "Server not found. Execute command with -l to see the list of known servers"
		exit 1
	fi
}

listKnownServers() {
	createFolderIfNotExists
	echo "List of known servers:"
	for file in $(ls /Users/$USER/.sshfs); do
		echo $file: $(cat /Users/$USER/.sshfs/$file)
	done
}

connectToServer() {
	mkdir /Users/$USER/mnt
	sshfs $user@$server:$folder /Users/$USER/mnt -ovolname=$ovolname
}

disconnectServer() {
	if [ -d /Users/$USER/mnt ]; then
		umount /Users/$USER/mnt
		rm -Rf /Users/$USER/mnt
	else
		echo "There are no servers mounted"
		exit 1
	fi
}

# MAIN
if ! command -v sshfs &> /dev/null; then
    echo "Please install sshfs: brew install gromgit/fuse/sshfs-mac"
    exit 1
else
	case $1 in
		-c | --connect) readServer;;
		-l | --list) listKnownServers;;
		-u | --umount) disconnectServer;;
		-h | --help) showHelp;;
		*) serverWizzard;;
	esac
fi

#TODO
# Save passwords (expect)
