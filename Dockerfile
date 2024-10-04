FROM alpine
LABEL org.opencontainers.image.source=https://github.com/midzelis/psql-client

# Install psql client
RUN apk --no-cache add postgresql-client curl bash catatonit 
SHELL [ "bash" ]

COPY --chmod=0755 "init.sh" .
COPY --chmod=0755 "immich.sh" .
ENTRYPOINT ["/usr/bin/catatonit", "--"]
CMD ["/init.sh"]
