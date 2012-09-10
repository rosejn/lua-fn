CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)
FIND_PACKAGE(Torch REQUIRED)

SET(src)
SET(luasrc fn/init.lua fn/seq.lua)

ADD_TORCH_PACKAGE(fn "${src}" "${luasrc}" "Functional programming tools for Lua.")

