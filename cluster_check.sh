#!/bin/sh

retcode=0
authentic_user="hbase"
user=`whoami`
root_dir=`dirname $0`
log_dir="$root_dir/log"
current_time=`date +"%Y-%m-%d-%H-%M-%S"`
log_file="$log_dir/$current_time"
alarm_people="chaiwentao"
alarm_way="wechat"
host=`hostname`

deadServer=-1
inconsistencies=-1


do_alarm() {
  curl -H "Content-Type:application/json" -X POST -d '{ "receivers": ["'$alarm_people'"],"enables": ["'$alarm_way'"],"summary": "'"$1"'","content": "'"$2"'"}' "http://message.vdian.net/api/message?token=e575fa6250fd5f98c1a47438ba347395"
}

if [ $authentic_user != $user ]
then
    retcode=1
    exit $retcode
fi

HBASE=`which hbase`

$HBASE hbck > $log_file

while read line
do
    if [[ $deadServer == -1 && $line == "Number of dead region servers:"* ]]
    then
         deadServer=${line##* }
    fi

    if [[ $inconsistencies == -1 && $line == *" inconsistencies detected." ]]
    then
         inconsistencies=${line%% *}
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

delete_log=`date -d "-30 days" +"%Y-%m-%d"`
rm -f $log_dir/$delete_log"*"

echo "[hbck completed. cluster status ok]"

exit 0
