FROM alpine:latest 
MAINTAINER Troy Topnik <troy.topnik@suse.com> 

RUN apk add git vim curl unzip jq
RUN addgroup dev -g 2000 \ 
  && adduser -h /home/dev -G dev -D dev -u 2000 

COPY bin/* /usr/local/bin/
COPY .ashrc /home/dev/.ashrc 
USER dev
WORKDIR /home/dev

EXPOSE 8080 

CMD ["/usr/local/bin/ttyd","-p","8080","/bin/sh"]
