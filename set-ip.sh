
export KUDU_QUICKSTART_IP=$(ip addr | awk '/inet .*/ {print $2}' | grep -v 127.0.0.1 | cut -d/ -f1 | tail -1)

#export KUDU_QUICKSTART_IP=172.31.160.1

echo KUDU_QUICKSTART_IP=${KUDU_QUICKSTART_IP}
