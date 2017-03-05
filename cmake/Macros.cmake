macro(GetFilesWithSourceGroups GLOB_TYPE VARIABLE RELATIVE_TO)
    file(${GLOB_TYPE} files ${ARGN})
    foreach(file ${files})
        file(RELATIVE_PATH relFile ${RELATIVE_TO} ${file})
        get_filename_component(folder ${relFile} PATH)
        string(REPLACE / \\ folder "${folder}")
        source_group("${folder}" FILES ${file})
    endforeach()
    list(APPEND ${VARIABLE} ${files})
endmacro()

function(SimpleCompileCheck VARIABLE DESCRIPTION SOURCE)
    if(MSVC)
        # Force warning as error to detect "noexcept" warning when exceptions are disabled:
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /WX")
    endif()
    string(MD5 hashInputs "${CMAKE_CXX_FLAGS}${SOURCE}")
    if(NOT DEFINED ${VARIABLE} OR NOT "${${VARIABLE}_HASH}" STREQUAL "${hashInputs}")
        file(WRITE ${CMAKE_BINARY_DIR}/CMakeTmp/CompileCheck.cpp "${SOURCE}\nint main() { return 0; };")
        try_compile(${VARIABLE} ${CMAKE_BINARY_DIR}/CMakeTmp ${CMAKE_BINARY_DIR}/CMakeTmp/CompileCheck.cpp OUTPUT_VARIABLE output)
        if(${VARIABLE})
            message("${DESCRIPTION} -- yes")
        else()
            message("${DESCRIPTION} -- no")
        endif()
        set(${VARIABLE} ${${VARIABLE}} CACHE INTERNAL "${DESCRIPTION}")
        set("${VARIABLE}_HASH" "${hashInputs}" CACHE INTERNAL "${DESCRIPTION} (hashed inputs)")
    endif()
endfunction()

macro(GetAbsoluteRelativeTo VARIABLE ROOT RELATIVE)
    if(IS_ABSOLUTE "${RELATIVE}")
        set(${VARIABLE} "${RELATIVE}")
    else()
        get_filename_component(${VARIABLE} "${ROOT}/${RELATIVE}" ABSOLUTE)
    endif()
endmacro()

