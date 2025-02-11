# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:edge

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    git \
    python3 && \
  mkdir -p /app/mkdocs/docs && \
  git config --global --add safe.directory /app/mkdocs && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    wheel

COPY requirements.txt /app/mkdocs/requirements.txt

RUN \
  pip install -U --no-cache-dir \
    -r /app/mkdocs/requirements.txt

COPY . /app/mkdocs/

WORKDIR /app/mkdocs

ENTRYPOINT ["catatonit", "--", "mkdocs", "serve"]

CMD [ "-a", "0.0.0.0:8000" ]
