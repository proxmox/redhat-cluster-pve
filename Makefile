RELEASE=2.2

RHCVER=3.1.93
RHCBRANCH=STABLE32

RHCDIR=cluster-${RHCVER}
RHCSRC=${RHCDIR}.tar.gz

PACKAGE=redhat-cluster-pve
PKGREL=2

DEBS=									\
	${PACKAGE}_${RHCVER}-${PKGREL}_amd64.deb			\
	${PACKAGE}-dev_${RHCVER}-${PKGREL}_amd64.deb

all: ${DEBS}
	echo ${DEBS}

${DEBS}: ${RHCSRC}
	rm -rf ${RHCDIR}
	tar xf ${RHCSRC}
	cp -a debian ${RHCDIR}/debian
	cat ${RHCDIR}/doc/COPYRIGHT >>${RHCDIR}/debian/copyright
	cd ${RHCDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEBS}

${RHCSRC} download:
	rm -rf ${RHCDIR} cluster.git
	git clone git://git.fedorahosted.org/cluster.git -b ${RHCBRANCH} cluster.git
	rsync -a --exclude .git --exclude .gitignore cluster.git/ ${RHCDIR}
	tar czf ${RHCSRC}.tmp ${RHCDIR}
	rm -rf ${RHCDIR} 
	mv ${RHCSRC}.tmp ${RHCSRC}

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean
	rm -rf cluster.git

clean:
	rm -rf *~ *.deb ${RHCDIR} ${PACKAGE}_* ${PACKAGE}-dev_*

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
