FROM traefik:v2.9.1
RUN mkdir -p /etc/traefik/acme \
  && touch /etc/traefik/acme/acme.json \
  && chmod 600 /etc/traefik/acme/acme.json

COPY ./docker/production/traefik/traefik.yml /etc/traefik
COPY ./docker/production/traefik/traefik-dynamic-conf.yml /etc/traefik

############################
# mkcert
RUN mkdir -p /etc/traefik/certs
RUN mkdir -p /usr/local/share/mkcert
RUN mkdir -p /usr/local/bin

#COPY ./certs/cert.pem /etc/traefik/certs
#COPY .//etc/traefik/certs/cert.pemcerts/key.pem /etc/traefik/certs

# copy mkcert binaries and select the one that fits to the architecture
COPY ./cert/mkcert* /usr/local/share/mkcert/

RUN if [ "${TARGETPLATFORM}" == "linux/arm/v7" ]; then \
  cp /usr/local/share/mkcert/mkcert-arm /usr/local/bin/mkcert; \
  else cp /usr/local/share/mkcert/mkcert-amd64 /usr/local/bin/mkcert; fi
RUN chmod 755 /usr/local/bin/mkcert


# custom entry point to generate the certs before traefik gets started
COPY ./docker/production/traefik/custom-entrypoint /custom-entrypoint
RUN chmod +x /custom-entrypoint

#ENTRYPOINT ["/custom-entrypoint"]
#CMD ["traefik"]
