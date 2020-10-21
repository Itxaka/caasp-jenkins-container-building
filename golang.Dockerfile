FROM opensuse/leap:15

ARG GOLANG_VERSION=1.15.3
ENV PATH /usr/local/go/bin:$PATH
RUN zypper install -y tar gzip wget
RUN wget -O go.tgz https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf /go.tgz
RUN go version
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH