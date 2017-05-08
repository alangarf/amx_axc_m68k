M68K=m68k-linux-gnu
AS=$(M68K)-as
LD=$(M68K)-ld
COPY=$(M68K)-objcopy
DUMP=$(M68K)-objdump

CPU=-m68000
ASFLAGS=$(CPU)
LDFLAGS=-T m68k.ld

EEPROM=AT28C256
PREFIX=m68k-

FMT=binary

SRCS=blink.s
OBJS=$(SRCS:.s=.o)
MAIN=blink

.PHONY: dump clean

all:	$(MAIN)

.s.o:
	$(AS) $(ASFLAGS) -o $@ $<

$(MAIN): $(OBJS)
	$(LD) $(LDFLAGS) -o $(MAIN).a $(OBJS)
	$(COPY) -b 0 -i 2 --interleave-width=1 -O $(FMT) $(MAIN).a $(PREFIX)$(MAIN)-even.bin
	$(COPY) -b 1 -i 2 --interleave-width=1 -O $(FMT) $(MAIN).a $(PREFIX)$(MAIN)-odd.bin

clean:
	rm -f *.o $(PREFIX)$(MAIN)-even.bin $(PREFIX)$(MAIN)-odd.bin $(MAIN).a

prog_even:
	@echo Programming $(MAIN)-even onto $(EEPROM)
	minipro -p "$(EEPROM)" -w $(PREFIX)$(MAIN)-even.bin -s

prog_odd:
	@echo Programming $(MAIN)-odd onto $(EEPROM)
	minipro -p "$(EEPROM)" -w $(PREFIX)$(MAIN)-odd.bin -s

dump:	$(MAIN)
	$(DUMP) $(CPU) -x -D $(MAIN).a
