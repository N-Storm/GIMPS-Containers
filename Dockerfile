FROM nvidia/cuda:12.8.0-devel-ubuntu24.04 as build

WORKDIR /build

RUN apt update && apt install -y --no-install-recommends \
    wget curl mc sudo htop build-essential nvidia-opencl-dev git python3 \
    ocl-icd-dev libgmp10 libgmp-dev make cmake clinfo patch diffutils unzip

RUN mkdir /artifacts; \
    wget "https://download.mersenne.ca/mfaktc/source-code/mfaktc-0.23.0.zip" && \
    unzip -o ./mfaktc-0.23.0.zip && cd mfaktc-0.23.0/src && \
    sed -i -e 's/CFLAGS = -Wall -Wextra -O2/CFLAGS = -Wall -Wextra -O3 -flto -ffunction-sections -fdata-sections -Wl,--gc-sections/' \
           -e 's/NVCCFLAGS += --generate-code/NVCCFLAGS += -O3 --generate-code/' Makefile && \
    make -j$(nproc) && cd ../.. && strip ./mfaktc-0.23.0/mfaktc && \
    tar Jcvf ./mfaktc-0.23.0.tar.xz --exclude ./mfaktc-0.23.0/src ./mfaktc-0.23.0 && \
    mv mfaktc-0.23.0.tar.xz /artifacts; \

WORKDIR /build

RUN git clone https://github.com/preda/gpuowl -b gpuowl && \
    cd gpuowl && git checkout gpuowl && make -j$(nproc) && strip build-release/gpuowl && \
    mkdir gpuowl-master && cp ./build-release/gpuowl ./gpuowl-master && cp LICENSE ./gpuowl-master && cp README.* ./gpuowl-master && \
    tar Jcvf ./gpuowl-master.tar.xz gpuowl-master && mv ./gpuowl-master.tar.xz /artifacts && ls -la /artifacts/

# FROM nvidia/cuda:12.8.0-runtime-ubuntu24.04 as base
FROM nvidia/cuda:12.8.0-base-ubuntu24.04 as base

FROM base as base-amd64

COPY --from=build /artifacts /root

RUN apt update && apt full-upgrade -y && apt install -y --no-install-recommends \
    wget curl mc sudo htop git python3 libgmp10 clinfo unzip tar xz-utils && \
    cd /root && tar xvf ./mfaktc-0.23.0.tar.xz && tar xvf ./gpuowl-master.tar.xz
