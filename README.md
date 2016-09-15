# Nginx auto #

## What is this? ##

A Docker image for **Nginx** web server, with:
* fully automated configuration based on Docker environment variables
* SSL parameters to provide A+ SSL rating
* HTTP/2 support

Docker repo can be found here: https://hub.docker.com/r/ijoijo/nginx-auto/

This image can be used with **Let's encrypt**, in order to provide SSL certificate with automated certificate creation and renewal.

Associated **Let's encrypt** Docker image can be found here: https://hub.docker.com/r/ijoijo/letsencrypt/


## How to use this image? ##

### HTTP only (without SSL) ###
#### With static content on Docker host ####

```bash
$ docker run -v /some/content:/usr/share/nginx/html:ro -e "NGINX_SERVERNAMES=test.example.com" -p 8080:80 -d ijoijo/nginx-auto
```
with replacing:
* `/some/content` with the correct path on your Docker host
* `test.example.com` by your server name
* `8080` by another port if needed, for ex. `80`


#### With static content within the Docker image ####

Create a `Dockerfile`, with the following content:
```
FROM ijoijo/nginx-auto
COPY static-html-directory /usr/share/nginx/html
```

Build the image:
```bash
$ docker build -t nginx-with-content .
```

Then start container:
```bash
$ docker run -e "NGINX_SERVERNAMES=test.example.com" -p 8080:80 -d nginx-with-content
```
with replacing:
* `test.example.com` by your server name
* `8080` by another port if needed, for ex. `80`


### HTTPS with Let's encrypt (with HTTP/2 support) ###

#### Pre-requisites ####

* Instructions below require **docker-compose** to be installed and running.
* Your server needs to be accessible through Internet on port 80, and be registered on public DNS


#### With static content on Docker host ####

Create a `docker-compose.yml` file, with the following content:
```
version: '2'

services:
  letsencrypt:
    image: ijoijo/letsencrypt
    restart: always
    volumes:
      - acme-webroot:/var/acme-webroot
      - letsencrypt-conf:/etc/letsencrypt
    environment:
      - LETSENCRYPT_HOSTNAMES=test.example.com
      - LETSENCRYPT_EMAIL=john@doe.com

  nginx:
    image: ijoijo/nginx-auto
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - letsencrypt-conf:/etc/letsencrypt:ro
      - acme-webroot:/var/acme-webroot:ro
      - dhparam:/etc/nginx/dhparam
      - wwwlogsvolume:/var/log/nginx
      - /some/content:/usr/share/nginx/html:ro
    environment:
      - NGINX_SERVERNAMES=test.example.com

volumes:
  wwwlogsvolume: {}
  acme-webroot: {}
  letsencrypt-conf: {}
  dhparam: {}

```
with replacing:
* `john@doe.com` by your email
* `test.example.com` by your server name on public DNS, both for `LETSENCRYPT_HOSTNAMES` and `NGINX_SERVERNAMES` variables
* `/some/content` with the correct path on your Docker host

Then start containers:
```bash
$ docker-compose up -d
```

#### With static content within the Docker image ####

Create a `Dockerfile`, with the following content:
```
FROM ijoijo/nginx-auto
COPY static-html-directory /usr/share/nginx/html
```

Build the image:
```bash
$ docker build -t nginx-with-content .
```

Create a `docker-compose.yml` file, with the following content:
```
version: '2'

services:
  letsencrypt:
    image: ijoijo/letsencrypt
    restart: always
    volumes:
      - acme-webroot:/var/acme-webroot
      - letsencrypt-conf:/etc/letsencrypt
    environment:
      - LETSENCRYPT_HOSTNAMES=test.example.com
      - LETSENCRYPT_EMAIL=john@doe.com

  nginx:
    image: nginx-with-content
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - letsencrypt-conf:/etc/letsencrypt:ro
      - acme-webroot:/var/acme-webroot:ro
      - dhparam:/etc/nginx/dhparam
      - wwwlogsvolume:/var/log/nginx
    environment:
      - NGINX_SERVERNAMES=test.example.com

volumes:
  wwwlogsvolume: {}
  acme-webroot: {}
  letsencrypt-conf: {}
  dhparam: {}

```
with replacing:
* `john@doe.com` by your email
* `test.example.com` by your server name on public DNS, both for `LETSENCRYPT_HOSTNAMES` and `NGINX_SERVERNAMES` variables

Then start containers:
```bash
$ docker-compose up -d
```

## Contribution ##

Any suggestions and contributions are welcome and encouraged.

## License ##

* The code for this docker image is licensed under the [MIT License](LICENSE)
* Nginx is licensed under the [BSD License](http://nginx.org/LICENSE)
