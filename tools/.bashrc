source <(kubectl completion bash)
export GOPATH=/home/go
export GOBIN=
export PATH=$PATH:${GOPATH//://bin:}/bin
