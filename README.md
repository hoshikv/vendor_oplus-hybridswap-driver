# OPLUS hybridswap_zram DLKM for peridot (SM8635 / Redmi Turbo 3)

ColorOS's hybridswap (zram + intelligent compressed-swap) is shipped on the
OnePlus **SM8635** (`vendor/oplus/kernel/mm/hybridswap_zram`) as loadable
DLKM modules. On the peridot ColorOS port those `.ko` from the OnePlus
vendor_dlkm fail to load against the Xiaomi GKI kernel (vermagic / KMI
mismatch). This repo contains the ported sources that are **built against the
exact peridot KMI** (`6.1.175-android14-11-ga3b9c44908dd-ab13320413`) as
loadable modules.

Source: `OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_sm8635`
branch `oneplus/sm8635_b_16.0.0_nord_5`, `vendor/oplus/kernel/mm/*` (GPL-2.0).

## Modules built

| Module | Source | Role |
|---|---|---|
| `crypto_zstdn.ko` | `hybridswap_zram/zstd/` | OPLUS zstd crypto acomp ("zstdn") |
| `oplus_bsp_lz4k.ko` | `hybridswap_zram/lz4k/` | OPLUS lz4k compressor ("lz4k") |
| `oplus_bsp_hybridswap_zram.ko` | `hybridswap_zram/` | zram block device + hybridswap (swapd/core) |

Note: `zstd/crypto_zstd.c` is ported for GKI — the osvelte kallsyms indirection
(`crypto_register/unregister_scomp`) is replaced with the direct GKI exports, and
`subsys_initcall` -> `module_init` (the module must self-register on load).

## Layout (flat)

```
hybridswap_zram/    # OPLUS hybridswap/zram driver tree (source of truth)
mm_osvelte/         # OPLUS osvelte (reserved for CONFIG_KCOMPRESSD/chp v2)
sa_common.h         # sched_assist header dep used by hybridmain.c
install.sh
```

The extra OPLUS `mm_osvelte` tree is kept for a later `CONFIG_KCOMPRESSD` /
hybridswapd_chp enabling; v1 compiles `hybridswap_zram` with `KCOMPRESSD` and
panel-event aggressiveness OFF to keep the KMI surface minimal.

## Building

Builds are hosted in **`hoshikv/peridot-kernel-build`** (`build.sh`, workflow
`kernel_display_touch_audio.yml`): it clones this repo into a flat
`hybridswap-driver` folder, stages the OPLUS `kernel/oplus_mm` include tree plus
the `kernel/oplus_cpu/sched/sched_assist/sa_common.h` dependency (symlink farm)
so `#include <../kernel/oplus_cpu/sched/sched_assist/sa_common.h>` and the zstd
`-I$(srctree)/mm/oplus_mm` paths resolve, and builds the modules against the
peridot KMI. There is no CI in this repository.

The build injects these module-local defines:
`CONFIG_HYBRIDSWAP`, `CONFIG_HYBRIDSWAP_SWAPD`, `CONFIG_HYBRIDSWAP_CORE` (and
CONFIG_CRYPTO_LZ4K / CONFIG_CRYPTO_ZSTDN go through their own Kbuild);
`CONFIG_KCOMPRESSD` and `CONFIG_QCOM_PANEL_EVENT_NOTIFIER` stay OFF in v1.

## Device notes

- The stock GKI `zram.ko` must be unloaded before this driver loads, so the
  OPLUS zram driver can claim the `zram` major + `/dev/zram0`:
  `rmmod zram` (or drop it from `modules.load`).
- A crypto acomp for the configured compressor must be present: stock GKI
  `crypto_zstd.ko`, or the `crypto_zstdn.ko` from this build (`zstdn`).
- Install: `install.sh --test` then `install.sh --persist`.

## License

GPL-2.0. Original sources (c) OPPO/OnePlus; ported for peridot.