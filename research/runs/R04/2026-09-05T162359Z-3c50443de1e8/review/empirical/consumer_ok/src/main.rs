use surface_demo::Widget;

fn main() {
    let w = Widget::new(7);
    println!("consumer_ok: root-path import works, id={}", w.id());
}
