#!/bin/bash

_USER="www-data"
_GROUP="www-data"
_ACL_FILE="acl.txt"

get_dpkg_install_status() {
	ACL_PKG="acl"
	DPKG_STATUS=$(dpkg -l | grep "${ACL_PKG}" | grep -v lib | awk '{ print $1 }')
	if [[ "${DPKG_STATUS}" == "ii" ]]; then
		echo "1"
	else
		echo "0"
	fi
}

adddate() {
    while IFS= read -r line; do
		TS_=$(($(date +%s%N)/1000000))
        printf '%s %s\n' "$(date +"%d.%m.%Y %T.%N")" "$line";
    done
}


verify_acl_install_status() {
	if [[ $(get_dpkg_install_status) == "1" ]]; then
		echo "1"
	else
		_UID=$(id -u)
		if [[ $_UID -eq 0 ]]; then
			apt install -y acl | adddate >> ./apt_install.log
			echo "1"
		else 
			echo "0"
		fi
	fi
}

IS_INSTALLED=0
while [[ $IS_INSTALLED -eq 0 ]]; do	
	IS_INSTALLED=$(verify_acl_install_status)
done

FIRST_SETUP=0
if [[ -r "${_ACL_FILE}" ]]; then
	if [[ -r acl_r_tmp.txt ]]; then
		rm -rf acl_r_tmp.txt
	fi
	if [[ $FIRST_SETUP -eq 1 ]]; then
		SCRIPT=$(readlink -f $0)
		SCRIPTPATH=`dirname $SCRIPT`
		cd $SCRIPTPATH
		ARGS_="-R ${_USER}:${_GROUP} *"
		chown $ARGS_
		getfacl -np -R . > ${_ACL_FILE}
	fi
	
	getfacl -np -R . > acl_r_tmp.txt
	if [[ $? -eq 0 ]]; then
		if [[ -r "acl_r_tmp.txt" ]]; then
		
			diff acl_r_tmp.txt ${_ACL_FILE} > /dev/null
			if [[ $? -eq 1 ]] && [[ $FIRST_SETUP -eq 1 ]]; then
				echo "copying tmp to acl because if diffs..."
				cp acl_r_tmp.txt ${_ACL_FILE}
				echo "IMPORTANT: DONT FORGET TO SET 'FIRST_SETUP' TO 0 after operation"
			fi
			
			diff acl_r_tmp.txt ${_ACL_FILE}
			EXIT_=$(echo $?)
			
			if [[ $EXIT_ -eq 1 ]]; then
				echo -n "restoring acl's ... "
				_ARGS="-R --restore=${_ACL_FILE}"
				setfacl $_ARGS
				echo "done"
			fi
			
			rm -rf acl_r_tmp.txt
		fi
	fi
fi
