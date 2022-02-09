FROM amd64/ubuntu:latest

# Change apt source to tuna
# RUN mv /etc/apt/sources.list /etc/apt/sources.list.backup && \
#     touch /etc/apt/sources.list && \
#     echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse" >> /etc/apt/sources.list && \
#     echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
#     echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
#     echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list

# Install tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget unzip && \
    apt-get install -y openjdk-11-jdk python3.8 && \
    # Change default tzdata config
    echo "Asia/Shanghai" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Install Android SDK Manager
WORKDIR /root
RUN wget -O commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip && \
    unzip commandlinetools.zip && \
    mkdir -p ./android/sdk/cmdline-tools/latest && \
    mv ./cmdline-tools/* ./android/sdk/cmdline-tools/latest/ && \
    rm -r cmdline-tools && \
    rm commandlinetools.zip

# Install Android SDK
WORKDIR /root/android/sdk/cmdline-tools/latest/bin
RUN yes | ./sdkmanager --install "platforms;android-30" "build-tools;30.0.3" "ndk;21.4.7075529" && \
    echo "export ANDROID_HOME=/root/android/sdk" >> $HOME/.bashrc && \
    echo "export ANDROID_NDK_HOME=/root/android/sdk/ndk/21.4.7075529" >> $HOME/.bashrc && \
    echo "export PATH=$PATH:/root/android/sdk/cmdline-tools/latest/bin" >> $HOME/.bashrc

# Install Bazel
WORKDIR /root
RUN apt-get install -y apt-transport-https curl gnupg && \
    curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg && \
    mv bazel.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    apt-get update && \
    apt-get install -y bazel

# Install tools
RUN apt-get install -y git vim

# Clone repo and build lyra
RUN git clone https://github.com/reekystive/lyra.git && \
    cd lyra && \
    bazel build -c opt :encoder_main && \
    bazel build -c opt :decoder_main && \
    bazel build -c opt :encoder_main --config=android_arm64 && \
    bazel build -c opt :decoder_main --config=android_arm64 && \
    bazel build android_example:lyra_android_example --config=android_arm64 --copt=-DBENCHMARK
