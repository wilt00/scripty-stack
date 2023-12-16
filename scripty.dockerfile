FROM archlinux:base-devel-20231112.0.191179 as build-base

RUN pacman -Syu --noconfirm
RUN pacman -S mold clang pkgconf cmake postgresql --noconfirm

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain install nightly --allow-downgrade --profile minimal && rustup default nightly && cargo install sqlx-cli --no-default-features --features native-tls,postgres && cargo install cargo-chef

WORKDIR /scripty-build

FROM build-base as planner
COPY ./scripty .
RUN cargo chef prepare --recipe-path recipe.json

FROM build-base as builder
COPY --from=planner /scripty-build/recipe.json recipe.json
RUN cargo chef cook --release --target x86_64-unknown-linux-gnu --recipe-path recipe.json

COPY ./scripty .

# ARG SQLX_OFFLINE=1
ENV DATABASE_URL="postgres://scripty:scripty@localhost:5432"
RUN cargo sqlx migrate run && cargo sqlx prepare --workspace
RUN cargo build --release --target x86_64-unknown-linux-gnu --bin scripty_v2


FROM archlinux:base-20231112.0.191179
RUN pacman -Syu --noconfirm && pacman -S opus --noconfirm

COPY ./scripty/scripty_i18n/locales /i18n
COPY --from=builder /scripty-build/target/x86_64-unknown-linux-gnu/release /app

VOLUME [ "/config" ]

CMD ["sh", "-c", "/app/scripty_v2 /config/config.toml"]
