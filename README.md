before this works, you'll have to `brew install libuv`

then

`swiftc -Ilib -I/usr/include src/spawn.swift`

if you run `./spawn` afterward, it should create a file named "hello"
