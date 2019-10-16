#!/usr/bin/env fish
while true
    echo lua/terminal.lua | entr -cd ldoc -f markdown lua
end
