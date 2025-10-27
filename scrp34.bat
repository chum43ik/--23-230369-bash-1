#!/bin/bash

echo "name: $0"
echo "filesystem navigator"
echo "author Ivanov Daniil"

echo ""

echo 'type "help" or "h" to get help'

while read -p '>' line
do
	read cmd arg <<< "$line"
	case $cmd in
		help|h)
			echo 'description:'
			echo "	it's the mid interpritator for filesystem navigation."
			echo ''
			echo 'commands:'
			echo '	"pwd" or "p" - print name of current directory;'
			echo '	"ls" or "l" - list current directory contents;'
			echo '	"up" or "u" - up to parent directory;'
			echo '	"cd <next-dir>" or "c <next-dir>" - change directory to the <next-dir>;'
			echo '	"quit" or "q" - quit from program.'
			echo ''
			echo 'tip:'
			echo 'you also can type "^D" for quit.'
			echo ''
			;;
		pwd|p)
			pwd
			;;
		ls|l)
			ls -lshF
			;;
		up|u)
			cd ..
			;;
		cd|c)
			if [[ ! -d $arg ]]
			then
				echo "$arg isn't a directory" >&2
			elif [[ ! -x $arg ]]
			then
				echo "$arg's permission deny" >&2
			else
				cd $arg
			fi
			;;
		quit|q)
			exit 0
			;;
	esac

done
