#!/bin/bash
#
# set local Java path
if [ -f "java/version" ]; then
    new_java_home=$(cat java/version)
    export JAVA_HOME=$(pwd)/java/$new_java_home
    export PATH=$JAVA_HOME/bin:$PATH
	echo "Found local Java version: $JAVA_HOME"
	echo
fi
#
RES_CODE=0
cd sepia-assist-server
TOOLS_JAR=$(ls | grep "^sepia-core-tools.*jar" | tail -n 1)
echo -e "\n-----Assist API-----\n"
java -jar $TOOLS_JAR connection-check httpGetJson -url=http://localhost:20721/ping -maxTries=3 -waitBetween=1500 -expectKey=result -expectValue=success
if [ $? -eq 0 ]
then
	echo "OK"
else
	echo "Error:"
	curl --silent -X GET http://localhost:20721/ping
	RES_CODE=1
	exit 1
fi
echo -e "\n-----Teach API-----\n"
java -jar $TOOLS_JAR connection-check httpGetJson -url=http://localhost:20722/ping -maxTries=3 -waitBetween=1500 -expectKey=result -expectValue=success
if [ $? -eq 0 ]
then
	echo "OK"
else
	echo "Error:"
	curl --silent -X GET http://localhost:20722/ping
	RES_CODE=1
fi
echo -e "\n-----Chat API - WebSocket Server-----\n"
java -jar $TOOLS_JAR connection-check httpGetJson -url=http://localhost:20723/ping -maxTries=3 -waitBetween=1500 -expectKey=result -expectValue=success
if [ $? -eq 0 ]
then
	echo "OK"
else
	echo "Error:"
	curl --silent -X GET http://localhost:20723/ping
	RES_CODE=1
fi
if [ -f "Xtensions/TTS/marytts/bin/marytts-server" ]; then
	echo -e '\n-----Extensions-----\n'
	STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:59125/voices)
	if [ $STATUS -eq 200 ]; then
		echo "MaryTTS server is running."
	else
		echo "MaryTTS server is NOT running."
	fi
fi
echo -e '\n-----Database: Elasticsearch-----\n'
ES_RES=$(curl --silent -X GET http://localhost:20724/_cluster/health?pretty | grep 'yellow\|green')
if [ -z "$ES_RES" ]; then
	echo "Error:"
	curl --silent -X GET http://localhost:20724/_cluster/health?pretty
	RES_CODE=1
	exit 1
else
	echo "OK"
fi
if [ $RES_CODE -eq 1 ]; then
	echo -e '\nDONE - It seems there were one ore more ERRORS, please check the output!'
	echo -e 'Before you continue consider running the shutdown script once.\n'
	exit 1
fi
echo -e '\nDONE - If you made it this far all should be GOOD, but please double-check the output.\n'
ip_adr=""
if [ -x "$(command -v ip)" ]; then
	# old: ifconfig
	ip_adr=$(ip a | grep -E 'eth0|wlan0' | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -1)
fi
if [ -z "$ip_adr" ]; then
	ip_adr="[IP]"
fi
echo "You should be able to reach your SEPIA server via:"
echo "$(hostname).local or $ip_adr"
echo ''
echo "Example1: http://$(hostname).local:20721/tools/index.html"
echo "Example2: http://$ip_adr:20721/tools/index.html"
echo "Example3: http://$ip_adr:20721/app/index.html"
echo ''
echo "If you've installed NGINX proxy with self-signed SSL try:"
echo "Example4: https://$(hostname).local:20726/sepia/assist/tools/index.html"
echo "Example5: https://$(hostname).local:20726/sepia/assist/app/index.html"
echo ''
echo "Please note: if this is a virtual machine the hostname might not work to contact the server!"
echo ''
echo "For more info about secure context and microphone access in the SEPIA client see: "
echo "https://github.com/SEPIA-Framework/sepia-docs/wiki/SSL-for-your-Server"
echo ''
