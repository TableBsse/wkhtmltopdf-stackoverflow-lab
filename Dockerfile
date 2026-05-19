# Stage 1: build wkhtmltopdf with debug symbols
FROM wkhtmltopdf/0.12:bionic-amd64 AS builder

RUN apt-get update -qq && apt-get install -y -q git 2>/dev/null

RUN git clone --depth=1 --branch 0.12.6 \
    https://github.com/wkhtmltopdf/wkhtmltopdf.git /src

WORKDIR /build
RUN /tgt/qt/bin/qmake \
    QMAKE_CFLAGS="-g -O1" \
    QMAKE_CXXFLAGS="-g -O1" \
    QMAKE_LFLAGS="" \
    CONFIG+="debug" \
    CONFIG-="release" \
    CONFIG+=silent \
    /src/wkhtmltopdf.pro && \
    make -j$(nproc)

# Stage 2: runtime lab environment
FROM ubuntu:bionic AS lab

RUN apt-get update -qq && apt-get install -y -q \
    gdb \
    libssl1.1 \
    libxext6 \
    libxrender1 \
    libfontconfig1 \
    libfreetype6 \
    libx11-6 \
    libglib2.0-0 \
    libpng16-16 \
    libjpeg8 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Copy the debug binary
COPY --from=builder /build/bin/wkhtmltopdf /lab/bin/wkhtmltopdf

# Copy Qt shared libs (the binary was linked against the patched Qt)
COPY --from=builder /tgt/qt/lib /lab/qt/lib

# Copy payloads
COPY payloads/ /lab/payloads/

# gdb config: don't paginate, catch signals
RUN echo "set pagination off" > /root/.gdbinit && \
    echo "catch signal SIGSEGV" >> /root/.gdbinit && \
    echo "catch signal SIGABRT" >> /root/.gdbinit

ENV LD_LIBRARY_PATH=/lab/qt/lib
WORKDIR /lab
