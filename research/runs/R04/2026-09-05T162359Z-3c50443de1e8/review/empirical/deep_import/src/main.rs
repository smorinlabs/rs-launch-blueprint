// Negative fixture: a consumer that names a private implementation module.
// This must NOT compile; success means the curated surface leaked.
fn main() {
    let w = surface_demo::internal::Widget::new(1);
    println!("{}", w.id());
}
