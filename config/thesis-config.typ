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

    show link: it => {
        underline(it)
    }

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
            } else {
                text(size: 1.3em)[#it.body]
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

#let _usecase_value(v) = {
    if type(v) == dictionary {
        let gloss_body = v.at("body", default: none)
        let gloss_target = v.at("target", default: none)
        let parts = v.at("parts", default: none)

        if gloss_body != none and gloss_target != none {
            link(gloss_target)[#gloss_body#sub[\G]]
        } else if type(parts) == array {
            [#for part in parts { _usecase_value(part) }]
        } else {
            v
        }
    } else if type(v) == array {
        if v.len() == 0 {
            "—"
        } else if v.all(item => type(item) == str) {
            let src = v.map(item => "- " + item).join("\n")
            eval(src, mode: "markup")
        } else {
            // Fallback for non-string items.
            list(
                tight: true,
                ..v.map(item => [#_usecase_value(item)]),
            )
        }
    } else {
        v
    }
}

#let useCase(useCaseDetails) = {
    if useCaseDetails.name != none and useCaseDetails.name != "" {
        heading(level: 3, numbering: none)[UC#useCaseDetails.number: #useCaseDetails.name]
    }

    let rows = for (k, v) in useCaseDetails {
        if k != "number" and k != "name" {
            let label = k.replace("_", " ")
            let label_clusters = label.clusters()
            let label_head = label_clusters.at(0)
            let label_tail = label_clusters.slice(1).join("")
            (
                text(
                    [
                        #upper(label_head)#label_tail
                    ],
                    weight: "bold",
                ),
                _usecase_value(v),
            )
        }
    }

    {
        set par(justify: false)
        table(
            inset: (x: 0pt, y: 5pt),
            stroke: none,
            columns: (0.4fr, 1fr),
            row-gutter: 0.35em,
            ..rows,
        )
    }
}

#let gloss(body, target) = link(target)[#body#sub[\G]]

