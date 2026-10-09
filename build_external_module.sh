#!/bin/bash
set -e

RDIR="$(pwd)"
KDIR="${RDIR}/out"

if [ -d "${RDIR}/toolchain/clang/host/linux-x86/clang-r383902/bin" ]; then
    CLANG_PATH="${RDIR}/toolchain/clang/host/linux-x86/clang-r383902/bin"
    PATH="${CLANG_PATH}:${PATH}"
    BUILD_CC="${CLANG_PATH}/clang"
    BUILD_LD="${CLANG_PATH}/ld.lld"
fi

if [ -d "${RDIR}/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin" ]; then
    GCC_PATH="${RDIR}/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin"
    PATH="${GCC_PATH}:${PATH}"
    BUILD_CROSS_COMPILE="${GCC_PATH}/aarch64-linux-android-"
else
    BUILD_CROSS_COMPILE="aarch64-linux-gnu-"
fi

mkdir -p "${RDIR}/build/modules"

echo "[+] Compiling memkernel driver module..."
make -C "${KDIR}" M="${RDIR}/memkernel" \
    ARCH=arm64 \
    CC="${BUILD_CC:-clang}" \
    LD="${BUILD_LD:-ld.lld}" \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE="${BUILD_CROSS_COMPILE}" \
    modules

cp "${RDIR}/memkernel/memkernel.ko" "${RDIR}/build/modules/memkernel.ko" 2>/dev/null || true

echo "[+] Compiling memkernel_enhanced driver module..."
make -C "${KDIR}" M="${RDIR}/memkernel_enhanced" \
    ARCH=arm64 \
    CC="${BUILD_CC:-clang}" \
    LD="${BUILD_LD:-ld.lld}" \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE="${BUILD_CROSS_COMPILE}" \
    modules

cp "${RDIR}/memkernel_enhanced/memkernel_enhanced.ko" "${RDIR}/build/modules/memkernel_enhanced.ko" 2>/dev/null || true

cat << 'EOF' > "${RDIR}/build/modules/SM-CPH2553_memkernel.sh"
#!/system/bin/sh
echo "[+] Loading memkernel module..."
insmod /data/local/tmp/memkernel.ko || true
echo "[+] Setting permissions..."
chmod 666 /dev/memkernel || true
echo "[+] memkernel initialized."
EOF

cat << 'EOF' > "${RDIR}/build/modules/SM-CPH2553_memkernel_enhanced.sh"
#!/system/bin/sh
echo "[+] Loading memkernel_enhanced module..."
insmod /data/local/tmp/memkernel_enhanced.ko || true
echo "[+] Setting permissions..."
chmod 666 /dev/memkernel_enhanced || true
echo "[+] memkernel_enhanced initialized."
EOF

chmod +x "${RDIR}/build/modules/SM-CPH2553_memkernel.sh" "${RDIR}/build/modules/SM-CPH2553_memkernel_enhanced.sh"

echo "[✔] External driver modules compiled successfully!"
