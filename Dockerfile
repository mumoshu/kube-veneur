FROM alpine:edge

COPY rootfs/ /
COPY s6-overlay/ /
COPY bin/ /bin

RUN apk add --update --no-cache ca-certificates

ENV VENEUR_DEBUG false
ENV VENEUR_ENABLE_PROFILING false
ENV VENEUR_FORWARD_ADDRESS http://veneur.example.com

CMD adduser -D -u 1000 -g 1000 --home /veneur veneur

EXPOSE 8126 8127

ENTRYPOINT [ "/init" ]

CMD /bin/s6-envuidgid -D 1000:1000 veneur /bin/veneur -f /veneur/veneur.yaml

