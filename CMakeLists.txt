cmake_minimum_required(VERSION 3.1)
include( ExternalProject )

set(CMAKE_VERBOSE_MAKEFILE OFF)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

set(RRI_VERSION_MAJOR "1")
set(RRI_VERSION_MINOR "0")
set(RRI_VERSION_PATCH "7")
set(RRI_VERSION "${RRI_VERSION_MAJOR}.${RRI_VERSION_MINOR}.${RRI_VERSION_PATCH}")

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set (CMAKE_CXX_STANDARD 11)

# use, i.e. don't skip the full RPATH for the build tree
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)

# when building, don't use the install RPATH already
# (but later on when installing)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE) 

SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")

# add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# the RPATH to be used when installing, but only if it's not a system directory
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
ENDIF("${isSystemDir}" STREQUAL "-1")

ExternalProject_Add(lpaggreg
  DOWNLOAD_COMMAND ""
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/external/lpaggreg"
)
ADD_SUBDIRECTORY(src)

file(GLOB SCRIPTS ${CMAKE_SOURCE_DIR}/scripts/*)
install(PROGRAMS ${SCRIPTS} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/samples DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY ${CMAKE_SOURCE_DIR}/cfg DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY ${CMAKE_BINARY_DIR}/lib DESTINATION ${CMAKE_INSTALL_PREFIX})
add_custom_target(installR  R --slave --vanilla < ${CMAKE_SOURCE_DIR}/scripts/rri-install.R)
add_custom_target(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_MODULE_PATH}/uninstall.cmake")
