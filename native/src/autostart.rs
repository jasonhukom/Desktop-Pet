//! Autostart with Windows login.
//!
//! Writes to current user's HKCU\Software\Microsoft\Windows\CurrentVersion\Run,
//! requiring no administrator privileges or startup folder shortcuts. The registry stores
//! "executable + --autostart", so if moved or renamed, the next launch will
//! automatically rewrite the new path via sync.
use std::path::{Path, PathBuf};

pub const RUN_KEY: &str = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
pub const RUN_VALUE: &str = "MinecraftDesktopPet";

fn wide(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

fn default_dir() -> Option<PathBuf> {
    std::env::var_os("APPDATA").map(|p| PathBuf::from(p).join("minecraft-desktop-pet"))
}

/// Command line executed at login: `"exe" --autostart [--user-data-dir="..."]`.
///
/// Appends --user-data-dir only when a non-default directory was specified,
/// avoiding reading a different settings folder. Quoted for spaces.
pub fn command_line(user_dir: &Path) -> String {
    let exe = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("Minecraft Desktop Pet.exe"));
    let mut line = format!("\"{}\" --autostart", exe.display());
    if default_dir().as_deref() != Some(user_dir) {
        line.push_str(&format!(" --user-data-dir=\"{}\"", user_dir.display()));
    }
    line
}

#[cfg(windows)]
mod win {
    use super::*;
    use std::ptr::{null, null_mut};
    use windows_sys::Win32::{
        Foundation::ERROR_SUCCESS,
        System::Registry::{
            RegCloseKey, RegCreateKeyExW, RegDeleteValueW, RegQueryValueExW, RegSetValueExW, HKEY,
            HKEY_CURRENT_USER, KEY_QUERY_VALUE, KEY_SET_VALUE, REG_OPTION_NON_VOLATILE, REG_SZ,
        },
    };

    const ERROR_FILE_NOT_FOUND: u32 = 2;

    unsafe fn open_key(write: bool) -> Result<HKEY, String> {
        let mut key: HKEY = null_mut();
        let mut disposition = 0u32;
        let access = if write {
            KEY_SET_VALUE | KEY_QUERY_VALUE
        } else {
            KEY_QUERY_VALUE
        };
        let rc = RegCreateKeyExW(
            HKEY_CURRENT_USER,
            wide(RUN_KEY).as_ptr(),
            0,
            null(),
            REG_OPTION_NON_VOLATILE,
            access,
            null(),
            &mut key,
            &mut disposition,
        );
        if rc != ERROR_SUCCESS {
            return Err(format!("Failed to open autostart registry key (error {rc})"));
        }
        Ok(key)
    }

    /// Whether the autostart entry exists in the registry.
    pub fn is_registered() -> bool {
        unsafe {
            let Ok(key) = open_key(false) else {
                return false;
            };
            let rc = RegQueryValueExW(
                key,
                wide(RUN_VALUE).as_ptr(),
                null(),
                null_mut(),
                null_mut(),
                null_mut(),
            );
            RegCloseKey(key);
            rc == ERROR_SUCCESS
        }
    }

    /// Write or delete the autostart entry. If enabled, always rewrites current path.
    pub fn set_enabled(enabled: bool, user_dir: &Path) -> Result<(), String> {
        unsafe {
            let key = open_key(true)?;
            let result = if enabled {
                let data: Vec<u16> = command_line(user_dir)
                    .encode_utf16()
                    .chain(std::iter::once(0))
                    .collect();
                let rc = RegSetValueExW(
                    key,
                    wide(RUN_VALUE).as_ptr(),
                    0,
                    REG_SZ,
                    data.as_ptr() as *const u8,
                    (data.len() * 2) as u32,
                );
                if rc == ERROR_SUCCESS {
                    Ok(())
                } else {
                    Err(format!("Failed to enable autostart (error {rc})"))
                }
            } else {
                let rc = RegDeleteValueW(key, wide(RUN_VALUE).as_ptr());
                if rc == ERROR_SUCCESS || rc == ERROR_FILE_NOT_FOUND {
                    Ok(())
                } else {
                    Err(format!("Failed to disable autostart (error {rc})"))
                }
            };
            RegCloseKey(key);
            result
        }
    }

    /// Synchronize registry at startup: refresh if enabled, clean old entry if disabled.
    pub fn sync(enabled: bool, user_dir: &Path) {
        if enabled {
            let _ = set_enabled(true, user_dir);
        } else if is_registered() {
            let _ = set_enabled(false, user_dir);
        }
    }
}

#[cfg(windows)]
pub use win::{set_enabled, sync};