macro(ConfigureFileIfChanged SRC_FILE DST_FILE SOURCE_FILES_VAR)    
    get_filename_component(fullSrcPath "${SRC_FILE}" ABSOLUTE)
    list(APPEND ${SOURCE_FILES_VAR} ${fullSrcPath} ${DST_FILE})
    source_group("config" FILES ${fullSrcPath} ${DST_FILE})
    configure_file("${fullSrcPath}" "${DST_FILE}.compare")
    file(READ "${DST_FILE}.compare" newContents)    
    file(TO_NATIVE_PATH "${fullSrcPath}" fullScrPathNative)
    file(TO_NATIVE_PATH "${CMAKE_CURRENT_LIST_FILE}" currentListFileNative)
    set(newContents
"//--------------------------------------------
// This file was autogenerated from: ${fullScrPathNative}
// while running: ${currentListFileNative}
// Do not edit!
//--------------------------------------------

${newContents}")
    file(REMOVE "${DST_FILE}.compare")
    if(EXISTS "${DST_FILE}")
        file(READ "${DST_FILE}" oldContents)
        if (NOT oldContents STREQUAL newContents)
            file(WRITE "${DST_FILE}" "${newContents}")
        endif()
    else()
        file(WRITE "${DST_FILE}" "${newContents}")
    endif()
endmacro()

macro(WriteFileIfDifferent CONTENTS DST_FILE SOURCE_FILES_VAR)
    list(APPEND ${SOURCE_FILES_VAR} ${DST_FILE})
    source_group("config" FILES ${SRC_FILE} ${DST_FILE})
    if(EXISTS "${DST_FILE}")
        file(READ "${DST_FILE}" oldContents)
        if(NOT oldContents STREQUAL CONTENTS)
            file(WRITE "${DST_FILE}" "${CONTENTS}")
        endif()
    else()
        file(WRITE "${DST_FILE}" "${CONTENTS}")
    endif()
endmacro()

macro(ApplyTurfBuildSettings)
    if(MSVC)
        set(CMAKE_EXE_LINKER_FLAGS "/ignore:4221 /debug")
        set(CMAKE_EXE_LINKER_FLAGS_DEBUG "/INCREMENTAL")
        set(CMAKE_EXE_LINKER_FLAGS_RELWITHASSERTS "/INCREMENTAL:NO")
        set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "/INCREMENTAL:NO")
        set(CMAKE_STATIC_LINKER_FLAGS "/ignore:4221")
        set(CMAKE_STATIC_LINKER_FLAGS_DEBUG "")
        set(CMAKE_STATIC_LINKER_FLAGS_RELWITHASSERTS "")
        set(CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO "")
        set(CMAKE_SHARED_LINKER_FLAGS "/ignore:4221 /debug")
        set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "/INCREMENTAL")
        set(CMAKE_SHARED_LINKER_FLAGS_RELWITHASSERTS "/INCREMENTAL:NO")
        set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "/INCREMENTAL:NO")
        set(CMAKE_C_FLAGS "/DWIN32 /D_WINDOWS /W3")
        set(CMAKE_C_FLAGS_DEBUG "/D_DEBUG /MTd /Zi /Od /Ob0 /RTC1 -DTURF_WITH_ASSERTS=1")
        set(CMAKE_C_FLAGS_RELWITHASSERTS "/DNDEBUG /MT /Zi /O2 /Ob1 -DTURF_WITH_ASSERTS=1")
        set(CMAKE_C_FLAGS_RELWITHDEBINFO "/DNDEBUG /MT /Zi /O2 /Ob1")
        set(CMAKE_CXX_FLAGS "/DWIN32 /D_WINDOWS /W3")
        set(CMAKE_CXX_FLAGS_DEBUG "/D_DEBUG /MTd /Zi /Od /Ob0 /RTC1 -DTURF_WITH_ASSERTS=1")
        set(CMAKE_CXX_FLAGS_RELWITHASSERTS "/DNDEBUG /MT /Zi /O2 /Ob1 -DTURF_WITH_ASSERTS=1")
        set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/DNDEBUG /MT /Zi /O2 /Ob1")
        if(TURF_WITH_EDIT_AND_CONTINUE)
            string(REPLACE "/Zi" "/ZI" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
            string(REPLACE "/Zi" "/ZI" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
            set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} /EDITANDCONTINUE /SAFESEH:NO")
            set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG} /EDITANDCONTINUE /SAFESEH:NO")
        endif()
        if(TURF_WITH_EXCEPTIONS)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc")
        else()
            add_definitions(-D_HAS_EXCEPTIONS=0)
        endif()
        if(NOT TURF_WITH_SECURE_COMPILER)
            add_definitions(-D_CRT_SECURE_NO_WARNINGS=1)
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /GS-")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /GS-")
        endif()
    else()
        set(CMAKE_C_FLAGS "-g -std=gnu99 -fno-stack-protector")
        if(DEFINED TURF_ENABLE_CPP11 AND NOT "${TURF_ENABLE_CPP11}")
            set(CMAKE_CXX_FLAGS "-g -fno-stack-protector")
        else()
            if(MINGW)
                set(CMAKE_CXX_FLAGS "-g -std=gnu++11 -fno-stack-protector")
            else()
                set(CMAKE_CXX_FLAGS "-g -std=c++11 -fno-stack-protector")
            endif()
        endif()
        if(NOT TURF_WITH_EXCEPTIONS)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions")
        endif()
        if(NOT CYGWIN)   # Don't specify -pthread on Cygwin
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
        endif()
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DTURF_WITH_ASSERTS=1")
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DTURF_WITH_ASSERTS=1")
        set(CMAKE_C_FLAGS_RELWITHASSERTS "${CMAKE_C_FLAGS_RELWITHDEBINFO} -DTURF_WITH_ASSERTS=1")
        set(CMAKE_CXX_FLAGS_RELWITHASSERTS "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -DTURF_WITH_ASSERTS=1")
        set(CMAKE_EXE_LINKER_FLAGS_RELWITHASSERTS "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}")
    endif()
    # Release is identical to RelWithDebInfo
    # Recommendation is to delete Release configuration and stick with RelWithDebInfo
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}")
    set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "${CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO}")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
endmacro()

macro(AddDLLCopyStep TARGET_NAME)
    foreach(DLL ${ARGN})
        add_custom_command(TARGET ${TARGET_NAME} POST_BUILD COMMAND
            ${CMAKE_COMMAND} -E copy_if_different ${DLL} $<TARGET_FILE_DIR:${TARGET_NAME}>)
    endforeach()
endmacro()
