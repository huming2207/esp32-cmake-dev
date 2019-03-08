FROM ubuntu:18.10
LABEL maintainer="Jackson Ming Hu <huming2207@gmail.com>"

# Install dependencies
RUN apt-get -qq update \
    && apt-get install -y sudo git wget libncurses-dev flex bison gperf \
                            python python-pip python-setuptools python-serial \
                            cmake ninja-build ccache \
                            vim picocom microcom curl aria2

# Get the ESP32 toolchain with Aussie ADSL workarounds :)
ENV ESP_TCHAIN_BASEDIR /esp/toolchains

RUN mkdir -p $ESP_TCHAIN_BASEDIR \
    && aria2c -x16 -o $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz \
            https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz \
    && tar -xzf $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz \
           -C $ESP_TCHAIN_BASEDIR/ \
    && rm $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz

RUN mkdir -p $ESP_TCHAIN_BASEDIR \
    && aria2c -x16 -o $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz \
            https://dl.espressif.com/dl/esp32ulp-elf-binutils-linux64-d2ae637d.tar.gz \
    && tar -xzf $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz \
           -C $ESP_TCHAIN_BASEDIR/ \
    && rm $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz

# Setup IDF_PATH
ENV IDF_PATH /esp/esp-idf
RUN mkdir -p $IDF_PATH

# Download ESP-IDF code and binaries
ENV IDF_BRANCH master
RUN cd ${IDF_PATH} \
    && git clone -b ${IDF_BRANCH} --recursive https://github.com/espressif/esp-idf.git .

# Add the toolchain binaries to PATH
ENV PATH $ESP_TCHAIN_BASEDIR/xtensa-esp32-elf/bin:$ESP_TCHAIN_BASEDIR/esp32ulp-elf-binutils/bin:$IDF_PATH/tools:$PATH

# Install SSH, ref: https://docs.docker.com/engine/examples/running_ssh_service/
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:espidfdev' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Final cleanup
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Create a developer account
RUN export uid=1001 gid=1001 && \
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

# Install Python dependencies for CMake build system
RUN /usr/bin/python -m pip install --user -r /esp/esp-idf/requirements.txt

# Here we go!
CMD ["/bin/bash"]