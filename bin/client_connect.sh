#!/bin/bash

# brew install psqlodbc
# brew install jq
# highly recommend using "cf-traveling-admin" from https://github.com/cloudfoundry-community/traveling-cf-admin
#
check_command(){
  if type $1 >/dev/null 2>&1; then
    #echo "$1 command exist"
    :
  else
    echo "please install $1 command"
    exit 1
  fi
}

if [ "$1" == "" ]; then
  echo "usage: ./client_connect.sh APP_NAME"
  exit 1
fi

# find the full path to this script, then set our path to chisel binaries
pushd $(dirname "${0}") > /dev/null
basedir=$(pwd -L)
# Use "pwd -P" for the path without links. man bash for more info.
popd > /dev/null
TOP_DIR="$(dirname ${basedir})"
# finally, set the path where we can find chisel
CLIENT_BASE_PATH="${TOP_DIR}/app/code/chisel-bin"


APP_NAME=$1
check_command cf
check_command jq

APP_GUID=`cf curl /v2/apps?q=name%3A$1 | jq -r '.resources|.[].metadata.guid'`
APP_DOMAIN=`cf curl /v2/apps/$APP_GUID/stats | jq -r '.["0"].stats.uris[0]'`
APP_ENV=`cf curl /v2/apps/$APP_GUID/env`
#SERVICE_LABEL=${SERVICE_LABEL:-`echo $APP_ENV | jq -r '.system_env_json.VCAP_SERVICES | .[][0].label'`}
SERVICE_LABEL=`echo $APP_ENV | jq -r '.system_env_json.VCAP_SERVICES | .[][0].label'`
SERVICE_NAME=`echo $APP_ENV | jq -r '.system_env_json.VCAP_SERVICES | .[][0].name'`
CREDENTIALS=`echo $APP_ENV | jq '.system_env_json.VCAP_SERVICES | .[][0].credentials'`

#REMOTE_HOST=`echo https://$APP_DOMAIN`
REMOTE_HOST=`echo $CREDENTIALS | jq -r .hostname`
REMOTE_PORT=`echo $CREDENTIALS | jq -r .port`
SERVICE_USER=`echo $CREDENTIALS | jq -r .username`
SERVICE_PASS=`echo $CREDENTIALS | jq -r .password`
SERVICE_DB=`echo $CREDENTIALS | jq -r .database`

LOCAL_PORT=${LOCAL_PORT:-15524}

echo_credentials(){
  echo "==============================="
  echo "APP_GUID: $APP_GUID"
  echo "APP_DOMAIN: https://$APP_DOMAIN"
  echo
  echo "$SERVICE_LABEL CREDENTIALS"
  echo
  echo "SERVICE NAME: $SERVICE_NAME"
  echo "SERVICE DATABASE: $SERVICE_DB"
  echo "SERVICE USERNAME: $SERVICE_USER"
  echo "SERVICE PASSWORD: $SERVICE_PASS"
  echo
  echo "LOCAL PORT: $LOCAL_PORT"
  echo "REMOTE HOST: $REMOTE_HOST"
  echo "REMOTE PORT: $REMOTE_PORT"
  echo
  echo "==============================="
}

kill_process(){
  if [ "${CHISEL_PID}" != "" ];then
    kill -9 $CHISEL_PID
  fi
}

connect_service(){
  #echo $SERVICE_LABEL
  case $SERVICE_LABEL in
    postgres* )
      echo_credentials
      check_command psql
      export PGPASSWORD=$SERVICE_PASS
      psql -h 127.0.0.1 -p $LOCAL_PORT -d $SERVICE_DB -U $SERVICE_USER
      kill_process
      ;;
    mysql* )
      check_command mysql
      mysql -h 127.0.0.1 -P $LOCAL_PORT -u $SERVICE_USER -p$SERVICE_PASS $SERVICE_NAME
      kill_process
      ;;
    * )
      echo_credentials
      kill_process
      ;;
  esac

}

start_client(){
  if [ "$(uname)" == 'Darwin' ]; then
    OS="Mac"
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS="Linux"
  elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
    OS="Cygwin"
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi

  if [ ! -z "$https_proxy" ]; then
    PROXY_PARAM="--proxy $https_proxy"
  fi

  case $OS in
    "Linux" )
      #./chisel_linux_amd64 client -v --proxy http://sjc1intproxy01.crd.ge.com:8080 --keepalive 3s https://predix-chisel-postgres-unreviewed-barcarole.run.asv-pr.ice.predix.io 4000:10.131.54.5:5432
      echo "$CLIENT_BASE_PATH/chisel_linux_amd64 client -v --keepalive ${KEEP_ALIVE:-'3s'} https://$APP_DOMAIN $LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT"
      $CLIENT_BASE_PATH/chisel_linux_amd64 client -v $PROXY_PARAM --keepalive ${KEEP_ALIVE:-'3s'} https://$APP_DOMAIN $LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT &
      ;;
    "Mac" )
      $CLIENT_BASE_PATH/chisel_darwin_amd64 client -v $PROXY_PARAM  --keepalive ${KEEP_ALIVE:-'3s'} https://$APP_DOMAIN $LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT &
      ;;
    "Cygwin" )
      $CLIENT_BASE_PATH/chisel_windows_386.exe client -v $PROXY_PARAM --keepalive ${KEEP_ALIVE:-'3s'} https://$APP_DOMAIN $LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT &
      ;;
  esac

  CHISEL_PID=`echo $!`
  sleep 3
}

start_client
connect_service
