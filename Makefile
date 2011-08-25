RELEASE=2.0

RHCVER=3.1.6
RHCBRANCH=origin/STABLE31

RHCDIR=cluster-${RHCVER}
RHCSRC=${RHCDIR}.tar.gz

PACKAGE=redhat-cluster-pve
PKGREL=1

DEBS=									\
	${PACKAGE}_${RHCVER}-${PKGREL}_amd64.deb			\
	${PACKAGE}-dev_${RHCVER}-${PKGREL}_amd64.deb

all: ${DEBS}
	echo ${DEBS}

${DEBS}: ${RHCSRC}
	rm -rf ${RHCDIR}
	tar xf ${RHCSRC}
	cp -a debian ${RHCDIR}/debian
	cd ${RHCDIR}; dpkg-buildpackage -rfakeroot -b -us -uc

${RHCSRC} download:
	rm -rf ${RHCDIR} cluster.git
	git clone git://git.fedorahosted.org/cluster.git cluster.git
	cd cluster.git; git checkout -b local ${RHCBRANCH}
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
