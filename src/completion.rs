use clap::ValueEnum;
use std::{fmt::Display, str};

use crate::client;
use crate::error::Result;

#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub enum Shell {
    Bash,
    Fish,
    // IMPORTANT: If you add a new shell, make sure to update
    //            the `iter` function below (+ update match statements)
}

impl Shell {
    pub fn generate_completion_str(&self) -> Result<String> {
        match self {
            Shell::Bash => bash_completion(),
            Shell::Fish => fish_completion(),
        }
    }

    pub fn iter() -> impl Iterator<Item = String> {
        [Shell::Bash, Shell::Fish] // NOTE: Update this if you add a new shell
            .iter()
            .map(|s| s.to_string().to_lowercase())
    }
}

impl Display for Shell {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let s = match self {
            Shell::Bash => "Bash",
            Shell::Fish => "Fish",
        };
        write!(f, "{}", s)
    }
}

pub fn bash_completion() -> Result<String> {
    client::list_templates().map(|all_templates| {
        BASH_COMPLETION_TEMPLATE.replace("{all_templates}", &all_templates.join(" "))
    })
}

pub fn fish_completion() -> Result<String> {
    client::list_templates().map(|all_templates| {
        let all_shells = Shell::iter().collect::<Vec<String>>();
        FISH_COMPLETION_TEMPLATE
            .replace("{all_templates}", &all_templates.join(" "))
            .replace("{all_shells}", &all_shells.join(" "))
    })
}

const BASH_COMPLETION_TEMPLATE: &str = "\
#!/usr/bin/env bash
complete -W \"{all_templates}\" gi
";

const FISH_COMPLETION_TEMPLATE: &str = "\
complete -c gi -f
complete -c gi -a '{all_templates}'
complete -c gi -s h -l help -d 'Print a short help text and exit'
complete -c gi -s v -l version -d 'Print a short version string and exit'
complete -c gi -l no-pager -d 'Do not pipe output into a pager'
complete -c gi -l completion -a '{all_shells}' -d 'Generate shell completion file'
";
