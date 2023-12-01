FROM postgres:16.1
COPY ./migrations /docker-entrypoint-initdb.d
