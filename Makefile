M68K=m68k-linux-gnu
AS=$(M68K)-as
LD=$(M68K)-ld
COPY=$(M68K)-objcopy
DUMP=$(M68K)-objdump

CPU=-m68000
ASFLAGS=$(CPU)
LDFLAGS=-T m68k.ld -M

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
	$(COPY) -b 0 -i 2 --interleave-width=1 -O $(FMT) $(MAIN).a even-$(MAIN).bin
	$(COPY) -b 1 -i 2 --interleave-width=1 -O $(FMT) $(MAIN).a odd-$(MAIN).bin

clean:
	rm -f *.o even-$(MAIN).bin odd-$(MAIN).bin $(MAIN).a

dump:	$(MAIN)
	$(DUMP) $(CPU) -x -D $(MAIN).a
