FROM nvidia/cuda:12.3.0-devel-ubuntu22.04 as build

RUN apt-get update && apt-get upgrade -y && apt-get install -y mold libclang1 cmake curl

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain install nightly && rustup default nightly && rustup component add rustfmt

WORKDIR /stt-build
COPY ./stt-service .
RUN cargo build --release --features cuda


FROM nvidia/cuda:12.3.0-runtime-ubuntu22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get upgrade -y && apt-get install -y netcat && rm -rf /var/lib/apt/lists/*

COPY --from=build /stt-build/target/release /app

VOLUME ["/models"]

CMD [ "sh", "-c", "/app/scripty_stt_service /models/$MODEL_NAME $INSTANCE_COUNT" ]
