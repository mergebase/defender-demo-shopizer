# build backend env
FROM adoptopenjdk/openjdk11-openj9:alpine as backend
RUN mkdir /opt/app

# RUN mkdir /files
COPY sm-shop/target/shopizer.jar /opt/app
COPY SALESMANAGER-TEST2.mv.db /opt/app
# COPY ./sm-shop/files /files

# build fontend env
FROM node:16.13.0-alpine as frontend
WORKDIR /opt/react
ENV PATH /opt/react/node_modules/.bin:$PATH
COPY reactjs/package*.json ./
COPY reactjs/.env ./
COPY reactjs/env.sh ./
COPY reactjs/conf ./
#remove internal .env file
RUN npm ci --silent
#must match package.json react-scripts
COPY ./reactjs/ .
RUN npm run build


# production env
FROM nginx:stable-alpine

# Nginx config
RUN rm -rf /etc/nginx/conf.d
COPY reactjs/conf /etc/nginx

RUN ls -al
COPY --from=backend /opt/app /opt/app
RUN apk add openjdk11
COPY --from=frontend /opt/react/build /usr/share/nginx/html

WORKDIR /usr/share/nginx/html
COPY reactjs/env.sh .
COPY reactjs/.env .

RUN ls -al /usr/share/nginx/html

# Add bash
RUN apk add --no-cache bash

# Make our shell script executable
RUN chmod +x env.sh
RUN chmod +x /opt/app/shopizer.jar

EXPOSE 80 8080  

# Start Nginx server
CMD ["/bin/bash", "-c", "/usr/share/nginx/html/env.sh /usr/share/nginx/html"]
