FROM cimg/base:2026.03
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
RUN curl -fsSL -o /tmp/maven.tar.gz https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
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
# Android SDK (36 and 37, no emulator)
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
	if [ -d ${ANDROID_HOME}/cmdline-tools/cmdline-tools ]; then \
		mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest; \
	else \
		mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
		mv ${ANDROID_HOME}/cmdline-tools/bin ${ANDROID_HOME}/cmdline-tools/lib ${ANDROID_HOME}/cmdline-tools/NOTICE.txt ${ANDROID_HOME}/cmdline-tools/source.properties ${ANDROID_HOME}/cmdline-tools/latest/; \
	fi
# Non-fatal: list available build-tools/platforms 36-40 (read with --progress=plain when bumping versions)
RUN echo "===== AVAILABLE build-tools/platforms 36-40 =====" && \
	${CMDLINE_TOOLS_ROOT}/sdkmanager --list 2>/dev/null | grep -E "build-tools;(3[6-9]|40)|platforms;android-(3[6-9]|40)" || echo "  (none matched)"; \
	true
# Accept licenses (yes || true swallows SIGPIPE so pipefail sees sdkmanager's status), then install
RUN (yes || true) | ${CMDLINE_TOOLS_ROOT}/sdkmanager --licenses && \
    ${CMDLINE_TOOLS_ROOT}/sdkmanager "platform-tools" && \
    ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;36.0.0" && \
    ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;37.0.0" && \
    ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-36" && \
    ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-37.1"
# Optional extras (keep what you use)
RUN ${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;android;m2repository" && \
	${CMDLINE_TOOLS_ROOT}/sdkmanager "extras;google;m2repository" && \
	sudo gem install fastlane --version 2.227.0 --no-document && \
	curl -sL https://firebase.tools | bash
# Google Cloud CLI (modern keyring method; apt-key is removed on Ubuntu 24.04)
ENV GCLOUD_VERSION=453.0.0-0
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
	echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
	sudo apt-get update && sudo apt-get install -y google-cloud-cli=${GCLOUD_VERSION} && \
	sudo gcloud config set --installation component_manager/disable_update_check true && \
	sudo gcloud config set disable_usage_reporting false