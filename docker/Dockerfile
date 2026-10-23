ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG DEPENDENCY_PROXY=github
ARG BUILD_JOBS=4
ENV USER=root PYTHONUNBUFFERED=1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git wget sudo build-essential cmake pkg-config \
    autoconf automake libtool patch python3-dev python3-pip \
    libcurl4-openssl-dev uuid-dev libncurses5-dev libtiff-dev \
    libeigen3-dev libsqlite3-dev sqlite3 libssl-dev iproute2 \
    && rm -rf /var/lib/apt/lists/*
RUN python3 -m pip install --no-cache-dir protobuf==3.14.0

WORKDIR /opt/bridge
COPY install.py ./
COPY scripts/ ./scripts/
COPY docker/deps/ ./third_party/
# Repository sources are supplied by the host. Missing sources must not trigger Git.
RUN python3 install.py --proxy "${DEPENDENCY_PROXY}" --jobs "${BUILD_JOBS}" \
      --source-dir /opt/bridge/third_party \
    && rm -rf third_party

# Copy project sources without duplicating downloaded dependencies in the image.
COPY CMakeLists.txt setup.bash.in setup.zsh.in ./
COPY cyber/ ./cyber/
COPY modules/ ./modules/
COPY cmake/ ./cmake/
COPY tests/ ./tests/
COPY docker/entrypoint.sh docker/environment.bash ./docker/
RUN source install/setup.bash \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DAPOLLO_LEGACY_RTPS=ON \
    && cmake --build build --parallel "${BUILD_JOBS}"
RUN printf '\nsource /opt/bridge/docker/environment.bash\n' >> /root/.bashrc

ENV CYBER_DOMAIN_ID=80
ENTRYPOINT ["/bin/bash", "/opt/bridge/docker/entrypoint.sh"]
CMD ["talker"]
