#!/bin/sh

retcode=0
authentic_user="hbase"
user=`whoami`
root_dir=`dirname $0`
log_dir="$root_dir/log"
current_time=`date +"%Y-%m-%d-%H-%M-%S"`
current_time="2018-12-05-16-39-04"
log_file="$log_dir/$current_time"
alarm_people="chaiwentao"
alarm_way="wechat"
host=`hostname`

deadServer=-1
inconsistencies=-1


do_alarm() {
	sumary="host host"
	content="content content"
  curl -H "Content-Type:application/json" -X POST -d '{ "receivers": ["'$alarm_people'"],"enables": ["'$alarm_way'"],"summary": "'$sumary'","content": "'$content'"}' "http://message.vdian.net/api/message?token=e575fa6250fd5f98c1a47438ba347395"
}

if [ $authentic_user != $user ]
then
    retcode=1
    exit $retcode
fi

HBASE=`which hbase`

#$HBASE hbck > $log_file

while read line
do
    if [[ $deadServer == -1 && $line == "Number of dead region servers:"* ]]
    then
		 echo $line
         deadServer=${line##* }
		 echo $deadServer
    fi

    if [[ $inconsistencies == -1 && $line == *" inconsistencies detected." ]]
    then
		 echo $line
         inconsistencies=${line%% *}
		 echo $inconsistencies
    fi
done < $log_file

if [ $inconsistencies == -1 ]
then
    echo "hbck process failed, retry"
    sh $root_dir/$0
    exit 1
fi

if [ $inconsistencies != 0 ]
then
    echo "hbck completed. found $inconsistencies inconsistencies"
    do_alarm "$host found $inconsistencies inconsistencies" "$host found $inconsistencies inconsistencies"
    retcode=1
fi

echo ""
echo "hbck completed. cluster status ok"

exit 0
