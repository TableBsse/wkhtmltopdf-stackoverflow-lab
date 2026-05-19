FROM ubuntu:bionic

RUN apt-get update -qq && apt-get install -y -q \
    gdb curl \
    libssl1.1 libxext6 libxrender1 libfontconfig1 libfreetype6 \
    libx11-6 libglib2.0-0 libpng16-16 libjpeg8 zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Download pre-built debug binary and compat libs from GitHub Release
# wkhtmltopdf 0.12.6 compiled with -g -O1 inside wkhtmltopdf/0.12:bionic-amd64
RUN mkdir -p /lab/bin /lab/libs /lab/output && \
    curl -fsSL https://github.com/TableBsse/wkhtmltopdf-stackoverflow-lab/releases/download/v0.12.6-debug/wkhtmltopdf \
         -o /lab/bin/wkhtmltopdf && \
    curl -fsSL https://github.com/TableBsse/wkhtmltopdf-stackoverflow-lab/releases/download/v0.12.6-debug/libssl.so.1.1 \
         -o /lab/libs/libssl.so.1.1 && \
    curl -fsSL https://github.com/TableBsse/wkhtmltopdf-stackoverflow-lab/releases/download/v0.12.6-debug/libcrypto.so.1.1 \
         -o /lab/libs/libcrypto.so.1.1 && \
    chmod +x /lab/bin/wkhtmltopdf

RUN echo "set pagination off" > /root/.gdbinit && \
    echo "catch signal SIGSEGV" >> /root/.gdbinit && \
    echo "catch signal SIGABRT" >> /root/.gdbinit

ENV LD_LIBRARY_PATH=/lab/libs
COPY payloads/ /lab/payloads/
WORKDIR /lab
