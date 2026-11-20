use std::process::Command;

pub(crate) fn run_detached(program: &str, args: &[&str]) {
    if let Err(error) = Command::new(program).args(args).spawn() {
        eprintln!("Could not run {program}: {error}");
    }
}
