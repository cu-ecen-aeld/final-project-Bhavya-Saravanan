SUMMARY = "Add version file to system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

do_install() {
    install -d ${D}${sysconfdir}
    echo "RELEASE-2 - Updated via Mender OTA on $(date)" > ${D}${sysconfdir}/build-version
}

FILES:${PN} = "${sysconfdir}/build-version"
