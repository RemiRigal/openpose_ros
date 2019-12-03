FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04
# Build with
#    docker image build --network host -t openpose_ros:cuda10.0 .
# Start with
#    docker run -it --rm --gpus all --network host openpose_ros:cuda10.0

RUN echo "Installing dependencies..." && \
	apt-get -y --no-install-recommends update && \
	apt-get -y --no-install-recommends upgrade && \
	apt-get install -y --no-install-recommends \
	build-essential \
	cmake \
	git \
	libatlas-base-dev \
	libprotobuf-dev \
	libleveldb-dev \
	libsnappy-dev \
	libhdf5-serial-dev \
	protobuf-compiler \
	libboost-all-dev \
	libgflags-dev \
	libgoogle-glog-dev \
	liblmdb-dev \
	pciutils \
	python-setuptools \
	python-dev \
	python-pip \
	opencl-headers \
	ocl-icd-opencl-dev \
	libviennacl-dev \
	libcanberra-gtk-module \
	libopencv-dev

RUN echo "Installing Pip packages" && \
	python -m pip install protobuf scipy==0.16

RUN echo "Installing ROS packages" && \
    apt-get update && apt-get install curl && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list' && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | apt-key add - && \
    apt-get update && \
    apt-get install -y \
        ros-kinetic-robot \
        ros-kinetic-cv-bridge \
        ros-kinetic-vision-opencv \
        ros-kinetic-image-transport \
        ros-kinetic-image-transport-plugins \
        ros-kinetic-tf2-geometry-msgs

RUN echo "Downloading and building OpenPose..." && \
	git clone --single-branch --branch master https://github.com/CMU-Perceptual-Computing-Lab/openpose.git && \
	cd /openpose && git checkout 254570df262d91b1940aaf5797ba6c5d6db4b52f && \
	mkdir -p /openpose/build && \
	cd /openpose/build && \
	cmake .. \
	    -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
	    -DCUDA_TOOLKIT_INCLUDE=/usr/local/cuda/include \
	    -DCUDA_NVCC_EXECUTABLE=/usr/local/cuda/bin/nvcc \
	    -DOpenCV_DIR=/opt/ros/kinetic/share/OpenCV-3.3.1-dev \
	    -DDOWNLOAD_BODY_COCO_MODEL:BOOL=OFF \
	    -DDOWNLOAD_BODY_MPI_MODEL:BOOL=OFF \
	    -DDOWNLOAD_BODY_25_MODEL:BOOL=OFF  \
	    -DDOWNLOAD_FACE_MODEL:BOOL=OFF  \
	    -DDOWNLOAD_HAND_MODEL:BOOL=OFF \
	    -DUSE_CUDNN:BOOL=ON \
	    -DCUDA_cublas_LIBRARY=/usr/local/cuda/lib64/libcublas.so && \
	make -j`nproc` && \
	make install

COPY . /catkin_ws/src
RUN echo "Building OpenPose ROS..." && \
    cd /catkin_ws && \
    /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /catkin_ws; catkin_make; . devel/setup.bash'
WORKDIR /catkin_ws

COPY ./entrypoint.sh /entrypoint.sh

RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/entrypoint.sh"]
CMD ["roslaunch",  "openpose_ros", "openpose_ros.launch"]
