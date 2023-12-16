FROM nvidia/cuda:12.3.1-devel-ubuntu22.04 as build-base

RUN apt-get update && apt-get upgrade -y && apt-get install -y mold libclang1 cmake curl

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain install nightly && rustup default nightly && rustup component add rustfmt
RUN cargo install cargo-chef

WORKDIR /stt-build

FROM build-base as planner
COPY ./stt-service .
RUN cargo chef prepare --recipe-path recipe.json

FROM build-base as builder
COPY --from=planner /stt-build/recipe.json recipe.json
RUN cargo chef cook --release --features cuda --target x86_64-unknown-linux-gnu --recipe-path recipe.json
COPY ./stt-service .
RUN cargo build --release --features cuda


FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get upgrade -y && apt-get install -y netcat && rm -rf /var/lib/apt/lists/*

COPY --from=builder /stt-build/target/release /app

VOLUME ["/models"]

CMD [ "sh", "-c", "/app/scripty_stt_service /models/$MODEL_NAME $INSTANCE_COUNT" ]
