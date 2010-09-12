### Makefile  -*- Makefile -*-

DESTDIR  =
prefix   = /usr/local
bindir   = $(prefix)/bin
mandir   = $(prefix)/share/man
man1dir  = $(mandir)/man1
perllibdir = $(prefix)/lib/site_perl
pkgperllibdir = $(perllibdir)/fdrdf

INSTALL  = install
XSLTPROC = xsltproc

srcdir   = .
pmsrcdir = $(srcdir)/lib/perl/fdrdf
modules  = file grib sha1 stat test

all:
	## There isn't much to be done for `all'
	## Use `$ make install' to install FDRDF
	true

doc: doc/fdrdf.1

doc/fdrdf.1: doc/fdrdf.xml
	$(XSLTPROC) -o $@ $<

install:
	$(INSTALL) -d -- \
	    $(bindir) $(man1dir) $(perllibdir)/fdrdf/module
	$(INSTALL) -m 0644 -- \
	    $(modules:%=$(pmsrcdir)/module/%.pm) \
	    $(pkgperllibdir)/module/
	$(INSTALL) -m 0755 -- $(srcdir)/doc/fdrdf.1 $(man1dir)/fdrdf.1
	$(INSTALL) -m 0755 -- $(srcdir)/src/fdrdf.pl $(bindir)/fdrdf

### Makefile ends here
