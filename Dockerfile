# Setup build arguments with default versions
ARG ANDROID_SDK_VERSION="6200805_latest"
ARG ANDROID_HOME="/opt/android-sdk"
ARG ANDROID_SDK_ROOT="/opt/android-sdk"
ARG ANDROID_BUILD_TOOLS_VERSION="29.0.3"
ARG CHROMIUM_VERSION="81.0.4044.138-0ubuntu0.18.04.1"
ARG AWS_CLI_VERSION="1.18.39"
ARG PYTHON_MAJOR_VERSION="3.6"
ARG NODE_VERSION="13.11.0"
ARG NVM_VERSION="0.35.3"

# Android
FROM ubuntu:18.04 as android
ARG ANDROID_SDK_VERSION
ARG ANDROID_HOME
ARG ANDROID_BUILD_TOOLS_VERSION
RUN apt-get update
RUN apt-get install -y curl unzip openjdk-8-jre openjdk-8-jdk
RUN curl -fSLk "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}.zip" -o commandlinetools-linux.zip
RUN unzip commandlinetools-linux.zip
RUN mkdir ${ANDROID_HOME}
RUN mv tools ${ANDROID_HOME}
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} --licenses
RUN $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# AWS
FROM ubuntu:18.04 as aws
ARG AWS_CLI_VERSION
ARG PYTHON_MAJOR_VERSION
RUN apt-get update
RUN apt-get install -y python3=${PYTHON_MAJOR_VERSION}.7-1~18.04
RUN apt-get install -y python3-pip
RUN pip3 install awscli==${AWS_CLI_VERSION}

# Final image
FROM ubuntu:18.04
WORKDIR /workspace
ARG ANDROID_HOME
ARG ANDROID_SDK_ROOT
ARG CHROMIUM_VERSION
ARG NODE_VERSION
ARG NVM_VERSION
ARG PYTHON_MAJOR_VERSION
ENV ANDROID_HOME=${ANDROID_HOME}
ENV CHROME_BIN=/usr/bin/chromium-browser
# access android tools
ENV PATH="${ANDROID_HOME}/tools/bin:${PATH}"
RUN apt-get update \
  # Install
  && apt-get install -y --no-install-recommends \
  chromium-browser=${CHROMIUM_VERSION} \
  python3=${PYTHON_MAJOR_VERSION}.7-1~18.04 \
  openjdk-8-jre \
  openjdk-8-jdk \
  gradle \
  jq \
  git \
  curl \
  openssh-client \
  # NodeJS
  && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
  && . /root/.nvm/nvm.sh \
  && nvm install ${NODE_VERSION} \
  && nvm alias default ${NODE_VERSION} \
  && nvm use default \
  # Clean
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_MAJOR_VERSION} 1
COPY --from=android ${ANDROID_HOME} ${ANDROID_HOME}
COPY --from=aws /usr/local/bin/aws* /usr/local/bin/
COPY --from=aws /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages
COPY --from=aws /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages
CMD ["bash"]
