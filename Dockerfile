FROM alpine:latest 
MAINTAINER Troy Topnik <troy.topnik@suse.com> 

RUN apk add git vim curl unzip jq
RUN addgroup dev \ 
  && adduser -h /home/dev -G dev -D dev \
  && chown dev:dev /home/dev 

COPY bin/* /usr/local/bin/
COPY .ashrc /home/dev/.ashrc 
USER dev
WORKDIR /home/dev

EXPOSE 8080 

CMD ["/usr/local/bin/ttyd","-p","8080","/bin/sh"]
