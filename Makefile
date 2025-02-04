all: imx_usb imx_uart

DESTDIR ?=
prefix ?= /usr
bindir ?= $(prefix)/bin
sysconfdir ?= $(prefix)/etc
rel_sysconfdir = $(shell realpath -m --relative-to=$(bindir) $(sysconfdir))

BUILDHOST := $(shell uname -s)
BUILDHOST := $(patsubst CYGWIN_%,CYGWIN,$(BUILDHOST))

ifneq ($(BUILDHOST),CYGWIN)
PKG_CONFIG ?= pkg-config
USBCFLAGS = `$(PKG_CONFIG) --cflags libusb-1.1`
USBLDFLAGS = `$(PKG_CONFIG) --libs libusb-1.0`
else
USBCFLAGS = -I/usr/include/libusb-1.0
USBLDFLAGS = -L/usr/lib -lusb-1.0
endif
CONFCPPFLAGS = -DSYSCONFDIR='"$(sysconfdir)"' -DREL_SYSCONFDIR='"$(rel_sysconfdir)"'
CFLAGS ?= -Wall -Wstrict-prototypes -Wno-trigraphs

imx_usb.o : imx_usb.c imx_sdp.h imx_loader_config.h portable.h
	$(CC) -c $*.c -o $@ -pipe -ggdb $(USBCFLAGS) $(CFLAGS) $(CONFCPPFLAGS)

%.o : %.c imx_sdp.h imx_loader_config.h portable.h image.h
	$(CC) -c $*.c -o $@ -pipe -ggdb $(CFLAGS) $(CONFCPPFLAGS)

imx_usb: imx_usb.o imx_sdp.o imx_sdp_simulation.o imx_loader_config.o sdp.o sdps.o
	$(CC) -o $@ $^ $(LDFLAGS) $(USBLDFLAGS)

imx_uart: imx_uart.o imx_sdp.o imx_loader_config.o sdp.o
	$(CC) -o $@ $^ $(LDFLAGS)

install: imx_usb imx_uart
	mkdir -p '$(DESTDIR)$(sysconfdir)/imx-loader.d/'
	install -m644 *.conf '$(DESTDIR)$(sysconfdir)/imx-loader.d/'
	mkdir -p '$(DESTDIR)$(bindir)'
	install -m755 imx_usb '$(DESTDIR)$(bindir)/imx_usb'
	install -m755 imx_uart '$(DESTDIR)$(bindir)/imx_uart'

uninstall:
	rm -rf '$(DESTDIR)$(sysconfdir)/imx-loader.d/'
	rm -rf '$(DESTDIR)$(bindir)/imx_usb'
	rm -rf '$(DESTDIR)$(bindir)/imx_uart'

clean:
	rm -f imx_usb imx_uart *.o

tests: imx_usb
	$(MAKE) -C tests/ tests

regen: imx_usb
	$(MAKE) -C tests/ regen

.PHONY: all clean install tests
