mod app;
mod config;
mod ipc;
mod model;
mod services;
mod ui;

#[tokio::main]
async fn main() {
    app::run().await;
}
