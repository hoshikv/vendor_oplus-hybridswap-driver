#!/usr/bin/env bash
# Ship the OPLUS hybridswap DLKM modules onto the device.
#   --test     just verify vermagic + load order (insmod dry)
#   --persist  copy .ko into /vendor_dlkm/lib/modules/<kver>/ + modules.load
set -euo pipefail

KVER="$(uname -r)"
DIR="${1:-/data/local/tmp/hybridswap}"
DEST="/vendor_dlkm/lib/modules/$KVER"

MODEL="$(getprop ro.product.model 2>/dev/null || echo unknown)"
KERNEL_LOCAL="$(cat /proc/sys/kernel/osrelease 2>/dev/null || true)"
echo "device: $MODEL kernel: $KERNEL_LOCAL"

case "$1" in
--persist)
  echo "[*] will install to $DEST"
  mount -o rw,remount /vendor_dlkm || true
  ;;
esac

verify() {
  local m="$1"
  [ -f "$m" ] || { echo "missing: $m"; return 1; }
  local v; v="$(strings "$m" 2>/dev/null | grep -m1 'vermagic=' || true)"
  echo "  $v"
}

echo "[*] verify module vermagic vs booted kernel"
echo "  booted: $KERNEL_LOCAL"
for b in crypto_zstdn oplus_bsp_lz4k oplus_bsp_hybridswap_zram; do
  verify "$DIR/$b.ko"
done

echo "[*] NOTE: stock zram.ko must be unloaded first (rmmod zram) so the OPLUS \
zram driver can claim the 'zram' major+device; it will be owned by \
oplus_bsp_hybridswap_zram instead."

if [ "$1" = "--persist" ]; then
  mkdir -p "$DEST"
  for b in crypto_zstdn oplus_bsp_lz4k oplus_bsp_hybridswap_zram; do
    m="$DIR/$b.ko"
    [ -f "$m" ] || continue
    cp "$m" "$DEST/$b.ko"
  done
  rm -f "$DEST/zram.ko" 2>/dev/null || true
  : > "$DEST/modules.load"
  for b in crypto_zstdn oplus_bsp_lz4k oplus_bsp_hybridswap_zram; do
    [ -f "$DEST/$b.ko" ] && echo "$b.ko" >> "$DEST/modules.load"
  done
  echo "[*] installed. reboot."
else
  echo "[*] dry run done. use --persist to install."
fi