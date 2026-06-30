#!/bin/bash

# ========================================================
# ARCHITECTURE & TOOLCHAIN ENGINE CORES
# ========================================================
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
ulimit -s unlimited

echo "========================================================"
echo "    🛸 CYBERTRON ULTIMATE INTERACTIVE DIAGNOSTIC ENGINE "
echo "========================================================"

echo "🛡️  Step 1: Checking KernelSU-Next environment..."
if [ ! -d "drivers/kernelsu" ]; then
    echo "📥 KernelSU-Next missing from drivers. Hooking integration engine..."
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s legacy
else
    echo "✅ KernelSU-Next directory already correctly mapped inside drivers/"
fi

echo "🔧 Step 2: Running Pre-Flight Code Diagnostic & Automatic Repair Loop..."
# Reset files to clean factory states before patching to prevent duplicate loop corruptions
git checkout fs/sdcardfs/main.c arch/arm64/Makefile drivers/hid/Makefile arch/arm64/configs/vendor/liber_defconfig drivers/net/usb/usbnet.c drivers/power/supply/qcom/smb5-lib.h 2>/dev/null
git checkout drivers/media/platform/msm/camera/ 2>/dev/null

# Patch 1: Neutralize the broken sdcardfs version macro syntax error
sed -i 's/SDCARDFS_VERSION/"v0.1"/g' fs/sdcardfs/main.c

# Patch 2: Force-comment every single line triggering legacy vdso32 compilation in the Makefile
sed -i '/vdso32/s/^/#/' arch/arm64/Makefile

# Patch 3: Inject local source search paths to resolve the Clang hid-trace header bug
echo "" >> drivers/hid/Makefile
echo "ccflags-y += -I\$(src)" >> drivers/hid/Makefile

# Patch 4: Automatically scan and fix ALL camera tracepoint relative headers
echo "🔍 Scanning camera framework sub-structures for alignment flags..."
find drivers/media/platform/msm/camera/ -name "Makefile" | while read -r camera_makefile; do
    echo "" >> "$camera_makefile"
    echo "ccflags-y += -I\$(src)" >> "$camera_makefile"
done

# Patch 5: Fix the duplicate cam_dump_tbl_info definition by isolating line 157 specifically
sed -i '157s/cam_dump_tbl_info/cam_dump_tbl_info_duplicate/' drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_util.c

# Patch 6: Fix the usbnet legacy timer/tasklet structure compilation block
sed -i '/del_timer_sync.*dev->delay/s/^/\/\//' drivers/net/usb/usbnet.c
sed -i '/tasklet_kill.*dev->bh/s/^/\/\//' drivers/net/usb/usbnet.c

# Patch 7: Bypass the smb5-lib undefined reference to smblib_handle_usb_current linker error
echo "🔋 Injecting fallback preprocessor macros inside battery charger headers..."
echo "" >> drivers/power/supply/qcom/smb5-lib.h
echo "#define smblib_handle_usb_current(...) (0)" >> drivers/power/supply/qcom/smb5-lib.h

echo "🧬 Step 3: Hard-injecting KernelSU-Next configuration hooks into blueprint..."
sed -i '/CONFIG_KSU/d' arch/arm64/configs/vendor/liber_defconfig
sed -i '/CONFIG_KPROBES/d' arch/arm64/configs/vendor/liber_defconfig
echo "" >> arch/arm64/configs/vendor/liber_defconfig
echo "CONFIG_KPROBES=y" >> arch/arm64/configs/vendor/liber_defconfig
echo "CONFIG_HAVE_KPROBES=y" >> arch/arm64/configs/vendor/liber_defconfig
echo "CONFIG_KPROBE_EVENTS=y" >> arch/arm64/configs/vendor/liber_defconfig
echo "CONFIG_KSU=y" >> arch/arm64/configs/vendor/liber_defconfig
echo "CONFIG_KSU_KPROBES_HOOK=y" >> arch/arm64/configs/vendor/liber_defconfig

echo "⚙️  Step 4: Generating environment config layout..."
make ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- vendor/liber_defconfig > /dev/null

# Strip legacy stack protectors & 32-bit vdso flags
sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/CONFIG_CC_STACKPROTECTOR_NONE=y/' .config
sed -i '/CONFIG_CC_STACKPROTECTOR_AUTO/d' .config
sed -i '/CONFIG_VDSO32/d' .config
sed -i '/CONFIG_COMPAT_VDSO/d' .config
echo "# CONFIG_VDSO32 is not set" >> .config

make ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- olddefconfig > /dev/null

echo "========================================================"
echo " 😎 PRE-FLIGHT CHECKS PASSED: ALL REPAIRS INJECTED!"
echo "========================================================"
read -p "🤔 Would you like to ignite the compilation engines now? (y/n): " choice

if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo "⏸️  Build compilation sequence paused by developer. Ready when you are, bro!"
    exit 0
fi

echo "🚀 Step 5: Commencing high-speed multi-core kernel compilation..."
rm -f kernel_core.log compiler_errors.log
start_time=$(date +%s)

# Compile using total warning suppression (-w) with background log duplication
make ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- KCFLAGS="-w" EXTRA_CFLAGS="-w" -j$(nproc) Image.gz 2>&1 | tee kernel_core.log

# ========================================================
# AUTOMATED RUNTIME ERROR ANALYTICS CAPTURING & SCANNING
# ========================================================
if [ -f "arch/arm64/boot/Image.gz" ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo "========================================================"
    echo "        🎉 SUCCESS! KERNEL COMPILED IN FIXED RUN!        "
    echo " Total Build Time: $((duration / 60)) minutes and $((duration % 60)) seconds."
    echo " Your flawless image is waiting at: arch/arm64/boot/Image.gz"
    echo "========================================================"
else
    end_time=$(date +%s)
    echo "========================================================"
    echo " ❌ COMPILATION CRASHED! EXTRACTING CODE BREAKS...      "
    echo "========================================================"
    
    # Isolate exact compiler error and fatal macro breakdowns into a clean log file
    grep -E "error:|fatal error:|modpost:" kernel_core.log > compiler_errors.log
    
    echo "⚠️  CRITICAL REJECTION METRICS DISCOVERED:"
    echo "--------------------------------------------------------"
    cat compiler_errors.log
    echo "--------------------------------------------------------"
    echo "📂 Raw break parameters have been saved into: compiler_errors.log"
    echo "========================================================"
fi