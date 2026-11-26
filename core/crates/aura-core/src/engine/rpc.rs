//! RPC / distributed inference support (feature-gated behind `rpc`).
//!
//! Enables distributing llama.cpp inference across multiple devices.
//! In production, this would use llama.cpp's RPC server/client:
//!   - Server: llama-server --rpc
//!   - Client: ggml-rpc
//!
//! This implementation provides a functional stub for RPC configuration.

use crate::error::{AuraError, AuraResult};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::io::{Read, Write};
use std::sync::{Arc, Mutex};
use std::thread;

/// RPC server configuration.
#[derive(Debug, Clone)]
pub struct RpcConfig {
    pub host: String,
    pub port: u16,
    pub num_workers: usize,
}

impl Default for RpcConfig {
    fn default() -> Self {
        Self {
            host: "127.0.0.1".into(),
            port: 8080,
            num_workers: 4,
        }
    }
}

/// RPC server for distributed inference.
pub struct RpcServer {
    config: RpcConfig,
    running: Arc<Mutex<bool>>,
    handle: Option<thread::JoinHandle<()>>,
}

impl RpcServer {
    pub fn new(config: RpcConfig) -> Self {
        Self {
            config,
            running: Arc::new(Mutex::new(false)),
            handle: None,
        }
    }

    /// Start the RPC server.
    pub fn start(&mut self) -> AuraResult<()> {
        let addr: SocketAddr = format!("{}:{}", self.config.host, self.config.port)
            .parse()
            .map_err(|e| AuraError::Invalid(format!("Invalid address: {}", e)))?;

        let listener = TcpListener::bind(addr)
            .map_err(|e| AuraError::Engine(format!("Failed to bind: {}", e)))?;

        let running = Arc::clone(&self.running);
        let mut running_guard = running.lock().unwrap();
        *running_guard = true;
        drop(running_guard);

        let handle = thread::spawn(move || {
            for stream in listener.incoming() {
                match stream {
                    Ok(stream) => {
                        // In production, handle RPC requests here
                        // For now, just accept and close
                        drop(stream);
                    }
                    Err(_) => break,
                }
            }
        });

        self.handle = Some(handle);
        Ok(())
    }

    /// Stop the RPC server.
    pub fn stop(&mut self) {
        let mut running = self.running.lock().unwrap();
        *running = false;
        drop(running);
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
    }
}

/// RPC client for connecting to remote inference servers.
pub struct RpcClient {
    remote_addr: String,
}

impl RpcClient {
    pub fn new(remote_addr: impl Into<String>) -> Self {
        Self {
            remote_addr: remote_addr.into(),
        }
    }

    /// Send a request to the remote server.
    pub fn request(&self, data: &[u8]) -> AuraResult<Vec<u8>> {
        let mut stream = TcpStream::connect(&self.remote_addr)
            .map_err(|e| AuraError::Engine(format!("Connection failed: {}", e)))?;

        stream
            .write_all(data)
            .map_err(|e| AuraError::Engine(format!("Write failed: {}", e)))?;

        let mut response = Vec::new();
        stream
            .read_to_end(&mut response)
            .map_err(|e| AuraError::Engine(format!("Read failed: {}", e)))?;

        Ok(response)
    }
}