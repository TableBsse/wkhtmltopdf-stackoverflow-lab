.PHONY: build crash gdb shell clean

IMAGE = wkhtmltopdf-stackoverflow-lab:latest
RUN   = docker run --rm -it \
          --security-opt seccomp:unconfined \
          --cap-add SYS_PTRACE \
          -v $(PWD)/payloads:/lab/payloads:ro \
          -v $(PWD)/output:/lab/output \
          $(IMAGE)

build:
	docker build -t $(IMAGE) .

crash:
	$(RUN) bash /lab/payloads/replay.sh

gdb:
	$(RUN) bash /lab/payloads/replay.sh --gdb

shell:
	$(RUN) bash

clean:
	docker rmi $(IMAGE) 2>/dev/null || true
	rm -f output/*
