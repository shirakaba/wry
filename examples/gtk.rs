use wry::{webview::WebViewBuilder, Result};

use cairo::*;
use gtk::*;

fn main() -> Result<()> {
    gtk::init()?;
    let window = Window::new(WindowType::Toplevel);

    if let Some(screen) = window.get_screen() {
        if let Some(visual) = screen.get_rgba_visual() {
            window.set_visual(Some(&visual));
        }
    }

    window.connect_draw(|_, cr| {
        cr.set_source_rgba(0., 0., 0., 0.);
        cr.set_operator(Operator::Source);
        cr.paint();
        cr.set_operator(Operator::Over);
        Inhibit(false)
    });

    window.set_app_paintable(true);
    window.show_all();
    // TODO add to webview
    /*
    let webview = WebViewBuilder::new(window)
        .unwrap()
        .initialize_script("menacing = 'ゴ';")
        .add_callback("world", |dispatcher, sequence, requests| {
            dispatcher.dispatch_script("console.log(menacing);")?;
            // Sequence is a number counting how many times this function being called.
            if sequence < 8 {
                println!("{} seconds has passed.", sequence);
            } else {
                // Requests is a vector of parameters passed from the caller.
                println!("{:?}", requests);
            }
            Ok(())
        })
        .load_url("https://tauri.studio")?
        .build()?;
    */

    gtk::main();
    Ok(())
}
