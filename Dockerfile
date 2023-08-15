FROM ubuntu:latest
WORKDIR /home/louis/dotfiles
RUN apt update && apt install -y git wget curl
COPY . .
CMD /bin/bash 
# CMD /bin/bash scripts/install

