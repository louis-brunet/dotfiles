# #!/usr/bin/env bash
#
# set -e
#
# log() {
#   echo "[$0] $*"
# }
#
# LLAMACPP_REPO=ggml-org/llama.cpp
# LLAMACPP_BUILD_JOBS=8
# LLAMACPP_BUILD_TARGET=llama-server
# LLAMACPP_INSTALL_DIR="${LLAMACPP_INSTALL_DIR:-$(mktemp -d)}"
# log "created $LLAMACPP_INSTALL_DIR"
#
# remove_temp_install_dir() {
#
#   cd - || return 1
#   log "TODO: rm -rf $LLAMACPP_INSTALL_DIR" || return 1
#   #
#   # # rm -rf "$LLAMACPP_TEMP_INSTALL_DIR" || return 1
#   # # log "removed $LLAMACPP_TEMP_INSTALL_DIR" || return 1
# }
#
# install_dependencies() {
#   sudo apt install -y \
#     libcurl4-openssl-dev \
#     || return 1
#
#   # # NOTE: Vulkan SDK installation/uninstallation guide - https://vulkan.lunarg.com/doc/view/latest/linux/getting_started_ubuntu.html
#   # wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
#   # sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-noble.list http://packages.lunarg.com/vulkan/lunarg-vulkan-noble.list
#   # sudo apt update
#   # sudo apt install vulkan-sdk
#   # vulkaninfo
#
#   # sudo apt install -y ocl-icd-opencl-dev
#   # # Add ROCm repository
#   # wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
#   # echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
#   # sudo apt update
#   # # Install ROCm packages
#   # sudo apt install -y rocm-opencl-dev
#
#   sudo apt update || return 1
#   # sudo apt install "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)" || return 1
#   # sudo apt install python3-setuptools python3-wheel || return 1
#   sudo usermod -a -G render,video $LOGNAME || return 1 # Add the current user to the render and video groups
#   wget https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/noble/amdgpu-install_6.3.60303-1_all.deb || return 1
#   sudo apt install ./amdgpu-install_6.3.60303-1_all.deb || return 1
#
#   # - installs packages amdgpu-install and dialog
#   # - then installs these packages:
#   # alsa-topology-conf alsa-ucm-conf amd-smi-lib amdgpu-core amdgpu-dkms amdgpu-dkms-firmware autoconf automake autotools-dev busybox-initramfs comgr composablekernel-dev cpio dkms dracut-install ffmpeg g++-13-multilib g++-multilib gcc-11-base gcc-13-multilib gcc-multilib gdb half hip-dev hip-doc hip-runtime-amd hip-samples hipblas hipblas-common-dev hipblas-dev hipblaslt hipblaslt-dev hipcc hipcub-dev hipfft hipfft-dev hipfort-dev hipify-clang hiprand hiprand-dev hipsolver hipsolver-dev hipsparse hipsparse-dev hipsparselt hipsparselt-dev hiptensor hiptensor-dev hsa-amd-aqlprofile hsa-rocr hsa-rocr-dev i965-va-driver initramfs-tools initramfs-tools-bin initramfs-tools-core intel-media-va-driver klibc-utils lib32asan8 lib32atomic1 lib32gcc-13-dev lib32gcc-s1 lib32gomp1 lib32itm1 lib32quadmath0 lib32stdc++-13-dev lib32stdc++6 lib32ubsan1 libaacs0 libamd3 libasan6 libasound2-data libasound2t64 libass9 libasyncns0 libavc1394-0 libavcodec-dev libavcodec60 libavdevice60 libavfilter9 libavformat-dev libavformat60 libavutil-dev libavutil58 libbabeltrace1 libbdplus0 libblas3 libbluray2 libbs2b0 libc6-dbg libc6-dev-i386 libc6-dev-x32 libc6-i386 libc6-x32 libcaca0 libcamd3 libccolamd3 libcdio-cdda2t64 libcdio-paranoia2t64 libcdio19t64 libcholmod5 libchromaprint1 libcjson1 libcodec2-1.2 libcolamd3 libdav1d7 libdc1394-25 libdebuginfod-common libdebuginfod1t64 libdecor-0-0 libdecor-0-plugin-1-gtk libdrm-amdgpu-amdgpu1 libdrm-amdgpu-common libdrm-amdgpu-dev libdrm-amdgpu-radeon1 libdrm-dev libdrm2-amdgpu libelf-dev libfftw3-double3 libfile-copy-recursive-perl libfile-listing-perl libfile-which-perl libflac12t64 libflite1 libgcc-11-dev libgfortran5 libgl-dev libglx-dev libgme0 libgsm1 libhttp-date-perl libhwy1t64 libiec61883-0 libigdgmm12 libipt2 libjack-jackd2-0 libjxl0.7 libklibc liblapack3 liblilv-0-0 libmbedcrypto7t64 libmp3lame0 libmpg123-0t64 libmysofa1 libnorm1t64 libnuma-dev libnuma1 libogg0 libopenal-data libopenal1 libopenjp2-7 libopenmpt0t64 libopus0 libpci3 libpciaccess-dev libpgm-5.3-0t64 libplacebo338 libpocketsphinx3 libpostproc57 libpulse0 librabbitmq4 librav1e0 libraw1394-11 librist4 librubberband2 libsamplerate0 libsdl2-2.0-0 libserd-0-0 libshine3 libsnappy1v5 libsndfile1 libsndio7.0 libsord-0-0 libsource-highlight-common libsource-highlight4t64 libsoxr0 libspeex1 libsphinxbase3t64 libsratom-0-0 libsrt1.5-gnutls libssh-gcrypt-4 libstdc++-11-dev libsuitesparseconfig7 libsvtav1enc1d1 libswresample-dev libswresample4 libswscale-dev libswscale7 libtheora0 libtimedate-perl libtsan0 libtwolame0 libudfread0 libunibreak5 liburi-perl libusb-1.0-0 libva-drm2 libva-x11-2 libva2 libvdpau1 libvidstab1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libvpl2 libvpx9 libwebpmux3 libx264-164 libx265-199 libx32asan8 libx32atomic1 libx32gcc-13-dev libx32gcc-s1 libx32gomp1 libx32itm1 libx32quadmath0 libx32stdc++-13-dev libx32stdc++6 libx32ubsan1 libxcb-shape0 libxv1 libxvidcore4 libzimg2 libzix-0-0 libzmq5 libzstd-dev libzvbi-common libzvbi0t64 linux-base linux-headers-6.8.0-55 linux-headers-6.8.0-55-generic linux-headers-generic m4 mesa-common-dev mesa-va-drivers mesa-vdpau-drivers migraphx migraphx-dev miopen-hip miopen-hip-dev mivisionx mivisionx-dev ocl-icd-libopencl1 openmp-extras-dev openmp-extras-runtime pciutils pocketsphinx-en-us python3-argcomplete rccl rccl-dev rocalution rocalution-dev rocblas rocblas-dev rocfft rocfft-dev rocm rocm-cmake rocm-core rocm-dbgapi rocm-debug-agent rocm-developer-tools rocm-device-libs rocm-gdb rocm-hip-libraries rocm-hip-runtime rocm-hip-runtime-dev rocm-hip-sdk rocm-language-runtime rocm-llvm rocm-ml-libraries rocm-ml-sdk rocm-opencl rocm-opencl-dev rocm-opencl-runtime rocm-opencl-sdk rocm-openmp-sdk rocm-smi-lib rocm-utils rocminfo rocprim-dev rocprofiler rocprofiler-dev rocprofiler-plugins rocprofiler-register rocprofiler-sdk rocprofiler-sdk-roctx rocrand rocrand-dev rocsolver rocsolver-dev rocsparse rocsparse-dev rocthrust-dev roctracer roctracer-dev rocwmma-dev rpp rpp-dev va-driver-all valgrind vdpau-driver-all zstd
#
#
#   # sudo apt install -y amdgpu-install
#
#   # sudo apt update || return 1
#   # sudo apt install amdgpu-dkms rocm || return 1
#
#   log "✅ installed dependencies for llama.cpp build" || return 1
# }
#
# install_llamacpp() {
#   install_dependencies || return 1
#
#   latest_tag_name="$(curl -s "https://api.github.com/repos/$LLAMACPP_REPO/releases/latest" | jq -r .tag_name)"
#   log "🌐 pulling llama.cpp source code at the tag for the latest release ($latest_tag_name)" || return 1
#   git clone --depth 1 --branch "$latest_tag_name" "https://github.com/$LLAMACPP_REPO" || return 1
#
#   cd "$(basename "$LLAMACPP_REPO")" || return 1
#
#     # -DGGML_VULKAN=ON \
#   cmake -B build \
#     -DGGML_HIP=ON \
#     -DLLAMA_CURL=ON \
#     || return 1
#
#   cmake \
#     --build build \
#     --config Release \
#     --parallel "$LLAMACPP_BUILD_JOBS" \
#     --target "$LLAMACPP_BUILD_TARGET" \
#     || return 1
#
#   ls build/bin || return 1
#
#   log "✅ built $LLAMACPP_BUILD_TARGET from source"
# }
#
# cd "$LLAMACPP_INSTALL_DIR"
#
# install_llamacpp ||  {
#   log "ERROR: could not install llama.cpp"
#   remove_temp_install_dir
#   exit 1
# }
#
# remove_temp_install_dir
