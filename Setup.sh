#!/bin/bash
# Installer for SkybotV2

# Install Luvit
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
cp lit /usr/local/bin/lit
cp luvi /usr/local/bin/luvi
cp luvit /usr/local/bin/luvit

# Copy libsqlite3.so to the project directory
cp /usr/lib/libsqlite3.so.0 libsqlite3.so>/dev/null || :
cp /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 libsqlite3.so>/dev/null || :
# See if the file is actually there 
cp libsqlite3.so libsqlite3.so

# Generate the default config
cp config.lua.default config.lua
cp blacklist.lua.default blacklist.lua
cp userlist.lua.default userlist.lua