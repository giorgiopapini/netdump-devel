INCLUDEDIR = usr/include
DOCDIR = usr/share/doc/netdump-devel
PKGCONFIGDIR = usr/lib/pkgconfig


install: install_dirs copy_include copy_docs copy_pkgconfig

install_dirs:
	mkdir -p $(DESTDIR)/$(INCLUDEDIR)
	mkdir -p $(DESTDIR)/$(INCLUDEDIR)/netdump
	mkdir -p $(DESTDIR)/$(DOCDIR)
	mkdir -p $(DESTDIR)/$(PKGCONFIGDIR)

copy_include:
	cp -r include/* $(DESTDIR)/$(INCLUDEDIR)/netdump
	cp -r netdump.h $(DESTDIR)/$(INCLUDEDIR)/

copy_docs:
	cp -r doc/README $(DOCDIRDEST)/

copy_pkgconfig:
	cp -r pkgconfig/netdump-devel.pc $(DESTDIR)/$(PKGCONFIGDIR)

clean:
	rm -rf $(DESTDIR)/$(INCLUDEDIR)/netdump
	rm -rf $(DESTDIR)/$(INCLUDEDIR)/netdump.h
	rm -rf $(DESTDIR)/$(DOCDIR)
	rm -rf $(DESTDIR)/$(PKGCONFIGDIR)
