M68K=m68k-linux-gnu
AS=$(M68K)-as
LD=$(M68K)-ld
COPY=$(M68K)-objcopy
DUMP=$(M68K)-objdump

CPU=-m68000
ASFLAGS=-march=68000 -mcpu=68000
LDFLAGS=-T m68k.ld -M

START=0x00
FMT=binary

SRCS=blink.s
OBJS=$(SRCS:.s=.o)
MAIN=blink

.PHONY: dump clean

all:	$(MAIN)
	@echo Builds blink.bin

.s.o:
	$(AS) $(ASFLAGS) -o $@ $<

$(MAIN): $(OBJS)
	$(LD) $(LDFLAGS) -o $(MAIN).a $(OBJS)
	$(COPY) -O $(FMT) $(MAIN).a $(MAIN).bin
	$(COPY) -b 0 -i 2 --interleave-width=1 -O $(FMT) $(MAIN).a even-$(MAIN).bin
	$(COPY) -b 1 -i 2 --interleave-width=1 -O $(FMT) $(MAIN).a odd-$(MAIN).bin
	$(COPY) -O $(FMT) $(MAIN).a $(MAIN).bin

clean:
	rm -f *.o $(MAIN).bin $(MAIN).a $(MAIN).map *.bin

dump:	$(MAIN)
	$(DUMP) $(CPU) -x -D $(MAIN).a
