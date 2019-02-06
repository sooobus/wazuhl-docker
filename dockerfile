FROM ubuntu:18.04

# Clone the following in this folder before start:
# wget https://github.com/mongodb/mongo-c-driver/releases/download/1.13.0/mongo-c-driver-1.13.0.tar.gz
# tar xzf mongo-c-driver-1.13.0.tar.gz
# rm mongo-c-driver-1.13.0.tar.gz
# git clone https://github.com/mongodb/mongo-cxx-driver.git --branch releases/stable --depth 1
# git clone https://github.com/BVLC/caffe.git
# svn co http://llvm.org/svn/llvm-project/test-suite/trunk train.out/llvm-test-suite
# cd tools
# git clone http://hera:8080/gerrit/wazuhl-clang clang

ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD . /wazuhl
#ADD caffe /caffe
#ADD mongo-c-driver-1.13.0 /mongo-c-driver-1.13.0
#ADD mongo-cxx-driver /mongo-cxx-driver
#ADD wazuhl /wazuhl
#ADD wazuhl-training-ground /training-ground
#ADD suites /suites

RUN apt-get update && apt-get install -y python3
RUN apt-get update && apt-get install -y python3-pip
WORKDIR /
RUN ls /wazuhl
RUN pip3 install -r /wazuhl/training-ground/requirements.txt

# Caffe dependencies.
RUN apt-get update && apt-get install -y build-essential cmake git pkg-config libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libatlas-base-dev
RUN apt-get update && apt-get install -y --no-install-recommends libboost-all-dev
RUN apt-get update && apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
RUN apt-get update && apt-get install -y python3-dev
RUN apt-get update && apt-get install -y python3-numpy python3-scipy
RUN apt-get install -y libopencv* opencv*
RUN apt-get update && apt-get install -y python-opencv

ENV LD_LIBRARY_PATH="/usr/local/lib/:/caffe/build/lib/:"


# Install caffe.
WORKDIR /wazuhl/caffe
RUN mkdir build
WORKDIR /wazuhl/caffe/build
RUN cmake ..
RUN make all
RUN make install
RUN make runtest

# Generate proto for wazuhl build.

WORKDIR /wazuhl/caffe
RUN protoc src/caffe/proto/caffe.proto --cpp_out=.
RUN mkdir include/caffe/proto
RUN mv src/caffe/proto/caffe.pb.h include/caffe/proto

# Mongo.

RUN apt-get update &&  apt-get install -y cmake libssl-dev libsasl2-dev
WORKDIR /wazuhl/mongo-c-driver-1.13.0
RUN mkdir cmake-build
WORKDIR /wazuhl/mongo-c-driver-1.13.0/cmake-build
RUN cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF ..
RUN make
RUN make install

WORKDIR /wazuhl/mongo-cxx-driver/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
RUN make EP_mnmlstc_core
RUN make
RUN make install

# Wazuhl install.
RUN apt-get update && apt-get install -y ninja-build

WORKDIR /
RUN mkdir wazuhl-build
WORKDIR /wazuhl-build
RUN cmake -G Ninja /wazuhl -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/llvm
RUN ninja
RUN ninja install

ENTRYPOINT ["python", "wazuhl/training_ground/train.py", "/llvm/bin/clang", "wazuhl/train.out/llvm-test-suite", "wazuhl/train.out/llvm-test-suite-build", "/caffe/build/lib/"]
