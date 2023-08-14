FROM ubuntu:latest
WORKDIR /home/louis/dotfiles
COPY . .
RUN /bin/bash 
# CMD /bin/bash scripts/install

