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
pmsrcdir = $(srcdir)/lib/perl
perl_modules = \
	$(fdrdf_modules:%=fdrdf::module::%) \
	fdrdf::proto fdrdf::proto::chunks fdrdf::proto::io \
	fdrdf::util \
	fdrdf::xfmcache fdrdf::xfmcache::proto
fdrdf_modules = \
	file gdal gdalinfo grib sha1 stat test

perl_module_files = $(subst ::,/,$(perl_modules:%=%.pm))

all:
	## There isn't much to be done for `all'
	## Use `$ make install' to install FDRDF
	true

doc: doc/fdrdf.1

doc/fdrdf.1: doc/fdrdf.xml
	$(XSLTPROC) -o $@ $<

install:
	$(INSTALL) -d -- \
	    $(DESTDIR)$(bindir) \
	    $(DESTDIR)$(man1dir) \
	    $(DESTDIR)$(pkgperllibdir)/module \
	    $(DESTDIR)$(pkgperllibdir)/proto \
	    $(DESTDIR)$(pkgperllibdir)/xfmcache
	for pm in $(perl_module_files) ; do \
	    $(INSTALL) -m 0644 -- \
	        $(pmsrcdir)/$$pm $(DESTDIR)/$(perllibdir)/$$pm ; \
	done
	$(INSTALL) -m 0755 -- $(srcdir)/doc/fdrdf.1 \
	    $(DESTDIR)$(man1dir)/fdrdf.1
	$(INSTALL) -m 0755 -- $(srcdir)/src/fdrdf.pl \
	    $(DESTDIR)$(bindir)/fdrdf

### Makefile ends here
