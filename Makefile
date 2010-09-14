### Makefile  -*- Makefile -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

DESTDIR  =
prefix   = /usr/local
bindir   = $(prefix)/bin
mandir   = $(prefix)/share/man
man1dir  = $(mandir)/man1
perllibdir = $(prefix)/lib/site_perl
pkgperllibdir = $(perllibdir)/fdrdf

GZIP     = gzip -9v
INSTALL  = install
MKDIR_P  = mkdir -p
XSLTPROC = xsltproc

srcdir   = .
pmsrcdir = $(srcdir)/lib/perl
perl_module_files = \
	lib/perl/fdrdf/module/file.pm \
	lib/perl/fdrdf/module/gdal.pm \
	lib/perl/fdrdf/module/gdalinfo.pm \
	lib/perl/fdrdf/module/grib.pm \
	lib/perl/fdrdf/module/mark.pm \
	lib/perl/fdrdf/module/sha1.pm \
	lib/perl/fdrdf/module/stat.pm \
	lib/perl/fdrdf/proto.pm \
	lib/perl/fdrdf/proto/chunks.pm \
	lib/perl/fdrdf/proto/io.pm \
	lib/perl/fdrdf/util.pm \
	lib/perl/fdrdf/xfmcache.pm \
	lib/perl/fdrdf/xfmcache/proto.pm

perl_modules_no_lib_perl = \
	$(perl_module_files:lib/perl/%=%)

PACKAGE = fdrdf
VERSION = 0.2

distdir = $(PACKAGE)-$(VERSION)
DISTFILES = \
	$(DIST_COMMON) $(DIST_SOURCES) $(EXTRA_DIST)
DIST_COMMON = \
	AUTHORS COPYING INSTALL NEWS README
DIST_SOURCES = \
	$(perl_module_files) \
	doc/fdrdf.xml examples/mark.cf.rdf src/fdrdf.pl
EXTRA_DIST = \
	COPYING.FDL Makefile \
	doc/fdrdf.1

all:
	## There isn't much to be done for `all'
	## Use `$ make install' to install FDRDF
	true

.PHONY: dist
dist: dist-gzip

doc: doc/fdrdf.1

doc/fdrdf.1: doc/fdrdf.xml
	$(XSLTPROC) -o $@ $<

doc/fdrdf.1: doc/mark.cf.rdf.cdata
doc/%.cf.rdf.cdata: examples/%.cf.rdf
	echo "<![CDATA[$$(cat -- '$<')]]>" > $@

install:
	$(INSTALL) -d -- \
	    $(DESTDIR)$(bindir) \
	    $(DESTDIR)$(man1dir) \
	    $(DESTDIR)$(pkgperllibdir)/module \
	    $(DESTDIR)$(pkgperllibdir)/proto \
	    $(DESTDIR)$(pkgperllibdir)/xfmcache
	for pm in $(perl_modules_no_lib_perl) ; do \
	    $(INSTALL) -m 0644 -- \
	        $(pmsrcdir)/$$pm $(DESTDIR)/$(perllibdir)/$$pm ; \
	done
	$(INSTALL) -m 0755 -- $(srcdir)/doc/fdrdf.1 \
	    $(DESTDIR)$(man1dir)/fdrdf.1
	$(INSTALL) -m 0755 -- $(srcdir)/src/fdrdf.pl \
	    $(DESTDIR)$(bindir)/fdrdf

.PHONY: distdir
distdir: $(DISTFILES)
	test -d "$(distdir)" || mkdir -- "$(distdir)"
	for f in $(DISTFILES) ; do \
	    d="$(distdir)/$$(dirname "$$f")" \
	        && (test -d "$$d" || $(MKDIR_P) -- "$$d") \
	        && cp -p -- "$(srcdir)/$$f" "$$d" ; \
	done

.PHONY: dist-gzip
dist-gzip: distdir
	tar c $(distdir) | $(GZIP) > $(distdir).tar.gz

### Makefile ends here
