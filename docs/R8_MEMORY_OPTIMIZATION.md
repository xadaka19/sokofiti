# R8 Memory Optimization for Codemagic Builds

## Problem
R8 minification was failing with `OutOfMemoryError: Java heap space` during production builds on Codemagic.

## Root Cause
- R8 full-mode optimization requires significant memory (20GB+)
- Codemagic mac_pro_m2 has 32GB RAM total
- Previous configuration allocated 24GB to Java, leaving insufficient headroom for system processes

## Solution Applied

### 1. Reduced Java Heap Allocation
**Changed from:** 24GB → **12GB** (conservative approach)

**Files Modified:**
- `android/gradle.properties` - JVM args
- `codemagic.yaml` - JAVA_TOOL_OPTIONS and GRADLE_OPTS

**Rationale:** Leaves 20GB for system processes, R8 temporary files, and other build tools

### 2. Switched ProGuard Configuration
**Changed from:** `proguard-android-optimize.txt` → `proguard-android.txt`

**File:** `android/app/build.gradle`

**Impact:**
- Less aggressive optimization = lower memory usage
- Still provides code obfuscation and shrinking
- Slightly larger APK size (acceptable trade-off)

### 3. Reduced ProGuard Optimization Passes
**Changed from:** 5 passes → **2 passes**

**File:** `android/app/proguard-rules.pro`

**Impact:**
- Faster build time
- Lower memory consumption
- Still provides good obfuscation

### 4. Limited R8 Worker Threads
**Added:** `android.r8.maxWorkers = 2`

**Files:**
- `android/gradle.properties`
- `android/app/build.gradle`

**Impact:**
- Reduces parallel processing
- Lower peak memory usage
- Slightly longer build time (acceptable)

### 5. Enhanced Memory Cleanup
**Added aggressive cleanup script in `codemagic.yaml`:**
- Kill stale Gradle daemons
- Clear build cache
- Force kill any lingering Gradle processes
- Display memory status

### 6. Disabled R8 Full Mode
**Added:** `android.enableR8.fullMode=false`

**File:** `android/gradle.properties`

**Impact:**
- Uses R8 compatibility mode instead of full mode
- Significantly lower memory usage
- Still provides code shrinking and obfuscation

## Configuration Summary

### gradle.properties
```properties
org.gradle.jvmargs=-Xmx12g -Xms4g -Dfile.encoding=UTF-8 -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:SoftRefLRUPolicyMSPerMB=1 -XX:ReservedCodeCacheSize=512m
org.gradle.parallel=false
android.enableR8.fullMode=false
android.r8.maxWorkers=2
```

### codemagic.yaml
```yaml
vars:
  JAVA_TOOL_OPTIONS: "-Xmx12g -Xms4g"
  GRADLE_OPTS: "-Xmx12g -Xms4g -Dorg.gradle.jvmargs=-Xmx12g -Dorg.gradle.parallel=false -Dorg.gradle.daemon=false -Dorg.gradle.workers.max=2 -Dkotlin.compiler.execution.strategy=in-process"
```

### build.gradle
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        
        android.r8 {
            maxWorkers = 2
        }
    }
}
```

## Memory Allocation Breakdown

| Component | Memory | Purpose |
|-----------|--------|---------|
| Java Heap (Xmx) | 12 GB | R8, Gradle, Kotlin compiler |
| Java Initial (Xms) | 4 GB | Faster startup, less GC |
| Metaspace | 512 MB | Class metadata |
| Code Cache | 512 MB | JIT compiled code |
| System + Other | ~19 GB | macOS, build tools, temp files |
| **Total** | **32 GB** | mac_pro_m2 instance |

## Expected Results

### Build Time
- **Before:** ~17 minutes (failed with OOM)
- **After:** ~15-20 minutes (should complete successfully)

### APK Size Impact
- **Increase:** ~5-10% larger than full R8 optimization
- **Still acceptable:** Code is obfuscated and shrunk

### Security Impact
- ✅ Code obfuscation: **ENABLED**
- ✅ Resource shrinking: **ENABLED**
- ✅ ProGuard rules: **ACTIVE**
- ⚠️ Optimization level: **REDUCED** (from 5 to 2 passes)

**Overall Security:** Still strong, minor reduction in optimization depth

## Monitoring

### Check Memory During Build
The build now displays memory status:
```bash
🔹 Memory status after cleanup:
Pages free: XXXXX
```

### If Build Still Fails

1. **Further reduce heap:**
   ```properties
   org.gradle.jvmargs=-Xmx10g -Xms4g
   ```

2. **Disable resource shrinking temporarily:**
   ```gradle
   shrinkResources false  // Keep minifyEnabled true
   ```

3. **Use local build instead:**
   ```bash
   flutter build appbundle --release
   ```

## Alternative: Local Build

If Codemagic continues to fail, build locally:

```bash
# Clean first
cd android && ./gradlew clean

# Build with optimized settings
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Advantages:**
- No memory limits
- Faster iteration
- Full R8 optimization possible

**Disadvantages:**
- Manual process
- Requires local keystore setup

## Rollback Instructions

If you need to revert to aggressive optimization:

1. **gradle.properties:**
   ```properties
   org.gradle.jvmargs=-Xmx24g
   android.enableR8.fullMode=true
   ```

2. **build.gradle:**
   ```gradle
   proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
   ```

3. **proguard-rules.pro:**
   ```
   -optimizationpasses 5
   ```

4. **Upgrade Codemagic instance:**
   - Use `mac_pro` (64GB RAM) instead of `mac_pro_m2` (32GB)
   - Note: Higher cost

## Conclusion

These optimizations balance:
- ✅ **Security:** Code obfuscation still enabled
- ✅ **Reliability:** Build should complete without OOM
- ✅ **Cost:** No need to upgrade Codemagic instance
- ⚠️ **Performance:** Slightly larger APK, acceptable trade-off

**Status:** Ready for production build 🚀

