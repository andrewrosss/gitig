use std::str;

use crate::error::Error;
use crate::error::Result;

const API_URL: &str = "https://www.toptal.com/developers/gitignore/api";

pub fn list_templates() -> Result<Vec<String>> {
    get(&list_endpoint())
        .and_then(|res| res.text())
        .map_err(|_| Error::fetch_templates_failed())
        .map(|content| {
            content
                .lines()
                .filter(|l| !l.is_empty())
                .flat_map(|l| l.split(',').map(|t| t.to_owned()))
                .collect::<Vec<String>>()
        })
}

pub fn create<'a, I>(templates: I) -> Result<String>
where
    I: IntoIterator<Item = &'a str>,
{
    let templates = templates
        .into_iter()
        .map(|t| t.to_owned())
        .collect::<Vec<String>>();
    let res = get(&create_endpoint(&templates))?;
    if res.status().is_client_error() || res.status().is_server_error() {
        return match res.status() {
            reqwest::StatusCode::NOT_FOUND => handle_404(&templates),
            _ => Err(Error::generic()),
        };
    }
    Ok(res.text()?)
}

fn list_endpoint() -> String {
    format!("{}/list", API_URL)
}

fn create_endpoint(templates: &[String]) -> String {
    let templates_str = templates.join(",");
    format!("{}/{}", API_URL, templates_str)
}

fn get(url: &str) -> reqwest::Result<reqwest::blocking::Response> {
    let client = reqwest::blocking::ClientBuilder::new()
        .user_agent("Mozilla/5.0")
        .build()?;
    client.get(url).send()
}

fn handle_404(templates: &[String]) -> Result<String> {
    // try to provide the user with a helpful error message
    let Ok(known_templates) = list_templates() else {
        return Err(Error::generic());
    };
    let unknown_templates = find_unknown_templates(&known_templates, templates);
    let err = if !unknown_templates.is_empty() {
        Error::TemplateNotFound(unknown_templates)
    } else {
        Error::generic()
    };
    Err(err)
}

fn find_unknown_templates(known_templates: &[String], templates: &[String]) -> Vec<String> {
    // We could convert to HashSets and do a difference, but that would require
    // cloning the known_templates Vec. And since templates is likely < 10, it's
    // probably faster to just iterate over it.
    templates
        .iter()
        .filter(|t| !known_templates.contains(t))
        .map(|t| (*t).to_owned())
        .collect::<Vec<String>>()
}
