FROM archlinux:base-devel-20231112.0.191179 as build

RUN pacman -Syu --noconfirm
RUN pacman -S mold clang pkgconf cmake postgresql --noconfirm

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain install nightly --allow-downgrade --profile minimal && rustup default nightly && cargo install sqlx-cli --no-default-features --features native-tls,postgres

WORKDIR /scripty-build
COPY ./scripty .

# ARG SQLX_OFFLINE=1
ENV DATABASE_URL="postgres://scripty:scripty@localhost:5432"
RUN cargo sqlx migrate run && cargo sqlx prepare --workspace
RUN cargo build --release


FROM archlinux:base-20231112.0.191179
RUN pacman -Syu --noconfirm && pacman -S opus --noconfirm

COPY ./scripty/scripty_i18n/locales /i18n
COPY --from=build /scripty-build/target/release /app

VOLUME [ "/config" ]

CMD ["sh", "-c", "/app/scripty_v2 /config/config.toml"]
