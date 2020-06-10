#!/bin/bash

# 自定义命名空间
if [[ -n ${NAMESPACES} ]]; then
    NS="-n ${NAMESPACES}"
else
    NS="--all-namespaces"
fi

# 定义是否发送Pod异常邮件告警
MAIL_ALARM=${MAIL_ALARM:-false}

# 邮件告警相关参数
## 以下四个参数都需要base64加密
MAIL_TO=$( echo ${MAIL_TO} | base64 -d | tr 'A-Z' 'a-z' )
MAIL_FROM=$( echo ${MAIL_FROM} | base64 -d | tr 'A-Z' 'a-z' )
MAIL_PASSWORD=$( echo ${MAIL_PASSWORD} | base64 -d )
MAIL_SMTP_SERVER=$( echo ${MAIL_SMTP_SERVER} | base64 -d | tr 'A-Z' 'a-z' )

MAIL_SMTP_PORT=${MAIL_SMTP_PORT}
# 是否启用TSL认证
MAIL_TLS_CHECK=${MAIL_TLS_CHECK:-true}
# 自签名TSL认证CA证书，需要base64加密
MAIL_CACERT=$( echo ${MAIL_CACERT} | base64 -d )
MAIL_CA_PATH=${MAIL_CA_PATH:-'/root/cacert.pem'}

# 定义要监控的Pod状态
STATUS_TYPE=${STATUS_TYPE:-Evicted|Terminating|Error|OutOfmemory|CreateContainerError|Failed|Unknown};

KUBE_GET_POD()
{
    kubectl get pod ${NS} -o custom-columns=NAMESPACES:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase | grep -v NAMESPACES
}

KUBE_DEL_POD()
{
    kubectl delete pods $1
}

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
    if [[ ${MAIL_TLS_CHECK} == 'true' ]]; then
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
    if [[ ${MAIL_TLS_CHECK} == 'false' ]]; then
        curl --silent --url "smtps://${MAIL_SMTP_SERVER}:${MAIL_SMTP_PORT}" \
        --mail-from "${MAIL_FROM}" --mail-rcpt "${MAIL_TO}" \
        --user "${MAIL_FROM}:${MAIL_PASSWORD}" \
        --insecure \
        --upload-file mail.txt
        return
    fi
}

echo "初始获取 Pod 状态"
POD_STATUS_LIST=$( KUBE_GET_POD | grep -E ${STATUS_TYPE} );
echo "${POD_STATUS_LIST}" | tee /tmp/pod-list.txt

if [[ -n "${POD_STATUS_LIST}" ]]; then
    echo '检查到异常 Pod'
    echo '删除异常 Pod'
    NS_POD=$( cat /tmp/pod-list.txt | awk '{print " -n " $1" "$2}' )
    for i in "$NS_POD";
    do
        KUBE_DEL_POD "$i"
    done

    echo '等待30s，然后检查异常 Pod 并统计数量'
    sleep 30
    CHECK_POD_COUNT_1=$( KUBE_GET_POD | grep -E ${STATUS_TYPE} | wc -l )
    echo "CHECK_POD_COUNT_1=$CHECK_POD_COUNT_1"

    if [[ ${CHECK_POD_COUNT_1} > 0 ]]; then
        echo "第一次检查异常 Pod > 0"
        echo '再等30s，然后再检查异常 Pod 并统计数量'
        sleep 30
        CHECK_POD_COUNT_2=$( KUBE_GET_POD | grep -E ${STATUS_TYPE} | wc -l )
        echo "CHECK_POD_COUNT_2=$CHECK_POD_COUNT_2"

        if [[ $[CHECK_POD_COUNT_2-CHECK_POD_COUNT_1 ] > 5 ]]; then
            echo '第二次检查比第一次检查异常 Pod 数据大于 5，再等30s进行第三次检查'
            sleep 30

            POD_STATUS_LIST=$( KUBE_GET_POD | grep -E ${STATUS_TYPE} );
            echo "${POD_STATUS_LIST}" > /tmp/pod-list.txt

            CHECK_POD_COUNT_3=$( cat /tmp/pod-list.txt | wc -l )
            echo "CHECK_POD_COUNT_3=$CHECK_POD_COUNT_3"

            # 如果第三次相比第二次依然在增长，则触发删除异常Pod，并可选邮件告警
            if [[ $[CHECK_POD_COUNT_3-CHECK_POD_COUNT_2 ] > 5 ]]; then
                echo "第三次检查相比第二次检查异常 Pod 数依然在增长"
                echo '再次删除异常 Pod'

                NS_POD=$( cat /tmp/pod-list.txt | awk '{print " -n " $1" "$2}' )
                for i in "$NS_POD";
                do
                    KUBE_DEL_POD "$i"
                done
                if [[ ${MAIL_ALARM} == true ]]; then
                    echo '发送邮件告警'
                    send_mail "${POD_STATUS_LIST}"
                fi
            fi
        else
            echo "没有异常 Pod 增加"
            exit
        fi
    fi
else
    echo "没有异常 Pod"
fi
