{
  addDriverRunpath,
  alembic,
  boost,
  callPackage,
  ceres-solver,
  cmake,
  cudaPackages,
  dbus,
  draco,
  embree,
  fetchzip,
  ffmpeg_7,
  fftw,
  fftwFloat,
  freetype,
  gettext,
  glew,
  gmp,
  jemalloc,
  lib,
  libdecor,
  libepoxy,
  libffi,
  libGL,
  libGLU,
  libharu,
  libjpeg,
  libpng,
  libsamplerate,
  libsndfile,
  libspnav,
  libtiff,
  libwebp,
  libx11,
  libxext,
  libxi,
  libxkbcommon,
  libxrender,
  libxxf86vm,
  llvmPackages,
  makeWrapper,
  manifold,
  mesa,
  meshoptimizer,
  nix-update-script,
  onetbb,
  openal,
  opencolorio,
  openexr,
  openimagedenoise,
  openimageio,
  openjpeg,
  openpgl,
  opensubdiv,
  openvdb,
  openxr-loader,
  pkg-config,
  potrace,
  pugixml,
  python313Packages, # must use python3Packages instead of python3.pkgs, see https://github.com/NixOS/nixpkgs/issues/211340
  rubberband,
  runCommand,
  shaderc,
  spaceNavSupport ? true,
  stdenv,
  vulkan-headers,
  vulkan-loader,
  wayland,
  wayland-protocols,
  wayland-scanner,
  waylandSupport ? true,
  zlib,
  zstd,
}:

let
  stdenv' = cudaPackages.backendStdenv;
  python3Packages = python313Packages;
  python3 = python3Packages.python;

  libdecor' = libdecor.overrideAttrs (old: {
    # Blender uses private APIs, need to patch to expose them
    patches = (old.patches or [ ]) ++ [ ./libdecor.patch ];
  });
in

