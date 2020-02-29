#!/bin/bash

MAIL_ALARM=${MAIL_ALARM}
# 账号和密码需要base64加密
MAIL_TO=$( echo ${MAIL_TO} | base64 -d | tr 'A-Z' 'a-z' )
MAIL_FROM=$( echo ${MAIL_FROM} | base64 -d | tr 'A-Z' 'a-z' )
MAIL_PASSWORD=$( echo ${MAIL_PASSWORD} | base64 -d )
MAIL_SMTP_SERVER=$( echo ${MAIL_SMTP_SERVER} | base64 -d | tr 'A-Z' 'a-z' )

MAIL_SMTP_PORT=${MAIL_SMTP_PORT}

# 是否启用TSL认证
MAIL_TLS_CHECK=${MAIL_TLS_CHECK:-true}
# 自签名TSL认证CA证书
MAIL_CACERT=$( echo ${MAIL_CACERT} | base64 -d )
MAIL_CA_PATH=${MAIL_CA_PATH:-'/root/cacert.pem'}

if [[ -n ${NAMESPACES} ]]; then
    NS="-n ${NAMESPACES}"
else
    NS="--all-namespaces"
fi

STATUS_TYPE=${STATUS_TYPE:-'Evicted|Terminating|Error|OutOfmemory|CreateContainerError|Failed|Unknown|Running|Pending'};
KUBE_COMMAND=$( kubectl get pod ${NS} -o custom-columns=NAMESPACES:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase | grep -v NAMESPACES );
POD_STATUS_LIST=$( echo "${KUBE_COMMAND}" | grep -E "${STATUS_TYPE}" );

send_mail ()
{
cat << EOF > mail.txt
From: ${MAIL_FROM}
To: ${MAIL_TO}
Subject: Pod状态异常通知
Date: $( date -Iseconds )

应用状态:
EOF
    echo "${1}" >> mail.txt
    # 公共TLS认证邮箱
    if [[ ${MAIL_TLS_CHECK} && ${MAIL_TLS_CHECK} == 'true' ]]; then
        curl --silent --ssl --url "smtps://${MAIL_SMTP_SERVER}:${MAIL_SMTP_PORT}" \
        --mail-from "${MAIL_FROM}" --mail-rcpt "${MAIL_TO}" \
        --user "${MAIL_FROM}:${MAIL_PASSWORD}" \
        --upload-file mail.txt
        return
    fi
    # 私有TLS认证邮箱
    if [[ ${MAIL_CACERT} && -n ${MAIL_CACERT} && ${MAIL_TLS_CHECK} == 'true' ]]; then
        touch ${MAIL_CA_PATH}
        echo ${MAIL_CACERT} > ${MAIL_CA_PATH}
        curl --silent --ssl --url "smtps://${MAIL_SMTP_SERVER}:${MAIL_SMTP_PORT}" \
        --mail-from "${MAIL_FROM}" --mail-rcpt "${MAIL_TO}" \
        --cacert=${MAIL_CA_PATH} \
        --user "${MAIL_FROM}:${MAIL_PASSWORD}" \
        --upload-file mail.txt
        return
    fi
    # 非TLS认证邮箱
    if [[ ${MAIL_TLS_CHECK} && ${MAIL_TLS_CHECK} == 'false' ]]; then
        curl --silent --url "smtps://${MAIL_SMTP_SERVER}:${MAIL_SMTP_PORT}" \
        --mail-from "${MAIL_FROM}" --mail-rcpt "${MAIL_TO}" \
        --user "${MAIL_FROM}:${MAIL_PASSWORD}" \
        --insecure \
        --upload-file mail.txt
        return
    fi
}

if [[ -n "${POD_STATUS_LIST}" ]]; then
    # 先删除全部的异常Pod
    echo "${POD_STATUS_LIST}" | awk '{print "-n "$1" "$2 }' | xargs kubectl delete pod --force --grace-period=0

    # 等待10s，然后检查异常Pod并统计数量
    sleep 10
    CHECK_POD_COUNT_1=$( echo "${KUBE_COMMAND}" | grep -E "${STATUS_TYPE}" | wc -l )

    # 再等10s，然后再检查异常Pod并统计数量
    sleep 10
    CHECK_POD_COUNT_2=$( echo "${KUBE_COMMAND}" | grep -E "${STATUS_TYPE}" | wc -l )

    # 如果第二次检查大于第一次检查，然后再等5s进行第三次检查
    if [[ $[CHECK_POD_COUNT_2-CHECK_POD_COUNT_1 ] > 5 ]]; then
        sleep 5
        CHECK_POD_COUNT_3=$( echo "${KUBE_COMMAND}" | grep -E "${STATUS_TYPE}" | wc -l )
        # 如果第三次相比第二次依然在增长，则触发删除异常Pod，并可选邮件告警
        if [[ $[CHECK_POD_COUNT_3-CHECK_POD_COUNT_2 ] > 5 ]]; then

            POD_STATUS_LIST=$( echo "${KUBE_COMMAND}" | grep -E "${STATUS_TYPE}" );
            echo "${POD_STATUS_LIST}" | awk '{print "-n "$1" "$2 }' | xargs kubectl delete pod --force --grace-period=0

            if [[ -n ${MAIL_ALARM} ]]; then
                send_mail ${POD_STATUS_LIST}
            fi
        fi
    fi

fi
