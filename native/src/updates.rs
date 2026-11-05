use super::*;

// Stable two- or three-part release versions only. Unknown/special-edition/prerelease
// tags never become an update suggestion through an accidental lexical compare.
fn stable_version(tag:&str)->Option<[u32;3]> {
    let tag=tag.strip_prefix('v').or_else(||tag.strip_prefix('V')).unwrap_or(tag);
    let parts:Vec<_>=tag.split('.').collect();
    if parts.len()<2 || parts.len()>3 {return None;}
    let mut result=[0;3];
    for (i,part) in parts.iter().enumerate() {
        if part.is_empty() || !part.bytes().all(|c|c.is_ascii_digit()) {return None;}
        result[i]=part.parse().ok()?;
    }
    Some(result)
}
fn release_comparison(remote:&str,current:&str)->String {
    match (stable_version(remote),stable_version(current)) {
        (Some(r),Some(c)) if r>c=>"A newer release is available.".into(),
        (Some(r),Some(c)) if r==c=>"You are using the latest release. No newer version available.".into(),
        (Some(_),Some(_))=>"This release is older than the current version. No newer version available.".into(),
        _=>"Cannot verify version order; not recognized as a new release.".into(),
    }
}
impl App {
    pub(super) unsafe fn open_github(&self, releases: bool) {
        let url = if releases { "https://github.com/jasonhukom/Desktop-Pet/releases" } else { "https://github.com/jasonhukom/Desktop-Pet" };
        ShellExecuteW(self.panel, wide("open").as_ptr(), wide(url).as_ptr(), null(), null(), SW_SHOWNORMAL);
    }
    pub(super) unsafe fn check_update(&mut self) {
        if self.update_check.is_some() { return; }
        let (tx,rx) = std::sync::mpsc::channel();
        self.update_check = Some(rx);
        self.update_button(false);
        std::thread::spawn(move || {
            let result = (|| {
                let bytes = online::get("api.github.com", "/repos/jasonhukom/Desktop-Pet/releases/latest", 256*1024)?;
                let v: serde_json::Value = serde_json::from_slice(&bytes).map_err(|e| e.to_string())?;
                if v["draft"].as_bool()!=Some(false) || v["prerelease"].as_bool()!=Some(false) { return Err("No stable release".into()); }
                let tag=v["tag_name"].as_str().ok_or("Missing version")?;
                if tag.len()>64 {return Err("Invalid version".into());}
                Ok(tag.to_owned())
            })();
            let _ = tx.send(result);
        });
    }
    unsafe fn update_button(&self, enabled: bool) {
        if let Some((_,h))=self.controls.iter().find(|x|x.0==170) {
            EnableWindow(*h,enabled as i32);
            SetWindowTextW(*h,wide(if enabled {"Check Updates"} else {"Checking…"}).as_ptr());
        }
    }
    pub(super) unsafe fn poll_update(&mut self) {
        let Some(rx)=self.update_check.as_ref() else {return;};
        let result=match rx.try_recv() {
            Ok(v)=>v,
            Err(std::sync::mpsc::TryRecvError::Empty)=>return,
            Err(_)=>Err("Disconnected".into()),
        };
        self.update_check=None;
        self.update_button(true);
        match result {
            Ok(tag)=>{
                let comparison=release_comparison(&tag,VERSION);
                let message=format!("Latest release: {tag}\nCurrent version: v{VERSION}.\n{comparison}\n\nOpen GitHub release page?");
                if MessageBoxW(self.panel,wide(&message).as_ptr(),wide("Check Updates").as_ptr(),MB_YESNO|MB_ICONINFORMATION)==IDYES { self.open_github(true); }
            }
            Err(_)=>{MessageBoxW(self.panel,wide("Unable to reach GitHub Q_Q").as_ptr(),wide("Check Updates").as_ptr(),MB_OK|MB_ICONINFORMATION);}
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn numeric_versions_never_offer_older_or_equal_releases() {
        for tag in ["v2.4.12","v2.4.9","2.3.99","2.4.13"] {
            assert!(release_comparison(tag,"2.4.13").contains("No newer version"));
        }
        assert_eq!(stable_version("v2.5"),stable_version("v2.5.0"));
        assert!(stable_version("v2.4.10")>stable_version("v2.4.9"));
        assert!(release_comparison("v2.4.14","2.4.13").contains("newer release"));
        assert!(release_comparison("v2.5.0","2.4.99").contains("newer release"));
    }
    #[test]
    fn unknown_and_special_edition_tags_are_not_updates() {
        for tag in ["v2.4.14-beta","v2.4.14-blockbench","latest","v2","v2.4.13.1","v2.4.-1","v2.4.4294967296"] {
            assert!(stable_version(tag).is_none());
            assert!(release_comparison(tag,"2.4.13").contains("not recognized as a new release"));
        }
    }
}
