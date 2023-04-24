use std::error;
use std::{fmt, io};

#[derive(Debug)]
pub enum Error {
    Io(io::Error),
    Reqwest(reqwest::Error),
    TemplateNotFound(Vec<String>),
    ApplicationError(String),
}

impl Error {
    pub const GENERIC_MSG: &str = "Failed to create .gitignore file";
    pub const FETCH_TEMPLATE_FAILED_MSG: &str = "Failed to fetch templates";

    pub fn generic() -> Self {
        Error::ApplicationError(Self::GENERIC_MSG.to_owned())
    }

    pub fn fetch_templates_failed() -> Self {
        Error::ApplicationError(Self::FETCH_TEMPLATE_FAILED_MSG.to_owned())
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Error::Io(e) => write!(f, "IO error: {}", e),
            Error::Reqwest(e) => write!(f, "Reqwest error: {}", e),
            Error::TemplateNotFound(t) => write!(f, "Template(s) not found: {}", t.join(", ")),
            Error::ApplicationError(msg) => write!(f, "Application error: {}", msg),
        }
    }
}

impl error::Error for Error {
    fn source(&self) -> Option<&(dyn error::Error + 'static)> {
        match self {
            Error::Io(e) => Some(e),
            Error::Reqwest(e) => Some(e),
            Error::TemplateNotFound(_) => None,
            Error::ApplicationError(_) => None,
        }
    }
}

impl From<io::Error> for Error {
    fn from(e: io::Error) -> Self {
        Error::Io(e)
    }
}

impl From<reqwest::Error> for Error {
    fn from(e: reqwest::Error) -> Self {
        Error::Reqwest(e)
    }
}

pub type Result<T> = std::result::Result<T, Error>;
