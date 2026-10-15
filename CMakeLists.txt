cmake_minimum_required(VERSION 3.20)
project(stm32_threadx_app C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# --- 1. Donanım Mimari Bayrakları (STM32F103 - Cortex-M3) ---
set(EXTRA_CPU_FLAGS -mcpu=cortex-m3 -mthumb -msoft-float)
add_compile_options(${EXTRA_CPU_FLAGS} -fdata-sections -ffunction-sections -Wall -Wextra)
add_link_options(${EXTRA_CPU_FLAGS} -Wl,--gc-sections -nostartfiles)

# --- 2. libopencm3 Derleme Entegrasyonu ---
set(OPENCM3_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib/libopencm3)
set(OPENCM3_LIB ${OPENCM3_DIR}/lib/libopencm3_stm32f1.a)

add_custom_command(
    OUTPUT ${OPENCM3_LIB}
    COMMAND make TARGETS=stm32/f1
    WORKING_DIRECTORY ${OPENCM3_DIR}
    COMMENT "Derleniyor: libopencm3 (stm32/f1)"
)
add_custom_target(libopencm3_build DEPENDS ${OPENCM3_LIB})

add_library(opencm3 STATIC IMPORTED GLOBAL)
set_target_properties(opencm3 PROPERTIES IMPORTED_LOCATION ${OPENCM3_LIB})
add_dependencies(opencm3 libopencm3_build)
target_include_directories(opencm3 INTERFACE ${OPENCM3_DIR}/include)
target_compile_definitions(opencm3 INTERFACE STM32F1)

# --- 3. Eclipse ThreadX Entegrasyonu ---
set(THREADX_ARCH "cortex_m3")
set(THREADX_TOOLCHAIN "gnu")
set(TX_USER_FILE "${CMAKE_CURRENT_SOURCE_DIR}/src/tx_user.h" CACHE STRING "User config")

add_subdirectory(lib/threadx)

# --- 4. Ana Uygulama Hedefi ---
add_executable(${PROJECT_NAME}.elf
    src/main.c
    src/tx_initialize_low_level.S
)

target_include_directories(${PROJECT_NAME}.elf PRIVATE src)

target_link_libraries(${PROJECT_NAME}.elf PRIVATE
    opencm3
    azrtos::threadx
)

# Linker Script Ayarı
set(LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/ld/stm32f103c8t6.ld)
target_link_options(${PROJECT_NAME}.elf PRIVATE
    -L${OPENCM3_DIR}/lib
    -T${LINKER_SCRIPT}
    -Wl,-Map=${PROJECT_NAME}.map
)

# --- 5. Binary (.bin / .hex) Çıktısı ve Boyut Raporu ---
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary ${PROJECT_NAME}.elf ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -O ihex ${PROJECT_NAME}.elf ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_SIZE} --format=berkeley ${PROJECT_NAME}.elf
    COMMENT "Binary dosyalar üretiliyor ve bellek kullanımı hesaplanıyor..."
)
