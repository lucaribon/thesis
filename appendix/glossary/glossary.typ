#let gloss(body) = {
  link("https://codehex16.github.io/glossario#" + toIdCase(body.text))[#text(
    blue,
    size: 12pt,
    font: "Noto Sans",
  )[#underline[#body]\*]]
}