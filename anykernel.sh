### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
### AnyKernel setup
# global properties
properties() { '
kernel.string=by belowzeroiq @ github
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot shell variables
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

# Kernel version selection function
choose_kernel_version() {
  ui_print " "
  ui_print "  VOL + : Auto (use detected $DETECTED_VERSION)"
  ui_print "Waiting for input... "
  ui_print " "
  
  while true; do
    input=$(getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN)")
    case "$input" in
      *KEY_VOLUMEUP*)
        return 1
        ;;
      *KEY_VOLUMEDOWN*)
        return 2
        ;;
    esac
    sleep 0.1
  done
}

# KSU selection function
choose_ksu_variant() {
  ui_print " "
  ui_print "========================================="
  ui_print "  KSU Variant Selection"
  ui_print "========================================="
  ui_print " "
  ui_print "  VOL + : non-KSU"
  ui_print "  VOL - : KSU"
  ui_print " "
  ui_print "Waiting for input... "
  ui_print " "
  
  while true; do
    input=$(getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN)")
    case "$input" in
      *KEY_VOLUMEUP*)
        return 1
        ;;
      *KEY_VOLUMEDOWN*)
        return 2
        ;;
    esac
    sleep 0.1
  done
}

# Detect current kernel version
ui_print " "
ui_print "========================================="
ui_print "  Detecting Current Kernel Version"
ui_print "========================================="
ui_print " "

CURRENT_KERNEL=$(uname -r)
ui_print "Current kernel: $CURRENT_KERNEL"
ui_print " "

# Extract kernel version (5.10 or 5.15)
if echo "$CURRENT_KERNEL" | grep -q "5.10"; then
  DETECTED_VERSION="5.10"
  ui_print "Detected: Kernel 5.10"
elif echo "$CURRENT_KERNEL" | grep -q "5.15"; then
  DETECTED_VERSION="5.15"
  ui_print "Detected: Kernel 5.15"
else
  DETECTED_VERSION="unknown"
  ui_print "Warning: Could not detect kernel version"
fi

ui_print " "

# Ask user if they want to use detected version or choose manually
if [ "$DETECTED_VERSION" != "unknown" ]; then
  ui_print "========================================="
  ui_print "  Installation Mode"
  ui_print "========================================="
  ui_print " "
  ui_print "  VOL + : Auto (use detected $DETECTED_VERSION)"
  ui_print "  VOL - : Manual selection"
  ui_print " "
  ui_print "Waiting for input... "
  ui_print " "
  
  while true; do
    input=$(getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN)")
    case "$input" in
      *KEY_VOLUMEUP*)
        AUTO_MODE=1
        break
        ;;
      *KEY_VOLUMEDOWN*)
        AUTO_MODE=0
        break
        ;;
    esac
    sleep 0.1
  done
else
  AUTO_MODE=0
fi

ui_print " "

# Step 1: Choose kernel version
if [ "$AUTO_MODE" = "1" ]; then
  ui_print "Using auto-detected version: $DETECTED_VERSION"
  KERNEL_PREFIX="$DETECTED_VERSION"
else
  choose_kernel_version
  kernel_version=$?
  
  case $kernel_version in
    1)
      ui_print "Selected: Kernel 5.10"
      KERNEL_PREFIX="5.10"
      ;;
    2)
      ui_print "Selected: Kernel 5.15"
      KERNEL_PREFIX="5.15"
      ;;
  esac
fi

# Set device names based on kernel version
case $KERNEL_PREFIX in
  "5.10")
    device.name1=garnet
    ;;
  "5.15")
    device.name1=topaz
    device.name2=tapas
    device.name3=sapphiren
    device.name4=sapphire
    device.name5=xun
    device.name6=creek
    ;;
esac

ui_print " "

# Step 2: Choose KSU variant
if [ -f "$AKHOME/Image.${KERNEL_PREFIX}.ksu" ] && [ -f "$AKHOME/Image.${KERNEL_PREFIX}.noksu" ]; then
  choose_ksu_variant
  case $? in
    1)
      ui_print "Selected: non-KSU Kernel"
      mv -f "$AKHOME/Image.${KERNEL_PREFIX}.noksu" "$AKHOME/Image"
      ;;
    2)
      ui_print "Selected: KSU Kernel"
      mv -f "$AKHOME/Image.${KERNEL_PREFIX}.ksu" "$AKHOME/Image"
      ;;
  esac
elif [ -f "$AKHOME/Image.${KERNEL_PREFIX}" ]; then
  ui_print "Single image kernel found, flashing it"
  mv -f "$AKHOME/Image.${KERNEL_PREFIX}" "$AKHOME/Image"
elif [ -f "$AKHOME/Image.${KERNEL_PREFIX}.ksu" ]; then
  ui_print "Only KernelSU version found, flashing it"
  mv -f "$AKHOME/Image.${KERNEL_PREFIX}.ksu" "$AKHOME/Image"
elif [ -f "$AKHOME/Image.${KERNEL_PREFIX}.noksu" ]; then
  ui_print "Only Standard version found, flashing it"
  mv -f "$AKHOME/Image.${KERNEL_PREFIX}.noksu" "$AKHOME/Image"
else
  ui_print " "
  ui_print "ERROR: No kernel image found for version ${KERNEL_PREFIX}!"
  ui_print "Aborting installation..."
  exit 1
fi

ui_print " "
ui_print "Installing ${KERNEL_PREFIX} kernel..."
ui_print " "

# boot install
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" -o -L "/dev/block/by-name/init_boot_a" ]; then
    split_boot # for devices with init_boot ramdisk
    flash_boot # for devices with init_boot ramdisk
else
    dump_boot # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
    write_boot # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
fi

## end boot install
