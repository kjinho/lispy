ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS build
ARG DUCKDB_VERSION
RUN apk add --update --no-cache make cmake gcc musl-dev g++ git openssl-dev openssl-libs-static samurai python3

ENV GEN=ninja \
    EXTRA_CMAKE_VARIABLES='-DBUILD_UNITTESTS=FALSE -DBUILD_SHELL=FALSE' \
    BUILD_HTTPFS=1 \
    BUILD_JSON=1 \
    STATIC_OPENSSL=1 \
    EXTENSION_STATIC_BUILD=1

RUN set -x \
    && cd /tmp \
    && git clone --depth=1 -b v${DUCKDB_VERSION} https://github.com/duckdb/duckdb \
    && cd duckdb \
    && make release \
    && mkdir -p /duckdb/usr/local/lib \
    && mkdir -p /duckdb/usr/local/include \
    && cp -pv build/release/src/*.so /duckdb/usr/local/lib \
    && cp -pv src/include/*.h /duckdb/usr/local/include \
    && cd ../ \
    && rm -rf /tmp/duckdb*

FROM scratch
COPY --from=build /duckdb /libduckdb

FROM fukamachi/sbcl:latest-alpine
RUN apk --no-cache add gcc bash make curl ncurses-dev git musl-dev
RUN curl -L https://qlot.tech/installer | sh
RUN git clone https://github.com/lem-project/lem.git \
    && cd lem \
    && qlot install \
    && qlot exec sbcl --noinform --load scripts/build-ncurses.lisp \
    && install lem /usr/local/bin
RUN git clone https://github.com/lem-project/micros ~/.qlot/local-projects/micros
RUN install -d ~/.lem
RUN echo "(define-command slime-qlot-exec () ()" >> ~/.lem/init.lisp
RUN echo "  (let ((command (first (lem-lisp-mode/implementation::list-roswell-with-qlot-commands))))" >> ~/.lem/init.lisp
RUN echo "    (when command" >> ~/.lem/init.lisp
RUN echo "      (lem-lisp-mode:run-slime command))))" >> ~/.lem/init.lisp
COPY --from=0 /duckdb/usr/local/lib/libduckdb.so /usr/local/lib
ENTRYPOINT ["lem"]
