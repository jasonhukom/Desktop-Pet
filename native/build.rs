fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    println!("cargo:rerun-if-changed=app.rc");
    println!("cargo:rerun-if-env-changed=CXX");
    println!("cargo:rerun-if-env-changed=WINDRES");
    println!("cargo:rerun-if-changed=../assets/github.ico");
    println!("cargo:rerun-if-changed=../assets/github-dark.ico");
    println!("cargo:rerun-if-changed=audio_probe.cpp");

    let is_msvc = std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("msvc");
    let out_dir = std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap());

    if is_msvc {
        let audio = out_dir.join("audio-probe.obj");
        let cached_audio = std::path::Path::new("cached/audio-probe.obj");
        let compile_audio = std::process::Command::new("cl.exe")
            .args(["/nologo", "/c", "/O2", "/GR-", "/EHs-c-", "audio_probe.cpp"])
            .arg(format!("/Fo:{}", audio.display()))
            .status();
        if compile_audio.as_ref().map(|s| s.success()).unwrap_or(false) {
            // Compiled successfully
        } else if cached_audio.exists() {
            std::fs::copy(cached_audio, &audio).expect("failed to copy cached audio-probe.obj");
        } else {
            panic!("cl.exe required or cached/audio-probe.obj missing");
        }
        println!("cargo:rustc-link-arg={}", audio.display());
        println!("cargo:rustc-link-lib=ole32");
        println!("cargo:rustc-link-lib=uuid");
        println!("cargo:rerun-if-changed=app.manifest");
        println!("cargo:rerun-if-changed=../assets/icon.ico");
        let out = out_dir.join("app-res.res");
        let cached_res = std::path::Path::new("cached/app-res.res");
        let compile_rc = std::process::Command::new("rc.exe")
            .args(["/nologo", "/fo"])
            .arg(&out)
            .arg("app.rc")
            .status();
        if compile_rc.as_ref().map(|s| s.success()).unwrap_or(false) {
            // Compiled successfully
        } else if cached_res.exists() {
            std::fs::copy(cached_res, &out).expect("failed to copy cached app-res.res");
        } else {
            panic!("rc.exe required or cached/app-res.res missing");
        }
        println!("cargo:rustc-link-arg={}", out.display());
    } else {
        let audio = out_dir.join("audio-probe.o");
        let status = std::process::Command::new(std::env::var("CXX").unwrap_or_else(|_| "clang++".into()))
            .args(["-c", "-O2", "-fno-exceptions", "-fno-rtti", "audio_probe.cpp", "-o"])
            .arg(&audio)
            .status()
            .expect("clang++ required");
        assert!(status.success());
        println!("cargo:rerun-if-changed=app.manifest");
        println!("cargo:rerun-if-changed=../assets/icon.ico");
        let out = out_dir.join("app-res.o");
        let status = std::process::Command::new(std::env::var("WINDRES").unwrap_or_else(|_| "windres".into()))
            .args(["--codepage=65001", "-i", "app.rc", "-O", "coff", "-o"])
            .arg(&out)
            .status()
            .expect("windres required");
        assert!(status.success());
        println!("cargo:rustc-link-arg={}", audio.display());
        println!("cargo:rustc-link-arg={}", out.display());
        println!("cargo:rustc-link-arg=-lole32");
        println!("cargo:rustc-link-arg=-luuid");
        println!("cargo:rustc-link-arg=-lmsvcrt");
    }
}
