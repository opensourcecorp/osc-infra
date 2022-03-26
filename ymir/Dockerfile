# Have to use name Debian releases and not Sid, because Sid doesn't have a
# release file for custom APT repos (like the one Packer is from)
FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_LISTCHANGES_FRONTEND=none

WORKDIR /root

# So scripts will get checked
RUN apt-get update && apt-get install -y shellcheck && rm -rf /var/cache/apt/*

COPY . .

RUN shellcheck ./scripts/* && bash ./scripts/install.sh

WORKDIR /root/packer

ENTRYPOINT ["packer"]
CMD ["help"]
