RELEASE=2.0

RHCVER=3.1.5
RHCBRANCH=origin/STABLE31

PACKAGE=redhat-cluster-pve
PKGREL=2

DEBS=									\
	${PACKAGE}_${RHCVER}-${PKGREL}_amd64.deb			\
	${PACKAGE}-dev_${RHCVER}-${PKGREL}_amd64.deb

all: ${DEBS}
	echo ${DEBS}

.PHONY: cluster-${RHCVER}
${DEBS} cluster-${RHCVER}: cluster.git
	rm -rf cluster-${RHCVER}
	rsync -a --exclude .git --exclude .gitignore cluster.git/ cluster-${RHCVER}
	cp -a debian cluster-${RHCVER}/debian
	cd cluster-${RHCVER}; dpkg-buildpackage -rfakeroot -b -us -uc

cluster.git download:
	git clone git://git.fedorahosted.org/cluster.git cluster.git
	cd cluster.git; git checkout -b local ${RHCBRANCH}

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
	rm -rf *~ *.deb cluster-${RHCVER} ${PACKAGE}_* ${PACKAGE}-dev_*

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
