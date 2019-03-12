#!/bin/sh

PH_DIR=/phapp/phabricator
PH_CONFIG_BIN=$PH_DIR/bin/config

PH_BASE_URI=${PH_BASE_URI}
PH_MYSQL_HOST=${PH_MYSQL_HOST}
PH_MYSQL_USER=${PH_MYSQL_USER}
PH_MYSQL_PASS=${PH_MYSQL_PASS}
PH_MYSQL_PORT=${PH_MYSQL_PORT:-3306}
PH_TIMEZONE=${PH_TIMEZONE:-UTC}
PH_REPO_PATH=${PH_REPO_PATH:-/var/repo/}
PH_PYGMENTS_ENABLED=${PH_PYGMENTS_ENABLED}

# Storage engine
PH_STORAGE_MYSQL_ENGINE_MAX_SIZE=${PH_STORAGE_MYSQL_ENGINE_MAX_SIZE}
PH_STORAGE_LOCAL_DISK_PATH=${PH_STORAGE_LOCAL_DISK_PATH}
PH_STORAGE_S3_BUCKET=${PH_STORAGE_S3_BUCKET}
PH_AMAZON_S3_ACCESS_KEY=${PH_AMAZON_S3_ACCESS_KEY}
PH_AMAZON_S3_SECRET_KEY=${PH_AMAZON_S3_SECRET_KEY}
PH_AMAZON_S3_REGION=${PH_AMAZON_S3_REGION}
PH_AMAZON_S3_ENDPOINT=${PH_AMAZON_S3_ENDPOINT}

# Email
PH_CLUSTER_MAILERS=${PH_CLUSTER_MAILERS}
PH_METAMTA_DEFAULT_ADDRESS=${PH_METAMTA_DEFAULT_ADDRESS}

set_ph_config() {
  NAME=$1
  VALUE=$2

  if [ -z $VALUE ]; then
    return 1
  fi

  $PH_CONFIG_BIN set $NAME $VALUE
}

get_mysql_status() {
  nc -z -w1 $PH_MYSQL_HOST $PH_MYSQL_PORT
  echo $?
}

wait_for_mysql() {
  while [ $(get_mysql_status) -ne 0 ]; do
    echo "Waiting mysql..."
    sleep 1
  done
}

ph_setup_local_config() {
  set_ph_config "mysql.host" $PH_MYSQL_HOST
  set_ph_config "mysql.user" $PH_MYSQL_USER
  set_ph_config "mysql.pass" $PH_MYSQL_PASS
  set_ph_config "mysql.port" $PH_MYSQL_PORT

  set_ph_config "phabricator.base-uri" $PH_BASE_URI
  set_ph_config "phabricator.timezone" $PH_TIMEZONE
  set_ph_config "pygments.enabled" $PH_PYGMENTS_ENABLED

  if [ ! -d $PH_REPO_PATH ]; then
    echo "Creating repo dir at [${PH_REPO_PATH}]"
    mkdir -p $PH_REPO_PATH
  fi
  set_ph_config "repository.default-local-path" $PH_REPO_PATH

  set_ph_config "storage.mysql-engine.max-size" $PH_STORAGE_MYSQL_ENGINE_MAX_SIZE
  set_ph_config "storage.local-disk.path" $PH_STORAGE_LOCAL_DISK_PATH
  if [ ! -z $PH_STORAGE_LOCAL_DISK_PATH ]; then
    mkdir -p $PH_STORAGE_LOCAL_DISK_PATH
  fi
  set_ph_config "storage.s3.bucket" $PH_STORAGE_S3_BUCKET
  set_ph_config "amazon-s3.access-key" $PH_AMAZON_S3_ACCESS_KEY
  set_ph_config "amazon-s3.secret-key" $PH_AMAZON_S3_SECRET_KEY
  set_ph_config "amazon-s3.region" $PH_AMAZON_S3_REGION
  set_ph_config "amazon-s3.endpoint" $PH_AMAZON_S3_ENDPOINT

  if [ ! -z $PH_CLUSTER_MAILERS -a -f $PH_CLUSTER_MAILERS ]; then
    $PH_CONFIG_BIN set --stdin cluster.mailers < $PH_CLUSTER_MAILERS
    set_ph_config "metamta.default-address" $PH_METAMTA_DEFAULT_ADDRESS
  fi
}

ph_start() {
  $PH_DIR/bin/storage upgrade --force
  $PH_DIR/bin/phd start
}

if [ $1 = 'ph-start' ]; then
  wait_for_mysql
  ph_setup_local_config
  ph_start

  exec php-fpm
elif [ $1 = 'aphlict-start' ]; then
  shift

  wait_for_mysql
  ph_setup_local_config

  $PH_DIR/bin/aphlict start $@

  exec php-fpm
else
  exec $@
fi
