FROM ubuntu:18.04

# caffe dependencies
RUN apt-get update && apt-get install -y build-essential cmake git pkg-config libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libatlas-base-dev 
RUN apt-get update && apt-get install -y --no-install-recommends libboost-all-dev
RUN apt-get update && apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev

RUN apt-get update && apt-get install python3
RUN apt-get update && apt-get install -y python3-pip

RUN apt-get update && apt-get install -y python3-dev
RUN apt-get update && apt-get install -y python3-numpy python3-scipy

RUN apt-get update && apt-get install -y python-opencv
