trait NotDynCompatible: Send + Sync {
    fn name(&self) -> String;
    fn pick<T>(&self, value: T) -> T;
}

struct A;

impl NotDynCompatible for A {
    fn name(&self) -> String { "a".into() }
    fn pick<T>(&self, value: T) -> T { value }
}

fn main() {
    let erased: std::sync::Arc<dyn NotDynCompatible> = std::sync::Arc::new(A);
    assert_eq!(erased.name(), "a");
}
