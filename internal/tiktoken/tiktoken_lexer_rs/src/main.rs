#![allow(unused)]

use fancy_regex::Regex;
use serde::{Deserialize, Serialize};
use std::fs;

const R50K_PAT_STR: &'static str =
    r###"'(?:[sdmt]|ll|ve|re)| ?\p{L}++| ?\p{N}++| ?[^\s\p{L}\p{N}]++|\s++$|\s+(?!\S)|\s"###;

const O200K_BASE_PAT_STR: &'static str = concat!(
    r###"[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]*[\p{Ll}\p{Lm}\p{Lo}\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?"###,
    "|",
    r###"[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]+[\p{Ll}\p{Lm}\p{Lo}\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?"###,
    "|",
    r###"\p{N}{1,3}"###,
    "|",
    r###" ?[^\s\p{L}\p{N}]+[\r\n/]*"###,
    "|",
    r###"\s*[\r\n]+"###,
    "|",
    r###"\s+(?!\S)"###,
    "|",
    r###"\s+"###,
);

const CL100K_BASE_PAT_STR: &'static str = r###"'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}++|\p{N}{1,3}+| ?[^\s\p{L}\p{N}]++[\r\n]*+|\s++$|\s*[\r\n]|\s+(?!\S)|\s"###;

fn tokenize(regex: &Regex, text: &str) -> Vec<String> {
    let mut result = Vec::new();
    for mat in regex.find_iter(text) {
        let piece = mat.unwrap().as_str();
        result.push(piece.to_string());
    }
    result
}
#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
struct LexerResult {
    text: String,
    pieces: Vec<String>,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
struct SnapshotData {
    data: Vec<LexerResult>,
}

fn test_cl100k_base_fancy_regex(snapshot: &SnapshotData) {
    let regex = Regex::new(CL100K_BASE_PAT_STR).unwrap();
    for expected in &snapshot.data {
        let actual_tokens = tokenize(&regex, &expected.text);
        let actual = LexerResult {
            text: expected.text.clone(),
            pieces: actual_tokens,
        };
        similar_asserts::assert_eq!(expected, &actual);
    }
}

fn test_r50k_fancy_regex(snapshot: &SnapshotData) {
    let regex = Regex::new(R50K_PAT_STR).unwrap();
    for expected in &snapshot.data {
        let actual_tokens = tokenize(&regex, &expected.text);
        let actual = LexerResult {
            text: expected.text.clone(),
            pieces: actual_tokens,
        };
        similar_asserts::assert_eq!(expected, &actual);
    }
}

fn main() {
    let snapshot_path = "../__snapshot__/cl100k_base.json";
    let snapshot_str = fs::read_to_string(snapshot_path).unwrap();
    let expected: SnapshotData = serde_json::from_str(&snapshot_str).unwrap();
    test_cl100k_base_fancy_regex(&expected);

    let snapshot_path = "../__snapshot__/r50k.json";
    let snapshot_str = fs::read_to_string(snapshot_path).unwrap();
    let expected: SnapshotData = serde_json::from_str(&snapshot_str).unwrap();
    test_r50k_fancy_regex(&expected);
}
