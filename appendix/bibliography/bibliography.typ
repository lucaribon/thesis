#pagebreak()
#set page(numbering: none)

#v(1fr)

#pagebreak()
#counter(page).update(n => n - 1)
#set page(numbering: "1.")

// Hayagriva format
#bibliography("bibliography.yml")

// Biblatex
// #bibliography("bibliography.bib")