FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Shanghai

RUN buildDeps='libtool wget unzip xz-utils' && \
	apt-get update && apt-get install -y \
		gcc g++ \
		python python3.7 mono-devel \
		openjdk-8-jdk \
		pypy \
		php7.2-cli \
		ruby rustc \
		curl bash ca-certificates bzip2 $buildDeps && \
	GO_VERSION='1.19.13' && \
	arch="$(dpkg --print-architecture)" && \
	case "$arch" in \
	  amd64) goArch='amd64' ;; \
	  arm64) goArch='arm64' ;; \
	  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
	esac && \
	curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${goArch}.tar.gz" -o /tmp/go.tar.gz && \
	rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz && \
	rm -f /tmp/go.tar.gz && \
	ln -sf /usr/local/go/bin/go /usr/bin/go && \
	go version && \
	cd /tmp && wget -O jsv8.zip https://storage.googleapis.com/chromium-v8/official/canary/v8-linux64-dbg-8.4.109.zip && \
	unzip -d /usr/bin/jsv8 jsv8.zip && rm -rf /tmp/jsv8.zip && \
	NODE_VERSION='14.21.3' && \
	arch="$(dpkg --print-architecture)" && \
	case "$arch" in \
	  amd64) nodeArch='x64' ;; \
	  arm64) nodeArch='arm64' ;; \
	  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
	esac && \
	curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${nodeArch}.tar.xz" -o /tmp/node.tar.xz && \
	tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
	rm -f /tmp/node.tar.xz && \
	ln -sf /usr/local/bin/node /usr/bin/node && \
	node -v && npm -v && \
	PYPY3_VERSION='7.3.16' && \
	arch="$(dpkg --print-architecture)" && \
	case "$arch" in \
	  amd64) pypyArch='linux64' ;; \
	  arm64) pypyArch='aarch64' ;; \
	  *) echo "Unsupported architecture for PyPy3: $arch" >&2; exit 1 ;; \
	esac && \
	curl -fsSL "https://downloads.python.org/pypy/pypy3.10-v${PYPY3_VERSION}-${pypyArch}.tar.bz2" -o /tmp/pypy3.tar.bz2 && \
	rm -rf /opt/pypy3 && mkdir -p /opt/pypy3 && \
	tar -xjf /tmp/pypy3.tar.bz2 -C /opt/pypy3 --strip-components=1 && \
	rm -f /tmp/pypy3.tar.bz2 && \
	ln -sf /opt/pypy3/bin/pypy3 /usr/bin/pypy3 && \
	ln -sf /opt/pypy3/bin/pypy3 /usr/bin/pypy3.10 && \
	pypy3 -V && \
	apt-get purge -y --auto-remove $buildDeps && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /judge/test_case /judge/run /judge/spj /judge/log

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY *.jar /judge/server/app.jar

COPY run.sh /judge/server/run.sh

COPY check_nacos.sh /judge/server/check_nacos.sh

COPY testlib.h /usr/include/testlib.h

ADD Sandbox-amd64 /judge/server/Sandbox-amd64
ADD Sandbox-arm64 /judge/server/Sandbox-arm64
	
WORKDIR /judge/server

ENTRYPOINT ["bash", "./check_nacos.sh"]

EXPOSE 8088

EXPOSE 5050