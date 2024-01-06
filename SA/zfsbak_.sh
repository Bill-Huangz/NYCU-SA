	#!/usr/bin/env bash

Usage(){
	echo "Usage:"
	echo "- create: zfsbak DATASET [ROTATION_CNT]"
	echo "- list: zfsbak -l|--list [DATASET|ID|DATASET ID...]"
	echo "- delete: zfsbak -d|--delete [DATASET|ID|DATASET ID...]"
	echo "- export: zfsbak -e|--export DATASET [ID]"
	echo "- import: zfsbak -i|--import FILENAME DATASET"
}

MakeOPT(){
	tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
	#echo tmp
	ID=0
	for str in $tmp; do 
		zfs destroy $str
		ID=$((ID+1))
	done
	return $ID
}

List(){
	echo -e "ID\tDATASET\t\tTIME"
	re='^[0-9]+$'
	NID=(-1)
	#echo $@
	if [[ $# -eq 0 ]]; then
		tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
	elif [[ $1 =~ $re ]]; then
		tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
		NID=($(echo $@ | tr ' ' '\n'))
	else	
		tmp=$(zfs list -H -o name -t snapshot $1 | grep @zfsbak_ |  sort -t_ -k2)
		
		if [[ $# -gt 1 ]]; then 
			shift; NID=($(echo $@ | tr ' ' '\n')) 
		fi
	fi
	#len=${#NID[@]}
	#echo $len
	#for (( i=0; i<$len; i++ )); do echo "${NID[$i]}" ; done
	ID=0
	cur=0
	Exist=()
	for str in $tmp; do
		name=${str%@*}
		prefix=${str%/*}
		time=${str#*_}
		#echo "$prefix@$time"
		if [[  ! "${Exist[*]}" = *"|$prefix@$time|"* ]]; then
			ID=$((ID+1))
			if [[ "${NID[$cur]}" -eq -1 ]]; then 
				echo -e "$ID\t$name\t\t$time"
				# cur=$((cur+1))
			
			elif [[ "${NID[$cur]}" -eq $ID ]]; then
			
				echo -e "$ID\t$name\t\t$time"
				cur=$((cur+1))
			
			fi 
			Exist+=("|$name@$time|")
			# echo $Exist
		fi
	done;
}

Delete(){
	
	re='^[0-9]+$'
	NID=(-1)
	#echo $@
	if [[ $# -eq 0 ]]; then
		tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
	elif [[ $1 =~ $re ]]; then
		tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
		NID=($(echo $@ | tr ' ' '\n'))
	else	
		tmp=$(zfs list -H -o name -t snapshot $1 | grep @zfsbak_ |  sort -t_ -k2)
		
		if [[ $# -gt 1 ]]; then 
			shift; NID=($(echo $@ | tr ' ' '\n')) 
		fi
	fi
	
	ID=0
	for str in $tmp; do
		ID=$((ID+1))
		name=${str%@*}
		prefix=${str%/*}
		time=${str#*_}
		if [[ "${NID[$cur]}" -eq -1 ]]; then 
			zfs destroy $str
			echo "Destroy $str"
		elif [[ "${NID[$cur]}" -eq $ID ]]; then
			zfs destroy $str
			echo "Destroy $str"
			cur=$((cur+1))
		fi
	done;
}
Create(){
	LOC="$1"
	cnt="${2:-12}"
	zfs snapshot -r "${LOC}@zfsbak_${Date}"
	echo "Snap ${LOC}@zfsbak_${Date}"
		
	#tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
	#echo tmp
	#MakeOPT
	tmp=$(zfs list -H -o name -t snapshot $LOC | grep @zfsbak_ | sort -t_ -k2)
	tot=$(echo $tmp | tr ' ' '\n'| wc -l)
	# echo $tot; echo $tmp | tr ' ' '\n'; echo $cnt
	if [ $tot -gt $cnt ] ; then 
		tt=0
		#tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
		for str in $tmp; do
			tt=$((tt+1))	
			if [ $tt -le $((tot-cnt)) ] ; then 
				zfs destroy $str
				echo "Destroy $str"
			fi
		done	
	fi

}
zfsbak_Export(){
	id="${2:-1}"
	DATASET=$1
	inpname=$(List $@ |sed '1d' |awk 'NF {print $2 "@zfsbak_" $3}' )
	echo $inpname
	user=$SUDO_USER
	sudo_home="$(getent passwd | grep $user | cut -d: -f6)"
	#echo $user $sudo_home
	optname="${sudo_home}/$(echo $inpname |tr '/' '_').zst.aes"
	#echo  $inpname $optname
	#exit 0
	zfs send -R "$inpname" | zstd -qc - | openssl aes-256-cbc -k "$ZFSBAK_PASS"  -pbkdf2 -out "$optname"
	echo Export "$inpname" to "~/$(echo $inpname |tr '/' '_').zst.aes"
}
Export (){
	NID=(${2:-1})
	LOC=$1
	if [[ $# -eq 0 ]]; then
		tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
	elif [[ $1 =~ $re ]]; then
		tmp=$(zfs list -H -o name -t snapshot | grep @zfsbak_ |  sort -t_ -k2)
		NID=($(echo $@ | tr ' ' '\n'))
	else	
		tmp=$(zfs list -H -o name -t snapshot $1 | grep @zfsbak_ |  sort -t_ -k2)
		
		if [[ $# -gt 1 ]]; then 
			shift; NID=($(echo $@ | tr ' ' '\n')) 
		fi
	fi
	ID=0
	cur=0
	#echo $NID	
	for str in $tmp; do
		ID=$((ID+1))
		name=${str%@*}
		prefix=${str%/*}
		time=${str#*_}
		if [[ "${NID[$cur]}" -eq -1 ]]; then 
			echo "Destroy $str"
		elif [[ "${NID[$cur]}" -eq $ID ]]; then
			NAME=$str
			cur=$((cur+1))
		fi
	done;	
	echo $NAME

	user=$SUDO_USER
	home="$(getent passwd | grep $user | cut -d: -f6)"
	dest="${home}/$(echo $NAME | tr '/' '_').zst.aes"
	echo $home
	echo $dest
	# echo $NID	
	
	zfs send -R "$NAME" | zstd -qc - | openssl aes-256-cbc -k "$ZFSBAK_PASS"  -pbkdf2 -out "$dest" 
	echo Export "$NAME" to "~/$(echo $NAME |tr '/' '_').zst.aes"
}
Import(){
	name="${1}.aes"
	LOC=$2
	echo "Import $name to $LOC"
	zstd -qcd "$name" | zfs receive "$LOC"
}
Date="$(date '+%Y-%m-%d-%H:%M:%S')"
case "$1" in 
	-l|--list) shift; List $@;;
	-d|--delete) shift; Delete $@;;
	-e|--export) shift;  Export $@;;
	-i|--import) shift; Import $@;;
	*)
		if [ $# != 0 ]; 
		then
			Create $@
		else 
			Usage
		       	#MakeOPT	
		fi ;;
esac
