FROM nvidia/cuda:12.8.0-devel-ubuntu24.04 as build

RUN apt update && apt install -y --no-install-recommends \
    wget curl mc sudo htop build-essential nvidia-opencl-dev git \
    ocl-icd-dev libgmp10 libgmp-dev make cmake clinfo patch diffutils unzip

RUN cd $HOME && [[ -f mfaktc-0.23.0.zip ]] && rm -f mfaktc-0.23.0.zip; \
    [[ -d ./mfaktc-0.23.0 ]] && rm -rf ./mfaktc-0.23.0; \
    rm -rf /artifacts; mkdir /artifacts; \
    wget "https://download.mersenne.ca/mfaktc/source-code/mfaktc-0.23.0.zip" && \
    unzip -o ./mfaktc-0.23.0.zip && cd mfaktc-0.23.0/src && \
    sed -i -e 's/CFLAGS = -Wall -Wextra -O2/CFLAGS = -Wall -Wextra -O3 -flto -ffunction-sections -fdata-sections -Wl,--gc-sections/' \
           -e 's/NVCCFLAGS += --generate-code/NVCCFLAGS += -O3 --generate-code/' Makefile && \
    make -j$(nproc) && sleep 5 && cd ../.. && strip ./mfaktc-0.23.0/mfaktc && tar Jcvf ./mfaktc-0.23.0.tar.xz --exclude ./mfaktc-0.23.0/src ./mfaktc-0.23.0 && \
    mv mfaktc-0.23.0.tar.xz /artifacts; \
    cd $HOME && rm -rf gpuowl; git clone https://github.com/preda/gpuowl gpuowl && \
    cd gpuowl && git checkout gpuowl && make -j$(nproc) && strip build-release/gpuowl && \
    cp ./build-release/gpuowl . && tar Jcvf ./gpuowl-master.tar.xz LICENSE README.md gpuowl && \
    mv ./gpuowl-master.tar.xz /artifacts && ls -la /artifacts/

FROM nvidia/cuda:12.8.0-runtime-ubuntu24.04 as base

FROM base as base-amd64

COPY --from=build /artifacts $HOME
