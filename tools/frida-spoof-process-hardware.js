/*
 * Load after the main LDPlayer bypass script when the app should see a
 * Samsung SM-N935F-like hardware profile from in-process Java/native APIs.
 */
(function () {
  var PROFILE = {
    build: {
      PRODUCT: "gracerltexx",
      MANUFACTURER: "samsung",
      BRAND: "samsung",
      DEVICE: "gracerlte",
      MODEL: "SM-N935F",
      HARDWARE: "samsungexynos8890",
      FINGERPRINT: "samsung/gracerltexx/gracerlte:8.0.0/R16NW/N935FXXS4BRK2:user/release-keys"
    },
    cpu: {
      abi: "arm64-v8a",
      abiList: "arm64-v8a,armeabi-v7a,armeabi",
      abiArray: ["arm64-v8a", "armeabi-v7a", "armeabi"],
      abiList32: "armeabi-v7a,armeabi",
      abiArray32: ["armeabi-v7a", "armeabi"],
      abiList64: "arm64-v8a",
      abiArray64: ["arm64-v8a"],
      cores: 8,
      familyArm64: 4
    },
    gpu: {
      vendor: "ARM",
      renderer: "Mali-T880",
      version: "OpenGL ES 3.2"
    },
    memory: {
      totalMem: 4294967296,
      availMem: 2147483648,
      threshold: 268435456,
      lowMemory: false
    },
    props: {
      "ro.product.cpu.abi": "arm64-v8a",
      "ro.product.cpu.abilist": "arm64-v8a,armeabi-v7a,armeabi",
      "ro.product.cpu.abilist32": "armeabi-v7a,armeabi",
      "ro.product.cpu.abilist64": "arm64-v8a",
      "ro.hardware": "samsungexynos8890",
      "ro.board.platform": "exynos5",
      "ro.hardware.egl": "mali",
      "ro.opengles.version": "196610"
    }
  };

  var GL_VENDOR = 0x1f00;
  var GL_RENDERER = 0x1f01;
  var GL_VERSION = 0x1f02;
  var nativeStringCache = {};

  function fakeGlString(name) {
    var value = Number(name);
    if (value === GL_VENDOR) return PROFILE.gpu.vendor;
    if (value === GL_RENDERER) return PROFILE.gpu.renderer;
    if (value === GL_VERSION) return PROFILE.gpu.version;
    return null;
  }

  function nativeString(value) {
    if (!nativeStringCache[value]) {
      nativeStringCache[value] = Memory.allocUtf8String(value);
    }
    return nativeStringCache[value];
  }

  function findExport(moduleName, symbolName) {
    try {
      if (moduleName === null && Module.getGlobalExportByName) {
        return Module.getGlobalExportByName(symbolName);
      }
    } catch (ignored) {
    }

    try {
      var module = Process.findModuleByName(moduleName);
      if (module && module.findExportByName) {
        return module.findExportByName(symbolName);
      }
    } catch (ignored) {
    }

    try {
      if (Module.findExportByName) {
        return Module.findExportByName(moduleName, symbolName);
      }
    } catch (ignored) {
    }

    return null;
  }

  function propValue(key) {
    if (Object.prototype.hasOwnProperty.call(PROFILE.props, key)) {
      return PROFILE.props[key];
    }
    if (key === "ro.build.fingerprint") {
      return PROFILE.build.FINGERPRINT;
    }
    return null;
  }

  function setBuildProfile() {
    var Build = Java.use("android.os.Build");
    Object.keys(PROFILE.build).forEach(function (fieldName) {
      try {
        Build[fieldName].value = PROFILE.build[fieldName];
      } catch (err) {
        console.log("[-] Build." + fieldName + " spoof failed: " + err);
      }
    });

    try {
      Build.CPU_ABI.value = PROFILE.cpu.abi;
      Build.CPU_ABI2.value = PROFILE.cpu.abiArray32[0];
      Build.SUPPORTED_ABIS.value = Java.array("java.lang.String", PROFILE.cpu.abiArray);
      Build.SUPPORTED_32_BIT_ABIS.value = Java.array("java.lang.String", PROFILE.cpu.abiArray32);
      Build.SUPPORTED_64_BIT_ABIS.value = Java.array("java.lang.String", PROFILE.cpu.abiArray64);
    } catch (err) {
      console.log("[-] Build CPU ABI spoof failed: " + err);
    }
  }

  function hookRuntime() {
    try {
      var Runtime = Java.use("java.lang.Runtime");
      Runtime.availableProcessors.implementation = function () {
        return PROFILE.cpu.cores;
      };
      console.log("[+] Runtime.availableProcessors spoof enabled: " + PROFILE.cpu.cores);
    } catch (err) {
      console.log("[-] Runtime.availableProcessors hook failed: " + err);
    }
  }

  function patchMemoryInfo(info) {
    if (!info) return;
    try {
      info.totalMem.value = PROFILE.memory.totalMem;
      info.availMem.value = PROFILE.memory.availMem;
      info.threshold.value = PROFILE.memory.threshold;
      info.lowMemory.value = PROFILE.memory.lowMemory;
    } catch (err) {
      console.log("[-] MemoryInfo patch failed: " + err);
    }
  }

  function hookMemoryInfo() {
    try {
      var ActivityManager = Java.use("android.app.ActivityManager");
      ActivityManager.getMemoryInfo.implementation = function (outInfo) {
        this.getMemoryInfo.call(this, outInfo);
        patchMemoryInfo(outInfo);
      };
      console.log("[+] ActivityManager.MemoryInfo spoof enabled: totalMem=" + PROFILE.memory.totalMem);
    } catch (err) {
      console.log("[-] ActivityManager.getMemoryInfo hook failed: " + err);
    }
  }

  function hookSystemProperties() {
    try {
      var SystemProperties = Java.use("android.os.SystemProperties");

      SystemProperties.get.overload("java.lang.String").implementation = function (key) {
        var fake = propValue(String(key));
        if (fake !== null) return fake;
        return this.get.overload("java.lang.String").call(this, key);
      };

      SystemProperties.get.overload("java.lang.String", "java.lang.String").implementation = function (key, def) {
        var fake = propValue(String(key));
        if (fake !== null) return fake;
        return this.get.overload("java.lang.String", "java.lang.String").call(this, key, def);
      };

      SystemProperties.getInt.overload("java.lang.String", "int").implementation = function (key, def) {
        var fake = propValue(String(key));
        if (fake !== null && /^-?\d+$/.test(fake)) return parseInt(fake, 10);
        return this.getInt.overload("java.lang.String", "int").call(this, key, def);
      };

      SystemProperties.getLong.overload("java.lang.String", "long").implementation = function (key, def) {
        var fake = propValue(String(key));
        if (fake !== null && /^-?\d+$/.test(fake)) return parseInt(fake, 10);
        return this.getLong.overload("java.lang.String", "long").call(this, key, def);
      };

      try {
        SystemProperties.native_get.overload("java.lang.String").implementation = function (key) {
          var fake = propValue(String(key));
          if (fake !== null) return fake;
          return this.native_get.overload("java.lang.String").call(this, key);
        };
      } catch (ignored) {
      }

      try {
        SystemProperties.native_get.overload("java.lang.String", "java.lang.String").implementation = function (key, def) {
          var fake = propValue(String(key));
          if (fake !== null) return fake;
          return this.native_get.overload("java.lang.String", "java.lang.String").call(this, key, def);
        };
      } catch (ignored) {
      }

      try {
        SystemProperties.native_get_int.overload("java.lang.String", "int").implementation = function (key, def) {
          var fake = propValue(String(key));
          if (fake !== null && /^-?\d+$/.test(fake)) return parseInt(fake, 10);
          return this.native_get_int.overload("java.lang.String", "int").call(this, key, def);
        };
      } catch (ignored) {
      }

      try {
        SystemProperties.native_get_long.overload("java.lang.String", "long").implementation = function (key, def) {
          var fake = propValue(String(key));
          if (fake !== null && /^-?\d+$/.test(fake)) return parseInt(fake, 10);
          return this.native_get_long.overload("java.lang.String", "long").call(this, key, def);
        };
      } catch (ignored) {
      }

      console.log("[+] android.os.SystemProperties CPU/GPU props spoof enabled");
    } catch (err) {
      console.log("[-] SystemProperties hook failed: " + err);
    }
  }

  function hookJavaGlesClass(className) {
    try {
      var Gles = Java.use(className);
      Gles.glGetString.overload("int").implementation = function (name) {
        var fake = fakeGlString(name);
        if (fake !== null) return fake;
        return this.glGetString.overload("int").call(this, name);
      };
      console.log("[+] " + className + ".glGetString spoof enabled");
    } catch (err) {
      console.log("[-] " + className + ".glGetString hook failed: " + err);
    }
  }

  function hookJavaGl() {
    [
      "android.opengl.GLES10",
      "android.opengl.GLES20",
      "android.opengl.GLES30",
      "android.opengl.GLES31",
      "android.opengl.GLES32",
      "javax.microedition.khronos.opengles.GL10"
    ].forEach(hookJavaGlesClass);
  }

  function hookNativeSystemProperties() {
    var systemPropertyGet = findExport("libc.so", "__system_property_get");
    if (!systemPropertyGet) {
      console.log("[-] __system_property_get export not found");
      return;
    }

    Interceptor.attach(systemPropertyGet, {
      onEnter: function (args) {
        this.key = args[0].readCString();
        this.out = args[1];
      },
      onLeave: function (retval) {
        var fake = propValue(this.key);
        if (fake === null) return;
        var value = nativeString(fake);
        Memory.copy(this.out, value, fake.length + 1);
        retval.replace(fake.length);
      }
    });
    console.log("[+] __system_property_get spoof enabled");
  }

  function hookNativeGl() {
    var hooked = {};

    [null, "libGLESv1_CM.so", "libGLESv2.so", "libGLESv3.so"].forEach(function (moduleName) {
      var glGetString = findExport(moduleName, "glGetString");
      if (!glGetString) return;

      var key = glGetString.toString();
      if (hooked[key]) return;
      hooked[key] = true;

      Interceptor.attach(glGetString, {
        onEnter: function (args) {
          this.name = args[0].toInt32();
        },
        onLeave: function (retval) {
          var fake = fakeGlString(this.name);
          if (fake !== null) {
            retval.replace(nativeString(fake));
          }
        }
      });
      console.log("[+] native glGetString spoof enabled at " + glGetString);
    });
  }

  function hookNativeCpuFeatures() {
    try {
      var getCpuFamily = findExport(null, "android_getCpuFamily");
      if (getCpuFamily) {
        Interceptor.attach(getCpuFamily, {
          onLeave: function (retval) {
            retval.replace(PROFILE.cpu.familyArm64);
          }
        });
        console.log("[+] android_getCpuFamily spoof enabled: ARM64");
      }
    } catch (err) {
      console.log("[-] android_getCpuFamily hook failed: " + err);
    }

    try {
      var getCpuCount = findExport(null, "android_getCpuCount");
      if (getCpuCount) {
        Interceptor.attach(getCpuCount, {
          onLeave: function (retval) {
            retval.replace(PROFILE.cpu.cores);
          }
        });
        console.log("[+] android_getCpuCount spoof enabled: " + PROFILE.cpu.cores);
      }
    } catch (err) {
      console.log("[-] android_getCpuCount hook failed: " + err);
    }
  }

  Java.perform(function () {
    setBuildProfile();
    hookRuntime();
    hookMemoryInfo();
    hookSystemProperties();
    hookJavaGl();
    console.log("[+] Process hardware profile spoof enabled: " +
      PROFILE.build.MODEL + ", " + PROFILE.cpu.cores + " cores, " +
      PROFILE.gpu.renderer + ", mem=" + PROFILE.memory.totalMem);
  });

  [500, 1500, 3000].forEach(function (delayMs) {
    setTimeout(function () {
      Java.perform(function () {
        setBuildProfile();
        console.log("[+] Build profile refreshed after delayed bypass hooks (" + delayMs + "ms)");
      });
    }, delayMs);
  });

  hookNativeSystemProperties();
  hookNativeGl();
  hookNativeCpuFeatures();
})();
