#!/bin/sh

CLEARDB=`echo $VCAP_SERVICES | grep "cleardb"`
PMYSQL=`echo $VCAP_SERVICES | grep "mysql"`
XTRADB=`echo $VCAP_SERVICES | grep "xtradb"`

if [ "$CLEARDB" != "" ];then
	SERVICE="cleardb"
elif [ "$XTRADB" != "" ]; then
	SERVICE="user-provided"
elif [ "$PMYSQL" != "" ]; then
	SERVICE="mysql"
fi

echo "detected $SERVICE"

if [ "$XTRADB" != "" ];then
	HOSTNAME=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials._HBX_DB_HOST_WRITE'`
	PASSWORD=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials._HBX_DBA_PWD_WRITE'`
	PORT=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials._HBX_DB_PORT'`
	USERNAME=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials._HBX_DBA_USER_WRITE'`
	DATABASE=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials._HBX_DB_NAME'`
else
	HOSTNAME=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.hostname'`
	PASSWORD=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.password'`
	PORT=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.port'`
	USERNAME=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.username'`
	DATABASE=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.name'`
fi
#--- ajout crendentials to unseal VAULT ---
UNSEAL_SERVICE=`echo $VCAP_SERVICES | grep "vault-keys"`
if [ "$UNSEAL_SERVICE" != "" ];then
	SERVICE="user-provided"
	if [ "$XTRADB" != "" ];then
		VAULT_UNSEAL_KEY1=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][1].credentials.VAULT_UNSEAL_KEY1'`
		VAULT_UNSEAL_KEY2=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][1].credentials.VAULT_UNSEAL_KEY2'`
		VAULT_UNSEAL_KEY3=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][1].credentials.VAULT_UNSEAL_KEY3'`
	else
		VAULT_UNSEAL_KEY1=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.VAULT_UNSEAL_KEY1'`
		VAULT_UNSEAL_KEY2=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.VAULT_UNSEAL_KEY2'`
		VAULT_UNSEAL_KEY3=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.VAULT_UNSEAL_KEY3'`
	fi
fi

cat <<EOF > cf.hcl
disable_mlock = true

storage "mysql" {
  username = "$USERNAME"
  password = "$PASSWORD"
  address = "$HOSTNAME:$PORT"
  database = "$DATABASE"
  table = "vault"
  max_parallel = 4
}

listener "tcp" {
 address = "0.0.0.0:8080"
 tls_disable = 1
}
EOF

echo "#### Starting Vault..."

./vault server -config=cf.hcl &

if [ "$VAULT_UNSEAL_KEY1" != "" ];then
	export VAULT_ADDR='http://127.0.0.1:8080'
	echo "#### Waiting..."
	sleep 1
	echo "#### Unsealing..."
	if [ "$VAULT_UNSEAL_KEY1" != "" ];then
		./vault operator unseal $VAULT_UNSEAL_KEY1
	fi
	if [ "$VAULT_UNSEAL_KEY2" != "" ];then
		./vault operator unseal $VAULT_UNSEAL_KEY2
	fi
	if [ "$VAULT_UNSEAL_KEY3" != "" ];then
		./vault operator unseal $VAULT_UNSEAL_KEY3
	fi
fi


