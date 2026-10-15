{
  description = "Minimalist ThreadX + libopencm3 Build & Lint Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin" # M4 MacBook Air (macOS)
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          # clang-tidy'nin arm-none-eabi standart kütüphanelerini (<stdint.h> vb.)
          # hem macOS hem Linux'ta hatasız bulması için sarmalayıcı script:
          lintScript = pkgs.writeShellScriptBin "project-lint" ''
            set -e
            if [ ! -f build/compile_commands.json ]; then
              echo "Önce 'project-configure' veya CMake çalıştırın!"
              exit 1
            fi
            echo ">>> [1/2] Running clang-tidy..."
            ${pkgs.llvmPackages.clang-tools}/bin/clang-tidy \
              -p build \
              --extra-arg=--target=arm-none-eabi \
              --extra-arg=--sysroot=${pkgs.gcc-arm-embedded}/arm-none-eabi \
              src/*.c

            echo ">>> [2/2] Running cppcheck..."
            ${pkgs.cppcheck}/bin/cppcheck \
              --project=build/compile_commands.json \
              --enable=warning,style,performance,portability \
              --suppress=*:*lib/* \
              --inline-suppr \
              --error-exitcode=1
          '';

          configureScript = pkgs.writeShellScriptBin "project-configure" ''
            cmake -B build -G Ninja \
              -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake \
              -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
          '';
        in
        {
          default = pkgs.mkShellNoCC {
            name = "stm32-tx-env";

            packages = with pkgs; [
              # Cross-compilation & Build
              gcc-arm-embedded
              cmake
              ninja
              gnumake
              python3 # libopencm3 IRQ header üretimi için zorunlu

              # Linting & Formatting
              llvmPackages.clang-tools # clang-tidy, clang-format
              cppcheck

              # Yardımcı komutlar
              configureScript
              lintScript
            ];

            shellHook = ''
              export ARM_NONE_EABI_SYSROOT="${pkgs.gcc-arm-embedded}/arm-none-eabi"
              echo "=========================================================="
              echo " ThreadX + libopencm3 DevShell (${system})"
              echo " - Yapılandırma : project-configure"
              echo " - Derleme      : cmake --build build"
              echo " - Lint / Analiz: project-lint"
              echo "=========================================================="
            '';
          };
        });
    };
}
