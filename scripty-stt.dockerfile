FROM rust:1.74.1

RUN apt-get update && apt-get upgrade -y && apt-get install -y mold libclang1 cmake curl

RUN rustup toolchain install nightly && rustup default nightly && rustup component add rustfmt

WORKDIR /stt-build
COPY ./stt-service .
RUN cargo build --release


FROM alpine:3.19.0

COPY --from=build /stt-build/target/release /app

VOLUME ["/models"]

CMD [ "sh", "-c", "/app/scripty_stt_service /models/$MODEL_NAME $INSTANCE_COUNT" ]
