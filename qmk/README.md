[tutorial](https://docs.qmk.fm/newbs) 

## Create a keymap

<!-- QMK_HOME=$(qmk config -ro user.qmk_home | sed -E 's/[^=]+=(.*)$/\1/') -->
```bash
QMK_HOME="${PROJECTS:-$HOME/code}"

QMK_KEYBOARD_NAME=keychron/k6_pro/iso/rgb
QMK_KEYMAP_NAME=louis-brunet

qmk new-keymap -kb "$QMK_KEYBOARD_NAME" -km "$QMK_KEYMAP_NAME"
nvim "${QMK_HOME}/qmk_firmware/keyboards/${QMK_KEYBOARD_NAME}/keymaps/${QMK_KEYMAP_NAME}/"
```


<!-- ## Set default keyboard and keymap -->
<!---->
<!-- ```bash -->
<!-- qmk  -->
<!-- ``` -->


## Build firmware

```bash
qmk compile [-kb <keyboard>] [-km <keymap>]
```

## Flash firmware
### Windows

Need [QMK Toolbox](https://docs.qmk.fm/newbs_flashing#flashing-your-keyboard-with-qmk-toolbox) for Windows <11.

### Command line - Linux (& Mac ?) only

```bash
qmk flash [-kb <keyboard>] [-km <keymap>]
```
