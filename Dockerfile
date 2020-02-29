FROM alpine

RUN     apk add --no-cache curl wget vim bash jq inotify-tools net-tools tzdata \
    &&  cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    &&  echo "Asia/Shanghai" > /etc/timezone \
    &&  rm -rf /var/cache/apk/*

COPY check-pod-state.sh /usr/local/bin

RUN     curl -LsS https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    &&  chmod +x /usr/local/bin/kubectl /usr/local/bin/check-pod-state.sh

