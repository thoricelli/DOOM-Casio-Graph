# Configure with [fxsdk build-fx] or [fxsdk build-cg], which provide the
# toolchain file and module path of the fxSDK

cmake_minimum_required(VERSION 3.15)
project(DOOM)

include(GenerateG1A)
include(GenerateG3A)
include(GenerateHH2Bin)
include(Fxconv)
find_package(Gint 2.9 REQUIRED)

file(GLOB SOURCES "source/*.c" "source/*.cpp" "source/dbg/*.c")
# Shared assets, fx-9860G-only assets and fx-CG-50-only assets
set(ASSETS
  # ...
)
set(ASSETS_fx
  assets-fx/example.png
  # ...
)
set(ASSETS_cg
  assets-cg/example.png
  # ...
)

fxconv_declare_assets(${ASSETS} ${ASSETS_fx} ${ASSETS_cg} WITH_METADATA)

include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/lib/include)

add_executable(doom ${SOURCES} ${ASSETS} ${ASSETS_${FXSDK_PLATFORM}})
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker -Map=output.map -Wl,--print-memory-usage")
target_compile_options(doom PRIVATE -Wall -Wextra -Os -g -flto -w)
target_link_libraries(doom Gint::Gint)
target_link_libraries(doom ${CMAKE_SOURCE_DIR}/std/lib/libmylib.a)

if("${FXSDK_PLATFORM_LONG}" STREQUAL fx9860G)
  generate_g1a(TARGET doom OUTPUT "DOOM.g1a"
    NAME "DOOM" ICON assets-fx/icon.png)
elseif("${FXSDK_PLATFORM_LONG}" STREQUAL fxCG50)
  generate_g3a(TARGET doom OUTPUT "DOOM.g3a"
    NAME "DOOM" ICONS assets-cg/icon-uns.png assets-cg/icon-sel.png)
elseif("${FXSDK_PLATFORM_LONG}" STREQUAL fx9860G_G3A)
  generate_g3a(TARGET doom OUTPUT "DOOM-fx.g3a"
    NAME "DOOM-fx" ICONS assets-cg/icon-uns.png assets-cg/icon-sel.png)
elseif("${FXSDK_PLATFORM_LONG}" STREQUAL fxCP)
  generate_hh2_bin(TARGET doom OUTPUT "DOOM-hh2.bin")
endif()
