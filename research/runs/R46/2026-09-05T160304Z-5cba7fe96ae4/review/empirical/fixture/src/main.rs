//! R46 fixture CLI binary: prints the license expression it was compiled with.

fn main() {
    println!("{}", r46_fixture::license_expression());
}
