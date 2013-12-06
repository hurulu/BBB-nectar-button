#!/bin/bash

source novarc
if [ $# -ne 1 ];then
	echo "$0 num_of_instances"
	exit 1
fi
num_instance=$1
#Make LED flash
./blink.py &
pid=$!
retry_max=10
retry_interval=3


function start_instances
{
	echo "Launch $num_instance instances ... "
	for((i=0;i<num_instance;i++))
	do
		uuid=`nova boot --image 034f7d4d-4ec2-424d-bbff-a4b8809dc01d --flavor m1.small --security_groups sa-test --key_name ray_nectar --availability_zone sa lei-test-BBB-$i|awk '{if($2=="id") print $4}'`
		uuid_array[$i]=$uuid
		echo ${uuid_array[$i]}
	done
}

function delete_instances
{
	for i in ${uuid_array[@]}
	do
		nova delete $i
	done
}

function script_exit
{
	exit_value=$1
	echo "exit $exit_value ..."
	delete_instances
	kill -9 $pid
	exit $exit_value
}
function status_array_init
{
	for((i=0;i<num_instance;i++))
	do
		status_array[$i]=1
	done
}

function check_build_command
{
	uuid=$1
	echo -ne "Check instances building status of $uuid ... "
	stat=`nova list|grep $uuid|awk '{print $6}'`
        if [ x"$stat" == "xACTIVE" ];then
		return 0
        elif [ x"$stat" == "xERROR" ];then
                script_exit 1
        else
		return 1
        fi
	
}

function check_ssh_command
{
	uuid=$1
	ip=`nova list|grep $uuid|awk '{print $8}'|cut -d= -f2`
	echo -ne "Check instances ssh $status of $ip  ... "
	ssh -i ray_nectar.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$ip "true" &>/dev/null
	return $?
}

function check_framework
{
	echo "Starting check loop ..."
	command=$1
	check_result=1
	retry=1
	while [ $check_result -ne 0 -o $retry -le $retry_max ]
	do
		check_result=0
		echo "Round $retry :"
		retry=`expr $retry + 1`
		index=0
		for i in ${uuid_array[@]}
		do
			if [ ${status_array[$index]} -eq 0 ];then
				echo "skip"
				index=`expr $index + 1`
				continue
			fi
			$command $i
			stat=$?
			if [ $stat -eq 0 ];then
				status_array[$index]=0
			fi
			check_result=`expr $check_result + $stat`
			index=`expr $index + 1`
			echo "$stat"
		done
		echo "check_result=$check_result"
		if [ $check_result -eq 0 ];then
			break
		fi
		sleep $retry_interval
	done
	if [ $check_result -ne 0 ];then
		script_exit 1
	fi
	return $check_result
}
#####################
# MAIN starts here
#####################
trap "script_exit 1" SIGINT
start_instances
start_time=`date +%s`
status_array_init
check_framework check_build_command
status_array_init
check_framework check_ssh_command
end_time=`date +%s`
booting_time=`expr $end_time - $start_time`
echo "$num_instance instances have successfully booted in $booting_time seconds"
script_exit 0
