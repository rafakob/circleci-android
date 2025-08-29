FROM cimg/base:2024.02

LABEL maintainer="CircleCI Execution Team <eng-execution@circleci.com>"

# Java 21 only
RUN sudo apt-get update && sudo apt-get install -y \
		ant \
		openjdk-21-jdk \
		ruby-full \
	&& \
	sudo rm -rf /var/lib/apt/lists/* && \
	ruby -v && \
	sudo gem install bundler && \
	bundle version

RUN sudo chmod -R a+w /var/lib/gems/ /usr/local/bin

ENV M2_HOME=/usr/local/apache-maven
ENV MAVEN_OPTS=-Xmx2048m
ENV PATH=$M2_HOME/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV JDK_HOME=${JAVA_HOME}
ENV JRE_HOME=${JDK_HOME}
ENV MAVEN_VERSION=3.9.9

RUN curl -sSL -o /tmp/maven.tar.gz http://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
	sudo tar -xz -C /usr/local -f /tmp/maven.tar.gz && \
	sudo ln -sf /usr/local/apache-maven-${MAVEN_VERSION} /usr/local/apache-maven && \
	rm -rf /tmp/maven.tar.gz && \
	mkdir -p /home/circleci/.m2

# Gradle
# ENV GRADLE_VERSION=8.13
# ENV PATH=$PATH:/usr/local/gradle-${GRADLE_VERSION}/bin
# RUN curl -sSL -o /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
#	sudo unzip -d /usr/local /tmp/gradle.zip && \
#	rm -rf /tmp/gradle.zip

# Android SDK (only 35 and 36, no emulator)
ENV ANDROID_HOME="/home/circleci/android-sdk"
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV CMDLINE_TOOLS_ROOT="${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/platform-tools/bin:${PATH}"

RUN SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip" && \
	mkdir -p ${ANDROID_HOME}/cmdline-tools && \
	mkdir ${ANDROID_HOME}/platforms && \
	mkdir ${ANDROID_HOME}/ndk && \
	wget -O /tmp/cmdline-tools.zip -t 5 "${SDK_TOOLS_URL}" && \
	unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
	rm /tmp/cmdline-tools.zip && \
	mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "tools" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platform-tools" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;35.0.1" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;36.0.0-rc5" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-35" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-36"

# Optional extras (keep what you use)
RUN echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;android;m2repository" && \
	echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;google;m2repository" && \
	sudo gem install fastlane --version 2.227.0 --no-document && \
	curl -sL https://firebase.tools | bash

# Google Cloud CLI
ENV GCLOUD_VERSION=453.0.0-0
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
	sudo add-apt-repository "deb https://packages.cloud.google.com/apt cloud-sdk main" && \
	sudo apt-get update && sudo apt-get install -y google-cloud-sdk=${GCLOUD_VERSION} && \
	sudo gcloud config set --installation component_manager/disable_update_check true && \
	sudo gcloud config set disable_usage_reporting false
