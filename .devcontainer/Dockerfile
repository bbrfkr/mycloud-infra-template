FROM mcr.microsoft.com/devcontainers/base:noble
USER vscode
WORKDIR /home/vscode

# install python
RUN sudo apt-get update && \
    sudo apt-get -y install python3 python3-venv

# create python venv
RUN python3 -m venv .venv
ENV PATH=/home/vscode/.venv/bin:$PATH

# install openstackclient
COPY requirements.txt .
RUN pip install -r requirements.txt && \
    pip uninstall -y python-zaqarclient && \
    rm requirements.txt

# install tofuenv and opentofu
ENV TOFUENV=/home/vscode/.tofuenv
RUN git clone --depth 1 https://github.com/tofuutils/tofuenv $TOFUENV
ENV PATH=$TOFUENV/bin:$PATH
RUN tofuenv use 1.10.6

# create terraform alias
RUN sudo ln -s /home/vscode/.tofuenv/bin/tofu /usr/bin/terraform
