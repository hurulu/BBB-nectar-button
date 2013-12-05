#!/bin/bash

source novarc

./blink.py &
pid=$!
instance_retry_times=10
ssh_retry_times=10
sleep_time=3

echo "Launch an instance ... "
uuid=`nova boot --image 034f7d4d-4ec2-424d-bbff-a4b8809dc01d --flavor m1.small --security_groups sa-test --key_name ray_nectar --availability_zone sa lei-test-BBB|awk '{if($2=="id") print $4}'`
echo "$uuid"

stat=`nova list|grep $uuid|awk '{print $6}'`
count=0
until [ x"$stat" == "xACTIVE" -o  x"$stat" == "xERROR" ]
do
	stat=`nova list|grep $uuid|awk '{print $6}'`
	if [ $count -gt $instance_retry_times ];then
		stat=ERROR
		nova delete $uuid
		kill -9 $pid
		exit 1
	fi
	count=`expr $count + 1 `
	echo "stat=$stat:  retries : $count  "
	sleep $sleep_time
done
echo $stat
if [ x"$stat" == "xERROR" ];then
	nova delete $uuid
	kill -9 $pid
	exit 1
fi


ip=`nova list|grep $uuid|awk '{print $8}'|cut -d= -f2`

if [ x"$ip" == "x" ];then
	echo "No IP"
	nova delete $uuid
	kill -9 $pid
	exit 1
fi 

echo $ip

ssh -i ray_nectar.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$ip "true"
ret=$?
count=0
while [ $ret -ne 0 ]
do
	ssh -i ray_nectar.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$ip "true"
	ret=$?
	if [ $count -gt $ssh_retry_times ];then
		echo "Cannot ssh"
		nova delete $uuid
		kill -9 $pid
		exit 1
	fi
	count=`expr $count + 1 `
	echo "retry $count $sleep_time seconds later ..."
	sleep $sleep_time
done

echo "SUCCESS"

nova delete $uuid
kill -9 $pid
exit 0
