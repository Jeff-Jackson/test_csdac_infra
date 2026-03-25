FROM ubuntu:20.04

### Default env
ENV TERRAFORM_VERSION="1.5.7"
ENV AWS_DEFAULT_REGION="us-west-1"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

### OS packages
RUN apt update && apt upgrade -y && apt install -y locales gawk jq xxd curl git wget unzip python3 python3-pip gcc make \
    && pip3 install boto3 && locale-gen en_US.UTF-8

RUN pip3 install requests

### AWS CLI v2
RUN wget -q "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "/tmp/awscliv2.zip" \
    && unzip /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install

### Terraform
RUN wget -q -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm /tmp/terraform.zip

### Terraspace
RUN echo "deb https://apt.boltops.com stable main" > /etc/apt/sources.list.d/boltops.list && curl -s https://apt.boltops.com/boltops-key.public | apt-key add -
RUN apt update && apt install rubygems -y && gem install bundler -v 2.4.22 && apt install -y terraspace

### Kubectl install (using fixed version for reliability)
ENV KUBECTL_VERSION="v1.29.0"
RUN curl -fsSL --retry 5 --retry-delay 5 -o /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl && \
    rm -f /tmp/kubectl

### Kustomize tool for a k8s
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Download and install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm get_helm.sh

# Verify installations
RUN kubectl version --client && \
    helm version && \
    xxd -version

### Cleanup
RUN rm -rf /tmp/*
