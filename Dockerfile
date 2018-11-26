FROM ubuntu:18.04

ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
#WORKDIR /root

ADD caffe /caffe
ADD mongo-c-driver-1.13.0 /mongo-c-driver-1.13.0
ADD mongo-cxx-driver /mongo-cxx-driver
ADD wazuhl /wazuhl

# caffe dependencies
RUN apt-get update && apt-get install -y build-essential cmake git pkg-config libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libatlas-base-dev 
RUN apt-get update && apt-get install -y --no-install-recommends libboost-all-dev
RUN apt-get update && apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev

RUN apt-get update && apt-get install python3
RUN apt-get update && apt-get install -y python3-pip

RUN apt-get update && apt-get install -y python3-dev
RUN apt-get update && apt-get install -y python3-numpy python3-scipy

RUN apt-get install -y libopencv* opencv*

RUN apt-get update && apt-get install -y python-opencv

#install caffe
WORKDIR /caffe
RUN mkdir build
WORKDIR /caffe/build
RUN cmake ..
RUN make all
RUN make install
RUN make runtest

# generate proto for wazuhl build
 #try build/include

WORKDIR /caffe
RUN protoc src/caffe/proto/caffe.proto --cpp_out=.
RUN mkdir include/caffe/proto
RUN mv src/caffe/proto/caffe.pb.h include/caffe/proto

ENV LD_LIBRARY_PATH /caffe/build/lib/:${LD_LIBRARY_PATH}

# mongo
#wget https://github.com/mongodb/mongo-c-driver/releases/download/1.13.0/mongo-c-driver-1.13.0.tar.gz
#tar xzf mongo-c-driver-1.13.0.tar.gz

RUN apt-get update &&  apt-get install -y cmake libssl-dev libsasl2-dev

WORKDIR /mongo-c-driver-1.13.0
RUN mkdir cmake-build
WORKDIR /mongo-c-driver-1.13.0/cmake-build
RUN cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF ..
RUN make
RUN make install

#git clone https://github.com/mongodb/mongo-cxx-driver.git \
 #    --branch releases/stable --depth 1
WORKDIR /mongo-cxx-driver/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
RUN make EP_mnmlstc_core
RUN make
RUN make install

RUN apt-get update && apt-get install -y ninja-build

WORKDIR /
RUN mkdir wazuhl-build
WORKDIR /wazuhl-build
RUN cmake -G Ninja /wazuhl -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/llvm
RUN LD_LIBRARY_PATH=/caffe/build/lib/ ninja
RUN ninja install