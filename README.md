# zf4

A forth interpreter written in zig

### Usage

```shell
# use repl
zf4
# interpret a file
zf4 <file>
# compile a file
zf4 compile <file>
# for now, you have to manually compile generated assembly code to get binary
clang -Wl,-e, -Wl,_start /tmp/forth.s
```
