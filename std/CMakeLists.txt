cmake_minimum_required(VERSION 3.10)
project(MyLibrary)

# Set toolchain (if needed for cross-compilation)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER sh-elf-gcc)

# Set include directory
include_directories(${CMAKE_SOURCE_DIR}/include)

# Add the library (choose STATIC for .a)
add_library(mylib STATIC src/mylib.c)

# Set output directory for static library
set_target_properties(mylib PROPERTIES 
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
)

# Install rules (optional)
install(TARGETS mylib DESTINATION lib)
install(FILES include/mylib.h DESTINATION include)
