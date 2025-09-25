// Non su primo capitolo
//#pagebreak(to:"odd")

= Introduzione // 2 pagine 
Introduzione al contesto applicativo.

// TODO: aggiungere riferimenti a:
// Termine nel glossario
// Citazione in linea
// Citazione nel pie' di pagina

Al momento glossario e citazioni devo ancora capirli.

== Organizzazione del testo

#set par(first-line-indent: 0pt)
/ #link(<cap:descrizione-stage>)[Il secondo capitolo]: descrive.
/ #link(<cap:analisi-requisiti>)[Il terzo capitolo]: descrive.
/ #link(<cap:introduzione-teorica>)[Il quarto capitolo]: descrive.
/ #link(<cap:descrizione-lavoro-svolto>)[Il quint capitolo]: descrive.
/ #link(<cap:conclusioni>)[Il sesto capitolo]: descrive.

Riguardo la stesura del testo, relativamente al documento sono state adottate le seguenti convenzioni tipografiche:

- gli acronimi, le abbreviazioni e i termini ambigui o di uso non comune menzionati vengono definiti nel glossario, situato alla fine del presente documento;
- per la prima occorrenza dei termini riportati nel glossario viene utilizzata la seguente nomenclatura: _parola_ (glsfirstoccur);
- i termini in lingua straniera o facenti parti del gergo tecnico sono evidenziati con il carattere _corsivo_.

La bibliografia è gestita nel file `bibliography.typ` con il nuovo formato Hayagriva, ma si può utilizzare il formato Bibtex. Per citare un elemento in bibliografia basta usare una semplice citazione `@citazione`, ad esempio per citare *il miglior libro di sempre* @p1 basta usare `@p1`.

== L'azienda

Descrizione dell'azienda.

== Il progetto

Introduzione allo scopo dello stage e la motivazione per cui l'avete scelto (il vostro interesse per la materia o l'argomento trattato, ecc.).
