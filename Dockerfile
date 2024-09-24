FROM alpine
LABEL org.opencontainers.image.source=https://github.com/midzelis/psql-client

# Install psql client
RUN apk --no-cache add postgresql-client curl bash

ENTRYPOINT  ["bash"]