use clap::Parser;
use pager::Pager;
use std::fmt;

fn main() -> gitig::Result<()> {
    let cli = Cli::parse();

    let templates = cli.template;
    let shell = cli.completion;
    let no_pager = cli.no_pager;
    let debug = cli.debug;

    handler(templates, shell, no_pager, debug)
}

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// Template(s) to include in the generated .gitignore file. If no templates are specified, display a list of all available templates.
    #[arg()]
    template: Vec<String>,

    /// Generate a completion file for the selected shell.
    #[clap(long, value_enum)]
    completion: Option<gitig::Shell>,

    /// Write template list to stdout. By default, this program attempts to paginate the list of available templates for easier reading.
    #[clap(long)]
    no_pager: bool,

    /// Increase program verbosity.
    #[clap(short, long)]
    debug: bool,
}

fn handler(
    templates: Vec<String>,
    shell: Option<gitig::Shell>,
    no_pager: bool,
    debug: bool,
) -> gitig::Result<()> {
    // If the user specified a shell, generate the completion file and exit
    if let Some(shell) = shell {
        return handle_completion(shell, debug);
    }
    // If no templates were specified, list all available templates
    if templates.is_empty() {
        return handle_list_templates(no_pager, debug);
    }
    // Otherwise, create a .gitignore file with the specified templates
    handle_create(templates, debug)
}

fn handle_completion(shell: gitig::Shell, debug: bool) -> gitig::Result<()> {
    match shell.generate_completion_str() {
        Ok(completion_str) => println!("{}", completion_str),
        Err(e) => match e {
            gitig::Error::ApplicationError(_) => eprintln!("{}", e),
            _ => log_err(gitig::Error::GENERIC_MSG, e, debug),
        },
    }
    Ok(())
}

fn handle_list_templates(no_pager: bool, debug: bool) -> gitig::Result<()> {
    if !no_pager {
        Pager::new().setup();
    }
    match gitig::list_templates() {
        Ok(templates) => println!("{}", templates.join("\n")),
        Err(e) => log_err(gitig::Error::FETCH_TEMPLATE_FAILED_MSG, e, debug),
    }
    Ok(())
}

fn handle_create(templates: Vec<String>, debug: bool) -> gitig::Result<()> {
    let templates = templates.iter().map(|t| t.as_str());
    match gitig::create(templates) {
        Ok(text) => println!("{}", text),
        Err(e) => match e {
            gitig::Error::TemplateNotFound(_) => {
                eprintln!("{}", e);
                eprintln!("Run `gi` (without arguments) for a list of templates.");
            }
            gitig::Error::ApplicationError(_) => eprintln!("{}", e),
            _ => log_err(gitig::Error::GENERIC_MSG, e, debug),
        },
    }
    Ok(())
}

fn log_err<E: fmt::Debug>(msg: &str, e: E, debug: bool) {
    if debug {
        eprintln!("{:?}\n\n{}", e, msg);
    } else {
        eprintln!("{}", msg);
    }
}
