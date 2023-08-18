FROM ubuntu:latest
WORKDIR /home/louis/dotfiles
RUN apt update && apt install -y git wget curl zsh
COPY . .
CMD /bin/bash ./scripts/bootstrap && ./scripts/install && exec zsh

