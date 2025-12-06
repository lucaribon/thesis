#import "../config/constants.typ": chapter
#let config(
    myAuthor: "Luca Ribon",
    myTitle: "Titolo",
    myLang: "it",
    myNumbering: "1.",
    body,
) = {
    // Set the document's basic properties.
    set document(author: myAuthor, title: myTitle)
    show math.equation: set text(weight: 400)

    show link: it => underline(it.body)

    // LaTeX look (secondo la doc di Typst)
    set page(margin: 1.5in, numbering: myNumbering, number-align: center)
    // set par(leading: 0.55em, first-line-indent: 1.8em, justify: true)
    set par(
        // first-line-indent: 1.8em,
        leading: 0.55em,
        spacing: 1.5em,
        justify: true,
    )
    set text(font: "New Computer Modern", size: 10pt, lang: myLang)
    set heading(numbering: myNumbering)
    show raw: set text(font: "New Computer Modern Mono", size: 10pt, lang: myLang)
    //show par: set block(spacing: 0.55em)
    // set par(spacing: 0.55em)
    show heading: set block(above: 1.4em, below: 1em)


    show heading.where(level: 1): it => {
        stack(
            spacing: 2em,
            if it.numbering != none {
                text(size: 1.5em)[#chapter #counter(heading).display()]
            },
            text(size: 2.1em, hyphenate: false, it.body),
            v(0.5em),
        )
    }

    show heading.where(level: 2): it => {
        stack(
            if it.numbering != none {
                text(size: 1.4em)[#counter(heading).display() #it.body]
            },
        )
    }

    show heading.where(level: 3): it => {
        stack(
            if it.numbering != none {
                text(size: 1.3em)[#counter(heading).display() #it.body]
            },
        )
    }

    show heading.where(level: 4): it => {
        stack(
            if it.numbering != none {
                text(size: 1.15em)[#counter(heading).display() #it.body]
            },
        )
    }

    body
}

#let useCase(useCaseDetails) = {
    let n = 1
    if useCaseDetails.number != "" and useCaseDetails.name != "" {
        text(12pt, [ *UC#useCaseDetails.number: #useCaseDetails.name* ])
    }
    let result = for (k, v) in useCaseDetails {
        if k != "number" and k != "name" {
            (text(k, weight: "bold"), v)
        }
        n = n + 1
    }
    table(
        inset: 8pt,
        stroke: none,
        columns: 2,
        ..result
    )
}

#let gloss(body, label-name: none) = {
    let target = if label-name != none { label-name } else { "glossary-" + body }
    show link: it => it.body
    link(label(target))[
        #text(blue)[#underline[#body]#sub[\G]]
    ]
}
