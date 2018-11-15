FROM ubuntu:18.04

# Install dependencies
RUN apt-get -qq update \
    && apt-get install -y sudo git wget libncurses-dev flex bison gperf \
                            python python-pip python-setuptools python-serial \
                            cmake ninja-build ccache \
                            vim picocom microcom

# Clean install KDevelop without some useless stuff from KDE
RUN apt-get install -y --no-install-recommends kdevelop

# Final cleanup
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Get the ESP32 toolchain
ENV ESP_TCHAIN_BASEDIR /opt/local/espressif

RUN mkdir -p $ESP_TCHAIN_BASEDIR \
    && wget -O $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz \
            https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz \
    && tar -xzf $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz \
           -C $ESP_TCHAIN_BASEDIR/ \
    && rm $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz

RUN mkdir -p $ESP_TCHAIN_BASEDIR \
    && wget -O $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz \
            https://dl.espressif.com/dl/esp32ulp-elf-binutils-linux64-d2ae637d.tar.gz \
    && tar -xzf $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz \
           -C $ESP_TCHAIN_BASEDIR/ \
    && rm $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz

# Setup IDF_PATH
ENV IDF_PATH /esp/esp-idf
RUN mkdir -p $IDF_PATH

# Download ESP-IDF code and binaries
ENV IDF_BRANCH release/v3.2
RUN cd ${IDF_PATH} \
    && git clone -b ${IDF_BRANCH} --recursive https://github.com/espressif/esp-idf.git .

# Add the toolchain binaries to PATH
ENV PATH $ESP_TCHAIN_BASEDIR/xtensa-esp32-elf/bin:$ESP_TCHAIN_BASEDIR/esp32ulp-elf-binutils/bin:$IDF_PATH/tools:$PATH

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Create a developer account
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer && \
    echo 'developer:espidfdev' | chpasswd 

USER developer
ENV HOME /home/developer      

# Set the work directory
RUN mkdir -p ${HOME}/project
WORKDIR ${HOME}/project

# Here we go!
ENTRYPOINT [ "/bin/bash" ]
