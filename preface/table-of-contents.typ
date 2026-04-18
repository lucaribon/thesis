#import "../config/constants.typ": figuresList, tablesList

#pagebreak()
#set page(numbering: none)

#v(1fr)

#pagebreak()
#counter(page).update(n => n - 1)
#set page(numbering: "i")
#show link: it => it.body

#[
  #show outline.entry.where(level: 1): it => {
    linebreak()
    link(it.element.location(), strong(it))
//    h(1fr)
  }
  #outline(
    indent: auto,
    depth: 5
  )
]

#outline(
  title: figuresList,
  target: figure.where(kind: image)
)

#pagebreak()
#set page(numbering: none)

#v(1fr)

#pagebreak()
#counter(page).update(n => n - 1)
#set page(numbering: "i")

#outline(
    title: tablesList,
    target: figure.where(kind: table),
    indent: auto
)
