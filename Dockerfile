FROM alpine:3.22.1

RUN apk add --no-cache \
  sqlite=3.49.2-r1 \
  minio-client=0.20250521.015954-r1 \
  bash=5.2.37-r0 \
  jq=1.8.0-r0

RUN addgroup -S grist && adduser -S grist -G grist
USER grist
WORKDIR /app

COPY .sqliterc /home/grist
COPY doc-iterator.sh scripts ./

ENV MINIO_MC=mcli

CMD [ "bash", "doc-iterator.sh", "-h" ]

