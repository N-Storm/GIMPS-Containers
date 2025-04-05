FROM nvidia/cuda:12.8.0-devel-ubuntu24.04 as build

WORKDIR /build

RUN apt update && apt install -y --no-install-recommends \
    wget curl mc sudo htop build-essential nvidia-opencl-dev git python3 \
    ocl-icd-dev libgmp10 libgmp-dev make cmake clinfo patch diffutils unzip

RUN mkdir /artifacts; \
    wget "https://github.com/N-Storm/mfaktc/releases/download/0.23.2-optimized/mfaktc-0.23.2-optimized-linux64-cuda12.8.0.zip" && \
    mkdir mfaktc-0.23.2-optimized-linux64-cuda12.8.0 && cd mfaktc-0.23.2-optimized-linux64-cuda12.8.0 && \
    unzip -o ../mfaktc-0.23.2-optimized-linux64-cuda12.8.0.zip && strip mfaktc && \
    tar Jcvf ../mfaktc-0.23.2-optimized-linux64-cuda12.8.0.tar.xz ./ && cd .. && \
    mv mfaktc-0.23.2pre4.tar.xz /artifacts; \
    cd /build && git clone https://github.com/preda/gpuowl -b gpuowl && \
    cd gpuowl && git checkout gpuowl && make -j$(nproc) && strip build-release/gpuowl && \
    mkdir gpuowl-master && cp ./build-release/gpuowl ./gpuowl-master && cp LICENSE ./gpuowl-master && cp README.* ./gpuowl-master && \
    tar Jcvf ./gpuowl-master.tar.xz gpuowl-master && mv ./gpuowl-master.tar.xz /artifacts && ls -la /artifacts/

# FROM nvidia/cuda:12.8.0-runtime-ubuntu24.04 as base
FROM nvidia/cuda:12.8.0-base-ubuntu24.04 as base

FROM base as base-amd64

COPY --from=build /artifacts /root

RUN apt update && apt full-upgrade -y && apt install -y --no-install-recommends \
    wget curl mc sudo htop git python3 libgmp10 clinfo unzip tar xz-utils && \
    cd /root && tar xvf ./mfaktc-0.23.2-optimized-linux64-cuda12.8.0.tar.xz && tar xvf ./gpuowl-master.tar.xz
