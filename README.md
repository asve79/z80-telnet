# z80-telnet

Telnet client for z80 (developed and tested on ts-conf machine emulator)

Client use RS232 (#F8EF+REGS) connection & socket server on host machine.

* windows library: https://github.com/asve79/xasconv
* socket library: https://github.com/HackerVBI/ZiFi/tree/master/_rs232
* socket server: https://github.com/HackerVBI/ZiFi/tree/master/_rs232/ic_emul_0.2
* Emulator: https://github.com/tslabs/zx-evo/raw/master/pentevo/unreal/Unreal/bin/unreal.7z or https://github.com/asve79/Xpeccy

build:
git clone git@github.com:asve79/z80-telnet.git

cd xasconv
./get_depencies.sh
./_make.sh

Demo:
![Demo](https://github.com/asve79/z80-telnet/blob/master/demo/z80-telnet-demo3.gif)
