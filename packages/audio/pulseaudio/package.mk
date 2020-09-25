# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-2018 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="pulseaudio"
PKG_VERSION="12.2"
PKG_SHA256="809668ffc296043779c984f53461c2b3987a45b7a25eb2f0a1d11d9f23ba4055"
PKG_LICENSE="GPL"
PKG_SITE="http://pulseaudio.org/"
PKG_URL="http://www.freedesktop.org/software/pulseaudio/releases/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain alsa-lib dbus libcap libsndfile libtool openssl soxr systemd glib:host"
PKG_LONGDESC="PulseAudio is a sound system for POSIX OSes, meaning that it is a proxy for your sound applications."
PKG_BUILD_FLAGS="+pic -lto"

 PKG_PULSEAUDIO_BLUETOOTH="--disable-bluez5"
 PKG_PULSEAUDIO_AVAHI="--disable-avahi"

# PulseAudio fails to build on aarch64 when NEON is enabled, so don't enable NEON for aarch64 until upstream supports it
if [ "$TARGET_ARCH" = "arm" ] && target_has_feature neon; then
  PKG_PULSEAUDIO_NEON="--enable-neon-opt"
else
  PKG_PULSEAUDIO_NEON="--disable-neon-opt"
fi

PKG_CONFIGURE_OPTS_TARGET="--disable-silent-rules \
                           --disable-nls \
                           --enable-largefile \
                           --disable-rpath \
                           $PKG_PULSEAUDIO_NEON \
                           --disable-x11 \
                           --disable-tests \
                           --disable-samplerate \
                           --disable-oss-output \
                           --disable-oss-wrapper \
                           --disable-coreaudio-output \
                           --enable-alsa \
                           --disable-esound \
                           --disable-solaris \
                           --disable-waveout \
                           --enable-glib2 \
                           --disable-gtk3 \
                           --disable-gconf \
                           $PKG_PULSEAUDIO_AVAHI \
                           --disable-jack \
                           --disable-asyncns \
                           --disable-tcpwrap \
                           --disable-lirc \
                           --enable-dbus \
                           --disable-bluez4 \
                           $PKG_PULSEAUDIO_BLUETOOTH \
                           --disable-bluez5-ofono-headset \
                           --disable-bluez5-native-headset \
                           --enable-udev \
                           --with-udev-rules-dir=/usr/lib/udev/rules.d \
                           --disable-hal-compat \
                           --enable-ipv6 \
                           --enable-openssl \
                           --disable-orc \
                           --disable-manpages \
                           --disable-per-user-esound-socket \
                           --disable-default-build-tests \
                           --disable-legacy-database-entry-format \
                           --with-system-user=root \
                           --with-system-group=root \
                           --with-access-group=root \
                           --without-caps \
                           --without-fftw \
                           --without-speex \
                           --with-soxr \
                           --with-module-dir=/usr/lib/pulse
                           CPPFLAGS=-I${SYSROOT_PREFIX}/usr/include"

pre_configure_target() {
  export CFLAGS="$CFLAGS -fopenmp"
  sed -e 's|; remixing-use-all-sink-channels = yes|; remixing-use-all-sink-channels = no|' \
      -i $PKG_BUILD/src/daemon/daemon.conf.in
}

post_makeinstall_target() {
  rm -rf $INSTALL/usr/bin/esdcompat
  rm -rf $INSTALL/usr/include
  rm -rf $INSTALL/usr/lib/cmake
  rm -rf $INSTALL/usr/lib/pkgconfig
  rm -rf $INSTALL/usr/lib/systemd
  rm -rf $INSTALL/usr/share/vala
  rm -rf $INSTALL/usr/share/zsh
  rm -rf $INSTALL/usr/share/bash-completion

  cp $PKG_DIR/config/system.pa $INSTALL/etc/pulse/
  cp $PKG_DIR/config/pulseaudio-system.conf $INSTALL/etc/dbus-1/system.d/

  mkdir -p $INSTALL/usr/config
    cp -PR $PKG_DIR/config/pulse-daemon.conf.d $INSTALL/usr/config

  ln -sf /storage/.config/pulse-daemon.conf.d $INSTALL/etc/pulse/daemon.conf.d

	sed -e 's|#load-module module-alsa-sink|load-module module-alsa-sink device=dmixer|' -i $INSTALL/etc/pulse/default.pa
	sed -e 's|load-module module-suspend-on-idle|#load-module module-suspend-on-idle|' -i $INSTALL/etc/pulse/default.pa
	sed -e 's|load-module module-udev-detect|#load-module module-udev-detect|' -i $INSTALL/etc/pulse/default.pa
	sed -e 's|load-module module-detect|#load-module module-detect|' -i $INSTALL/etc/pulse/default.pa
	mv $INSTALL/etc/pulse/default.pa $INSTALL/usr/config
	ln -sf /storage/.config/default.pa $INSTALL/etc/pulse/default.pa
}

post_install() {
  enable_service pulseaudio.service
}
