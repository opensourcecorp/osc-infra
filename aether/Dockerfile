FROM debian:buster

RUN apt-get update && apt-get install -y curl
RUN curl -fsSL -o /tmp/bootstrap-salt.sh https://bootstrap.saltproject.io \
    && \
    bash /tmp/bootstrap-salt.sh -j '{"file_client": "local"}' \
      -P \
      -x python3

COPY sls/ /srv/salt

EXPOSE 4505 4506
