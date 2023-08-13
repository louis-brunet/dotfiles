FROM ubuntu:latest
WORKDIR ~/dotfiles
COPY . .
CMD /bin/bash # scripts/install

