#!/usr/bin/env bash
# ccminer implementation from https://github.com/minershive/hiveos-linux/tree/master/hive/miners/ccminer

. h-manifest.conf

[[ `ps aux | grep "./ccminer" | grep -v grep | wc -l` != 0 ]] &&
	echo -e "${RED}$CUSTOM_NAME miner is already running${NOCOLOR}" &&
	exit 1

#try to release TIME_WAIT sockets
while true; do
	for con in `netstat -anp | grep TIME_WAIT | grep $MINER_API_PORT | awk '{print $5}'`; do
		echo -e "${RED}Attempting to release TIME_WAIT sockets for miner, miner should start shortly...${NOCOLOR}"
		killcx $con lo
	done
	netstat -anp | grep TIME_WAIT | grep $MINER_API_PORT &&
		continue ||
		break
done

echo -e "${GREEN}Attempting to set memory clocks at 810...${NOCOLOR}"
# 3x series cards
nvidia-smi -lmc 810
# 2x series cards
nvtool -setmem 810

CUSTOM_LOG_BASEDIR=`dirname "$CUSTOM_LOG_BASENAME"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/hive/lib
./ccminer -b 127.0.0.1:$MINER_API_PORT $(< $CUSTOM_CONFIG_FILENAME) 2>&1 | tee --append ${CUSTOM_LOG_BASENAME}.log
