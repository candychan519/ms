/*
 * Load after the main LDPlayer bypass script when the app should see a
 * Samsung SM-S921N-like hardware profile from in-process Java/native APIs.
 */
(function () {
  var PROFILE = {
    build: {
      PRODUCT: "e1sksx",
      MANUFACTURER: "samsung",
      BRAND: "samsung",
      DEVICE: "e1s",
      MODEL: "SM-S921N",
      BOARD: "s5e9945",
      HARDWARE: "s5e9945",
      SOC_MANUFACTURER: "Samsung",
      SOC_MODEL: "Exynos 2400",
      FINGERPRINT: "samsung/e1sksx/e1s:16/BP2A.250605.031.A2/S921NKSSDCZB4:user/release-keys"
    },
    cpu: {
      abi: "arm64-v8a",
      abiList: "arm64-v8a,armeabi-v7a,armeabi",
      abiArray: ["arm64-v8a", "armeabi-v7a", "armeabi"],
      abiList32: "armeabi-v7a,armeabi",
      abiArray32: ["armeabi-v7a", "armeabi"],
      abiList64: "arm64-v8a",
      abiArray64: ["arm64-v8a"],
      cores: 10,
      familyArm64: 4
    },
    gpu: {
      vendor: "Samsung",
      renderer: "Xclipse 940",
      version: "OpenGL ES 3.2"
    },
    memory: {
      totalMem: 8589934592,
      availMem: 5368709120,
      threshold: 536870912,
      lowMemory: false
    },
    display: {
      widthPixels: 1080,
      heightPixels: 2340,
      densityDpi: 420,
      density: 2.625,
      scaledDensity: 2.625,
      xdpi: 416.0,
      ydpi: 416.0
    },
    network: {
      ipAddress: "192.168.0.45",
      ipAddressInt: 755017920,
      macAddress: "02:11:32:54:76:7a",
      macBytes: [0x02, 0x11, 0x32, 0x54, 0x76, 0x7a]
    },
    locale: {
      timezoneId: "Asia/Seoul",
      countryIso: "kr",
      operator: "45008",
      operatorName: "KT"
    },
    vulkan: {
      vendorId: 0x144d,
      deviceId: 0x9945,
      deviceType: 1,
      vulkanDeviceName: "Samsung Xclipse 940"
    },
    props: {
      "ro.product.cpu.abi": "arm64-v8a",
      "ro.product.cpu.abilist": "arm64-v8a,armeabi-v7a,armeabi",
      "ro.product.cpu.abilist32": "armeabi-v7a,armeabi",
      "ro.product.cpu.abilist64": "arm64-v8a",
      "ro.hardware": "s5e9945",
      "ro.board.platform": "s5e9945",
      "ro.product.board": "s5e9945",
      "ro.product.device": "e1s",
      "ro.product.model": "SM-S921N",
      "ro.product.manufacturer": "samsung",
      "ro.product.brand": "samsung",
      "ro.soc.manufacturer": "Samsung",
      "ro.soc.model": "Exynos 2400",
      "ro.hardware.egl": "samsung",
      "ro.opengles.version": "196610",
      "ro.sf.lcd_density": "420",
      "qemu.sf.lcd_density": "420",
      "persist.sys.country": "KR",
      "persist.sys.language": "ko",
      "persist.sys.locale": "ko-KR",
      "persist.sys.timezone": "Asia/Seoul",
      "gsm.operator.iso-country": "kr",
      "gsm.sim.operator.iso-country": "kr",
      "gsm.operator.numeric": "45008",
      "gsm.sim.operator.numeric": "45008",
      "gsm.operator.alpha": "KT",
      "gsm.sim.operator.alpha": "KT",
      "dhcp.wlan0.ipaddress": "192.168.0.45",
      "dhcp.eth0.ipaddress": "192.168.0.45",
      "ro.boot.wifimacaddr": "02:11:32:54:76:7a",
      "wifi.interface.mac": "02:11:32:54:76:7a"
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
        if (typeof Build[fieldName] === "undefined") return;
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

  function patchDisplayMetrics(metrics) {
    if (!metrics) return;
    try {
      metrics.widthPixels.value = PROFILE.display.widthPixels;
      metrics.heightPixels.value = PROFILE.display.heightPixels;
      metrics.densityDpi.value = PROFILE.display.densityDpi;
      metrics.density.value = PROFILE.display.density;
      metrics.scaledDensity.value = PROFILE.display.scaledDensity;
      metrics.xdpi.value = PROFILE.display.xdpi;
      metrics.ydpi.value = PROFILE.display.ydpi;
    } catch (err) {
      console.log("[-] DisplayMetrics patch failed: " + err);
    }
  }

  function patchPoint(point) {
    if (!point) return;
    try {
      point.x.value = PROFILE.display.widthPixels;
      point.y.value = PROFILE.display.heightPixels;
    } catch (err) {
      console.log("[-] Display point patch failed: " + err);
    }
  }

  function hookDisplayProfile() {
    try {
      var Resources = Java.use("android.content.res.Resources");
      Resources.getDisplayMetrics.implementation = function () {
        var metrics = this.getDisplayMetrics.call(this);
        patchDisplayMetrics(metrics);
        return metrics;
      };
    } catch (err) {
      console.log("[-] Resources.getDisplayMetrics hook failed: " + err);
    }

    try {
      var Display = Java.use("android.view.Display");

      Display.getMetrics.implementation = function (metrics) {
        this.getMetrics.call(this, metrics);
        patchDisplayMetrics(metrics);
      };

      Display.getRealMetrics.implementation = function (metrics) {
        this.getRealMetrics.call(this, metrics);
        patchDisplayMetrics(metrics);
      };

      Display.getSize.implementation = function (point) {
        this.getSize.call(this, point);
        patchPoint(point);
      };

      Display.getRealSize.implementation = function (point) {
        this.getRealSize.call(this, point);
        patchPoint(point);
      };

      Display.getWidth.implementation = function () {
        return PROFILE.display.widthPixels;
      };

      Display.getHeight.implementation = function () {
        return PROFILE.display.heightPixels;
      };
    } catch (err) {
      console.log("[-] android.view.Display hook failed: " + err);
    }

    console.log("[+] Display profile spoof enabled: " +
      PROFILE.display.widthPixels + "x" + PROFILE.display.heightPixels +
      ", densityDpi=" + PROFILE.display.densityDpi);
  }

  function hookNetworkProfile() {
    try {
      var WifiInfo = Java.use("android.net.wifi.WifiInfo");
      WifiInfo.getIpAddress.implementation = function () {
        return PROFILE.network.ipAddressInt;
      };
      WifiInfo.getMacAddress.implementation = function () {
        return PROFILE.network.macAddress;
      };
      WifiInfo.getBSSID.implementation = function () {
        return PROFILE.network.macAddress;
      };
    } catch (err) {
      console.log("[-] WifiInfo hook failed: " + err);
    }

    try {
      var WifiManager = Java.use("android.net.wifi.WifiManager");
      WifiManager.getDhcpInfo.implementation = function () {
        var dhcpInfo = this.getDhcpInfo.call(this);
        if (dhcpInfo) {
          dhcpInfo.ipAddress.value = PROFILE.network.ipAddressInt;
        }
        return dhcpInfo;
      };
    } catch (err) {
      console.log("[-] WifiManager.getDhcpInfo hook failed: " + err);
    }

    try {
      var Formatter = Java.use("android.text.format.Formatter");
      Formatter.formatIpAddress.implementation = function () {
        return PROFILE.network.ipAddress;
      };
    } catch (err) {
      console.log("[-] Formatter.formatIpAddress hook failed: " + err);
    }

    try {
      var NetworkInterface = Java.use("java.net.NetworkInterface");
      NetworkInterface.getHardwareAddress.implementation = function () {
        return Java.array("byte", PROFILE.network.macBytes);
      };
    } catch (err) {
      console.log("[-] NetworkInterface.getHardwareAddress hook failed: " + err);
    }

    console.log("[+] Network profile spoof enabled: " +
      PROFILE.network.ipAddress + ", " + PROFILE.network.macAddress);
  }

  function hookKoreanLocaleAndTelephony() {
    try {
      var TimeZone = Java.use("java.util.TimeZone");
      TimeZone.getDefault.implementation = function () {
        return TimeZone.getTimeZone(PROFILE.locale.timezoneId);
      };
      console.log("[+] TimeZone spoof enabled: " + PROFILE.locale.timezoneId);
    } catch (err) {
      console.log("[-] TimeZone hook failed: " + err);
    }

    try {
      var TelephonyManager = Java.use("android.telephony.TelephonyManager");
      TelephonyManager.getNetworkCountryIso.overload().implementation = function () {
        return PROFILE.locale.countryIso;
      };
      TelephonyManager.getSimCountryIso.overload().implementation = function () {
        return PROFILE.locale.countryIso;
      };
      TelephonyManager.getNetworkOperator.overload().implementation = function () {
        return PROFILE.locale.operator;
      };
      TelephonyManager.getSimOperator.overload().implementation = function () {
        return PROFILE.locale.operator;
      };
      TelephonyManager.getNetworkOperatorName.overload().implementation = function () {
        return PROFILE.locale.operatorName;
      };
      TelephonyManager.getSimOperatorName.overload().implementation = function () {
        return PROFILE.locale.operatorName;
      };
      console.log("[+] TelephonyManager KR/KT spoof enabled");
    } catch (err) {
      console.log("[-] TelephonyManager hook failed: " + err);
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

  function writeVkPhysicalDeviceProperties(propertiesPtr) {
    if (!propertiesPtr || propertiesPtr.isNull()) return;
    try {
      propertiesPtr.add(8).writeU32(PROFILE.vulkan.vendorId);
      propertiesPtr.add(12).writeU32(PROFILE.vulkan.deviceId);
      propertiesPtr.add(16).writeU32(PROFILE.vulkan.deviceType);
      propertiesPtr.add(20).writeUtf8String(PROFILE.vulkan.vulkanDeviceName);
    } catch (err) {
      console.log("[-] Vulkan properties patch failed: " + err);
    }
  }

  function hookVulkanGpu() {
    try {
      var vkGetPhysicalDeviceProperties =
        findExport("libvulkan.so", "vkGetPhysicalDeviceProperties") ||
        findExport(null, "vkGetPhysicalDeviceProperties");

      if (vkGetPhysicalDeviceProperties) {
        Interceptor.attach(vkGetPhysicalDeviceProperties, {
          onEnter: function (args) {
            this.properties = args[1];
          },
          onLeave: function () {
            writeVkPhysicalDeviceProperties(this.properties);
          }
        });
        console.log("[+] vkGetPhysicalDeviceProperties spoof enabled: " + PROFILE.vulkan.vulkanDeviceName);
      }
    } catch (err) {
      console.log("[-] vkGetPhysicalDeviceProperties hook failed: " + err);
    }

    try {
      var vkGetPhysicalDeviceProperties2 =
        findExport("libvulkan.so", "vkGetPhysicalDeviceProperties2") ||
        findExport("libvulkan.so", "vkGetPhysicalDeviceProperties2KHR") ||
        findExport(null, "vkGetPhysicalDeviceProperties2") ||
        findExport(null, "vkGetPhysicalDeviceProperties2KHR");

      if (vkGetPhysicalDeviceProperties2) {
        Interceptor.attach(vkGetPhysicalDeviceProperties2, {
          onEnter: function (args) {
            this.properties2 = args[1];
          },
          onLeave: function () {
            var propertiesOffset = Process.pointerSize === 8 ? 16 : 8;
            writeVkPhysicalDeviceProperties(this.properties2.add(propertiesOffset));
          }
        });
        console.log("[+] vkGetPhysicalDeviceProperties2 spoof enabled: " + PROFILE.vulkan.vulkanDeviceName);
      }
    } catch (err) {
      console.log("[-] vkGetPhysicalDeviceProperties2 hook failed: " + err);
    }
  }

  Java.perform(function () {
    setBuildProfile();
    hookRuntime();
    hookMemoryInfo();
    hookDisplayProfile();
    hookSystemProperties();
    hookNetworkProfile();
    hookKoreanLocaleAndTelephony();
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
  hookVulkanGpu();
})();