stdenv'.mkDerivation (finalAttrs: {
  pname = "blender";
  version = "5.2.3";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchzip {
    name = "source";
    url = "https://download.blender.org/source/blender-${finalAttrs.version}.tar.xz";
    hash = "sha256-umFiI2GnG54t9LQAKUpC2ZHVeq+oN5xmpOf4H+nql6M=";
  };

  patches = [
    # Blender actually wants a more recent version of eigen. However, the
    # ceres-solver dependency propagates eigen 3 and appears to be incompatible
    # with more recent versions.
    ./eigen-3-compat.patch
  ];

  postPatch = ''
    substituteInPlace intern/ghost/intern/GHOST_SystemPathsUnix.cc \
      --replace-fail \
        'static const char *static_libs_path = PREFIX "/" BLENDER_INSTALL_LIBDIR;' \
        'static const char *static_libs_path = BLENDER_INSTALL_LIBDIR;'
  '';

  env.NIX_CFLAGS_COMPILE = "-I${python3}/include/${python3.libPrefix}";

  cmakeFlags = [
    "-C../build_files/cmake/config/blender_release.cmake"

    (lib.cmakeFeature "MaterialX_DIR" "${python3Packages.materialx}/lib/cmake/MaterialX")
    (lib.cmakeFeature "PYTHON_INCLUDE_DIR" "${python3}/include/${python3.libPrefix}")
    (lib.cmakeFeature "PYTHON_LIBPATH" "${python3}/lib")
    (lib.cmakeFeature "PYTHON_LIBRARY" "${python3.libPrefix}")
    (lib.cmakeFeature "PYTHON_NUMPY_INCLUDE_DIRS" "${python3Packages.numpy}/${python3.sitePackages}/numpy/_core/include")
    (lib.cmakeFeature "PYTHON_NUMPY_PATH" "${python3Packages.numpy}/${python3.sitePackages}")
    (lib.cmakeFeature "PYTHON_VERSION" "${python3.pythonVersion}")

    (lib.cmakeBool "WITH_BUILDINFO" false)
    (lib.cmakeBool "WITH_CPU_CHECK" false)
    (lib.cmakeBool "WITH_CYCLES_CUDA_BINARIES" true)
    (lib.cmakeBool "WITH_CYCLES_DEVICE_CUDA" true)
    (lib.cmakeBool "WITH_CYCLES_DEVICE_HIP" false)
    (lib.cmakeBool "WITH_CYCLES_HIP_BINARIES" false)
    (lib.cmakeBool "WITH_CYCLES_DEVICE_ONEAPI" false)
    (lib.cmakeBool "WITH_CYCLES_ONEAPI_BINARIES" false)
    (lib.cmakeBool "WITH_CYCLES_DEVICE_OPTIX" false)
    (lib.cmakeBool "WITH_CYCLES_EMBREE" true)
    (lib.cmakeBool "WITH_CYCLES_OSL" true)
    (lib.cmakeBool "WITH_CYCLES_PARALLEL_DEVICE_KERNEL_BUILD" true)
    (lib.cmakeBool "WITH_HYDRA" false)
    (lib.cmakeBool "WITH_INSTALL_PORTABLE" false)
    (lib.cmakeBool "WITH_JACK" false)
    (lib.cmakeBool "WITH_LIBS_PRECOMPILED" false)
    (lib.cmakeBool "WITH_OPENIMAGEDENOISE" true)
    (lib.cmakeBool "WITH_PIPEWIRE" false)
    (lib.cmakeBool "WITH_PULSEAUDIO" false)
    (lib.cmakeBool "WITH_PYTHON_INSTALL" false)
    (lib.cmakeBool "WITH_PYTHON_INSTALL_NUMPY" false)
    (lib.cmakeBool "WITH_PYTHON_INSTALL_REQUESTS" false)
    (lib.cmakeBool "WITH_STRICT_BUILD_OPTIONS" true)
    (lib.cmakeBool "WITH_SYSTEM_GLOG" true)
    (lib.cmakeBool "WITH_USD" false)

    # Blender supplies its own FindAlembic.cmake (incompatible with the Alembic-supplied config file)
    (lib.cmakeFeature "ALEMBIC_INCLUDE_DIR" "${lib.getDev alembic}/include")
    (lib.cmakeFeature "ALEMBIC_LIBRARY" "${lib.getLib alembic}/lib/libAlembic${stdenv.hostPlatform.extensions.sharedLibrary}")
    (lib.cmakeFeature "CYCLES_CUDA_BINARIES_ARCH" (lib.concatStringsSep ";" cudaPackages.flags.realArches))
  ]
  ++ lib.optionals waylandSupport [
    (lib.cmakeBool "WITH_GHOST_WAYLAND" true)
    (lib.cmakeBool "WITH_GHOST_WAYLAND_DYNLOAD" false)
  ]
  ++ lib.optionals stdenv.cc.isClang [
    (lib.cmakeFeature "PYTHON_LINKFLAGS" "") # Clang doesn't support "-export-dynamic"
  ];

  preConfigure = ''
    (
      expected_python_version=$(grep -E --only-matching 'set\(_PYTHON_VERSION_SUPPORTED [0-9.]+\)' build_files/cmake/Modules/FindPythonLibsUnix.cmake | grep -E --only-matching '[0-9.]+')
      actual_python_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[0:2])))')
      if ! [[ "$actual_python_version" = "$expected_python_version" ]]; then
        echo "wrong Python version, expected '$expected_python_version', got '$actual_python_version'" >&2
        exit 1
      fi
    )
  '';

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkg-config
    python3Packages.wrapPython
    python3
    addDriverRunpath
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    alembic
    boost
    ceres-solver
    draco
    ffmpeg_7
    fftw
    fftwFloat
    freetype
    gettext
    glew
    gmp
    jemalloc
    libepoxy
    libharu
    libjpeg
    libpng
    libsamplerate
    libsndfile
    libtiff
    libwebp
    manifold
    meshoptimizer
    opencolorio
    openexr
    openimageio
    openjpeg
    openpgl
    (opensubdiv.override { cudaSupport = true; })
    onetbb
    openvdb
    openxr-loader
    potrace
    pugixml
    python3Packages.materialx
    python3Packages.openshadinglanguage
    rubberband
    llvmPackages.llvm
    embree
    (openimagedenoise.override { cudaSupport = true; })
    libGL
    libGLU
    libx11
    libxext
    libxi
    libxrender
    libxxf86vm
    openal
    cudaPackages.cuda_cudart
    shaderc
    vulkan-headers
    vulkan-loader
    zlib
    zstd
  ]
  ++ lib.optionals waylandSupport [
    dbus
    libdecor'
    libffi
    libxkbcommon
    wayland
    wayland-protocols
    wayland-scanner
  ]
  ++ lib.optional spaceNavSupport libspnav;

  pythonPath =
    let
      ps = python3Packages;
    in
    [
      ps.cattrs
      ps.materialx
      ps.numpy
      ps.openshadinglanguage
      ps.requests
      ps.zstandard
    ];

  blenderExecutable = placeholder "out" + "/bin/blender";

  postInstall = ''
    buildPythonPath "''${pythonPath[*]}"
    wrapProgram $blenderExecutable \
      --prefix PATH : $program_PATH \
      --prefix PYTHONPATH : "$program_PYTHONPATH" \
      --add-flags '--python-use-system-env'
  '';

  # Set RUNPATH so that libs in /run/opengl-driver(-32)/lib can be
  # found. See the explanation in libglvnd.
  postFixup = ''
    for program in $out/bin/blender $out/bin/.blender-wrapped; do
      addDriverRunpath "$program"
    done
  '';

  passthru = {
    python = python3;
    pythonPackages = python3Packages;

    withPackages =
      f:
      (callPackage ./wrapper.nix { }).override {
        blender = finalAttrs.finalPackage;
        extraModules = (f python3Packages);
      };

    tests = {
      render = runCommand "${finalAttrs.pname}-test" { nativeBuildInputs = [ mesa.llvmpipeHook ]; } ''
        set -euo pipefail
        cat <<'PYTHON' > scene-config.py
        import bpy
        bpy.context.scene.eevee.taa_render_samples = 32
        bpy.context.scene.cycles.samples = 32
        bpy.context.scene.render.resolution_x = 100
        bpy.context.scene.render.resolution_y = 100
        bpy.context.scene.render.threads_mode = 'FIXED'
        bpy.context.scene.render.threads = 1
        PYTHON

        mkdir $out
        for engine in BLENDER_EEVEE_NEXT CYCLES; do
          echo "Rendering with $engine..."
          # Beware that argument order matters
          ${lib.getExe finalAttrs.finalPackage} \
            --background \
            -noaudio \
            --factory-startup \
            --python-exit-code 1 \
            --python scene-config.py \
            --engine "$engine" \
            --render-output "$out/$engine" \
            --render-frame 1
        done
      '';
      tester-cudaAvailable = cudaPackages.writeGpuTestPython { } ''
        import subprocess
        subprocess.run([
            "${lib.getExe finalAttrs.finalPackage}",
            "--background",
            "-noaudio",
            "--python-exit-code",
            "1",
            "--python",
            "${./test-cuda.py}",
        ], check=True)
      '';
    };

    updateScript = nix-update-script {
      extraArgs = [
        "--url=https://projects.blender.org/blender/blender"
      ];
    };
  };

  meta = {
    description = "3D Creation/Animation/Publishing System";
    homepage = "https://www.blender.org";
    license = with lib.licenses; [
      gpl2Plus
      nvidiaCudaRedist
    ];
    donationPage = "https://fund.blender.org/";

    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [
      amarshall
      veprbl
    ];
    mainProgram = "blender";
  };
})
