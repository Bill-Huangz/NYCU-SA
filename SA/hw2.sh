#!/bin/sh


decodeFile(){
	FILE="${1}"
	INFO="info.json"
	> "$INFO"
	cur=0;
	while read -r line; do
		if [ "$cur" -eq 0 ] ; then
			awk "\""$1\"" \""$2\""" >> $INFO 		
		fi 

	done < "$FILE"

}


while getopts ":i:o:c:j" op; do
	case $op in
		i)
			decodeFile "$OPTARG";;

		o);;

		j);;

		*) >&2 printf 'hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]\n\nAvailable Options:\n\n-i: Input file to be decoded\n-o: Output directory\n-c csv|tsv: Output files.[ct]sv\n-j: Output info.json\n';;
	esac
done

exit 1

