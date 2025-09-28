## Utilizzo

Per compilare tramite Typst è necessario installarlo (`pacman -S typst` su Arch) oppure utilizzare l'[editor online](https://typst.app/).

Durante la scrittura è molto comodo utilizzare la funzione `watch` di Typst che aggiorna il PDF ad ogni modifica.

Struttura del template:

- `chapters/`: qui vanno inseriti i capitoli con l'effettivo contenuto della tesi.
- `appendix/`: contiene capitoli aggiuntivi, bibliografia e glossario
  - `bibliography/`: contiene i file per la bibliografia
    - `bibliography.bib`: file per la bibliografia in formato BibTeX
    - `bibliography.yml`: file per la bibliografia in formato Hayagriva
    - `bibliography.typ`: file incluso nella struttura dove viene selezionato il formato della bibliografia da utilizzare
- `config/`: le varie configurazioni del template:
  - `variables.typ`: qui vengono definite le variabili con i propri dati personali.
- `images/`: tutte le immagini e simili raccolte qui per avere un po' di ordine.
- `preface/`: contiene la struttura delle pagine che precedono il vero contenuto:
  - `acknowledgements.typ`: ringraziamenti vari.
  - `dedication.typ`: dediche e una piccola citazione.
  - `summary.typ`: sommario in cui viene descritto di cosa tratta la tesi.
- `structure.typ`: contiene la struttura e l'ordine dei capitoli.
- `thesis.typ`: vera e propria tesi, file che andrà compilato per produrre il PDF.

## Fonti e utilità

- [Documentazione Typst](https://typst.app/docs/)
- [FIUP Code of Conduct](https://github.com/FIUP/Getting_Started/blob/master/CODE_OF_CONDUCT.md)
