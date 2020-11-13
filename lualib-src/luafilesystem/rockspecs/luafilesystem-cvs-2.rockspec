package = "LuaFileSystem"

version = "cvs-2"

source = {
   url = "git://github.com/keplerproject/luafilesystem.git",
}

description = {
   summary = "File System Library for the Lua Programming Language",
   detailed = [[
      LuaFileSystem is a Lua library developed to complement the set of
      functions related to file systems offered by the standard Lua
      distribution. LuaFileSystem offers a portable way to access the
      underlying directory structure and file attributes.
   ]]
}

dependencies = {
   "lua >= 5.1"
}

build = {
   type = "module",
   modules = { lfs = "src/lfs.c" }
}
