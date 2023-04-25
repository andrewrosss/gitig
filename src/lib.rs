pub mod client;
pub mod completion;
pub mod error;

pub use client::create;
pub use client::list_templates;
pub use completion::bash_completion;
pub use completion::fish_completion;
pub use completion::Shell;
pub use error::Error;
pub use error::Result;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
