# OS-specific variables
INCLUDEDIR = /usr/include
DOCDIR = /usr/share/doc
PKGCONFIGDIR = /usr/lib


show-config:
	@echo "Configuration:"
	@echo "		INCLUDEDIR   = ${INCLUDEDIR}"
	@echo "		DOCDIR       = ${DOCDIR}"
	@echo "		PKGCONFIGDIR = ${PKGCONFIGDIR}"

install: install_dirs copy_include copy_docs copy_pkgconfig

install_dirs:
	@test -d ${INCLUDEDIR} || (echo "Error: INCLUDEDIR '${INCLUDEDIR}' does not exist. Set it correctly."; exit 1)
	mkdir -p ${DESTDIR}${INCLUDEDIR}/netdump
	@test -d ${DOCDIR} || (echo "Error: DOCDIR '${DOCDIR}' does not exist. Set it correctly."; exit 1)
	@test -d ${PKGCONFIGDIR} || (echo "Error: PKGCONFIGDIR '${PKGCONFIGDIR}' does not exist. Set it correctly"; exit 1)

copy_include:
	cp -r include/* ${DESTDIR}${INCLUDEDIR}/netdump
	cp -r netdump.h ${DESTDIR}${INCLUDEDIR}/

copy_docs:
	cp -r doc/README ${DOCDIR}/netdump-devel

copy_pkgconfig:
	cp -r pkgconfig/netdump-devel.pc ${DESTDIR}${PKGCONFIGDIR}/pkgconfig

clean:
	rm -rf ${DESTDIR}${INCLUDEDIR}/netdump
	rm -rf ${DESTDIR}${INCLUDEDIR}/netdump.h
	rm -rf ${DESTDIR}${DOCDIR}/netdump-devel
	rm -rf ${DESTDIR}${PKGCONFIGDIR}/pkgconfig
