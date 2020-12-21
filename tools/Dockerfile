FROM    alpine:3.10

RUN     set -ex \
    &&  echo "http://mirrors.aliyun.com/alpine/edge/community" >> /etc/apk/repositories \
    &&  echo "http://mirrors.aliyun.com/alpine/edge/main" >> /etc/apk/repositories \
    &&  echo "http://mirrors.aliyun.com/alpine/edge/testing" >> /etc/apk/repositories \
    &&  apk update \
    &&  apk upgrade \
    &&  apk add --no-cache \
    	git \
	    graphviz \
        tzdata\
        apache2-utils \
        bash \
        bash-completion \
        bind-tools \
        bird \
        bridge-utils \
        busybox-extras \
        conntrack-tools \
        curl \
        dhcping \
        drill \
        ethtool \
        file\
        fping \
        iftop \
        iperf \
        iproute2 \
        ipset \
        iptables \
        iptraf-ng \
        iputils \
        ipvsadm \
        jq \
        libc6-compat \
        liboping \
        mtr \
        net-snmp-tools \
        netcat-openbsd \
        nftables \
        ngrep \
        nmap \
        nmap-nping \
        openssl \
        py-crypto \
        py2-virtualenv \
        python2 \
        scapy \
        socat \
        strace \
        tcpdump \
        tcptraceroute \
        util-linux \
        vim \
        openssh \
        wget \
        net-tools \
        inotify-tools \
        htop \
        iotop \
        procps \
        sysstat \
        go-bootstrap \
        tshark \
        httpie \
        fio \
        atop \
        glances \
        websocat \
    &&  rm -rf /tmp/* \
    &&  rm -rf /var/cache/apk/*

# setting timezone
RUN 	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
	&&  echo "Asia/shanghai" >> /etc/timezone

# apparmor issue #14140
RUN     mv /usr/sbin/tcpdump /usr/bin/tcpdump

# Installing ctop - top-like container monitor
ARG     CTOP_VERSION=0.7.5
RUN 	curl -LSs https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-amd64 -o /usr/local/bin/ctop \
	&& 	chmod +x /usr/local/bin/ctop \
    &&  rm -rf /tmp/*

# Installing calicoctl
ARG     CALICOCTL_VERSION=v3.17.0
RUN 	curl -LSs https://github.com/projectcalico/calicoctl/releases/download/${CALICOCTL_VERSION}/calicoctl -o /usr/local/bin/calicoctl \
	&& 	chmod +x /usr/local/bin/calicoctl \
    &&  rm -rf /tmp/*

# Installing docker-debug
ARG     DOCKER_DEBUG_VERSION=0.7.3
RUN 	curl -LSs https://github.com/zeromake/docker-debug/releases/download/${DOCKER_DEBUG_VERSION}/docker-debug-linux-amd64 -o /usr/local/bin/docker-debug \
	&& 	chmod +x /usr/local/bin/docker-debug \
    &&  rm -rf /tmp/*

# Installing kubectl-debug
ARG     KUBECTL_VERSION=0.1.1
RUN 	curl -LSs https://github.com/aylei/kubectl-debug/releases/download/v${KUBECTL_VERSION}/kubectl-debug_${KUBECTL_VERSION}_linux_amd64.tar.gz -o /tmp/kubectl-debug.tar.gz \
    &&  cd /tmp \
    &&  tar -zxf kubectl-debug.tar.gz \
    &&  mv kubectl-debug /usr/local/bin/kubectl-debug \
    &&  chmod +x /usr/local/bin/kubectl-debug \
    &&  rm -rf /tmp/*

# Installing kubectl
RUN     curl -LSs -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl \
    &&  chmod +x /usr/local/bin/kubectl

# Installing termshark
ARG     TERMSHARK_VERSION=2.1.1
RUN     curl -LSs https://github.com/gcla/termshark/releases/download/v${TERMSHARK_VERSION}/termshark_${TERMSHARK_VERSION}_linux_x64.tar.gz -o /tmp/termshark_${TERMSHARK_VERSION}_linux_x64.tar.gz \
    &&  tar -zxvf /tmp/termshark_${TERMSHARK_VERSION}_linux_x64.tar.gz \
    &&  mv termshark_${TERMSHARK_VERSION}_linux_x64/termshark /usr/local/bin/termshark \
    &&  chmod +x /usr/local/bin/termshark

# Installing etcdctl
ARG     ETCD_VER=v3.4.14
## choose either URL
ARG     GOOGLE_URL=https://storage.googleapis.com/etcd
ARG     GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
ARG     DOWNLOAD_URL=${GOOGLE_URL}

RUN     go get -u github.com/google/pprof \
    &&  rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    &&  rm -rf /tmp/etcd-download-test \
    &&  mkdir -p /tmp/etcd-download-test \
    &&  curl -LSs ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    &&  tar xzf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1 \
    &&  rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    &&  cp -rf /tmp/etcd-download-test/etcdctl /usr/local/bin/etcdctl \
    &&  chmod +x /usr/local/bin/etcdctl \
    &&  rm -rf /tmp/*

# Settings
ADD     motd /etc/motd
ADD     profile /etc/profile
ENV     GOPATH=/root/go GOBIN='' PATH=$PATH:$GOROOT/bin:/root/go/bin

CMD     ["/bin/bash","-l"]
