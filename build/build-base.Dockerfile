# Base
#
# This image contains only third party dependencies and no Vault source code.
#
# It should be built with no Docker context.
#
FROM debian:buster

ENV GO_VERSION 1.12.12
ENV YARN_VERSION 1.19.1-1

RUN apt-get update -y && apt-get install --no-install-recommends -y -q \
                         curl \
                         zip \
                         build-essential \
                         gcc-multilib \
                         g++-multilib \
                         ca-certificates \
                         git mercurial bzr \
                         gnupg \
                         libltdl-dev \
                         libltdl7 \
						 bash

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -y && apt-get install -y -q nodejs yarn=${YARN_VERSION}

RUN rm -rf /var/lib/apt/lists/*


RUN mkdir /goroot && mkdir /gopath
RUN curl https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz \
           | tar xvzf - -C /goroot --strip-components=1

ENV GOPATH /gopath
ENV GOROOT /goroot
ENV PATH $GOROOT/bin:$GOPATH/bin:$PATH

RUN go get golang.org/x/tools/cmd/goimports
RUN go get github.com/mitchellh/gox
RUN go get github.com/hashicorp/go-bindata
RUN go get github.com/hashicorp/go-bindata/go-bindata
RUN go get github.com/elazarl/go-bindata-assetfs
RUN go get github.com/elazarl/go-bindata-assetfs/go-bindata-assetfs

RUN mkdir -p /gopath/src/github.com/hashicorp/vault
WORKDIR /gopath/src/github.com/hashicorp/vault

ENTRYPOINT /bin/bash

CMD make ember-dist && make static-dist && go build -o ${OUTPUT}
