FROM ubuntu:20.04

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    ca-certificates \
    curl \
    git \
    golang-go \
    python3 \
    python3-click \
    python3-unidiff \
    g++ \
    apt-transport-https \
    gnupg \
 && curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg \
 && mv bazel.gpg /etc/apt/trusted.gpg.d/ \
 && echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
 && apt update && apt -y install bazel \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/antmicro/verible.git -b wsip/rdformat \
 && cd verible && GIT_VERSION=$(git --version | cut -d " " -f 3) bazel build //verilog/tools/lint:verible-verilog-lint \
 && cp ./bazel-bin/verilog/tools/lint/verible-verilog-lint /bin/

ENV GOBIN=/opt/go/bin

# FIXME This layer might be avoid by using BuildKit and --mount=type=bind
COPY reviewdog.patch /tmp/reviewdog/reviewdog.patch

# Install reviewdog
RUN git clone https://github.com/reviewdog/reviewdog \
 && cd reviewdog \
 && git checkout 72c205e138df049330f2a668c33782cda55d61f6 \
 && git apply /tmp/reviewdog/reviewdog.patch \
 && mkdir -p $GOBIN \
 && go install ./cmd/reviewdog \
 && cd .. \
 && rm -rf reviewdog \
 && $GOBIN/reviewdog --version

COPY entrypoint.sh /opt/antmicro/entrypoint.sh
COPY action.py /opt/antmicro/action.py
COPY rdf_gen.py /opt/antmicro/rdf_gen.py
WORKDIR /opt/antmicro

ENTRYPOINT ["/opt/antmicro/entrypoint.sh"]
