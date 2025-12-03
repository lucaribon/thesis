#pagebreak(to: "odd")

= Descrizione dello stage // 2 pagine
<cap:descrizione-stage>

== Contesto aziendale <sez:contesto-aziendale>
Lo stage si è svolto in presenza presso la sede di Vicenza di KanbanBOX S.r.l.\
Sono stato inserito nel team sviluppatori software con il quale ho, fin da subito, partecipato a tutte le attività di routine previste, le più rilevanti sono:
- *daily stand-up meeting*: riunione giornaliera di circa 15 minuti in cui ogni membro del team condivide lo stato di avanzamento del proprio lavoro, le difficoltà incontrate e gli obiettivi per la giornata;
// TODO: chiedere se pivetta è effettivamente un consulente esterno
- *Dev+ weekly*: riunione settimanale del team di sviluppo a cui partecipa anche un consulente esterno, con esperienza rilevante nel mondo PHP open source, con cui si affrontano i problemi più ostici e si analizzano approfonditamente potenziali soluzioni;
- *Analisi issue Sentry*: riunione settimanale tra tutti i membri del team in cui si analizza il report delle issue tracciate da Sentry, uno strumento di monitoraggio degli errori in produzione; l'obbiettivo dell'incontro è quello di identificare i bug più critici e frequenti e di assegnarli ai membri del team per la risoluzione.

Per tutta la durata dello stage ho avuto a disposizione il supporto del mio tutor aziendale, il quale mi ha guidato nell'inserimento all'interno del team e del prodotto KanbanBOX su cui ho lavorato. \
Inoltre, ho avuto modo di collaborare anche con altri membri del team per discutere con chi aveva maggiore esperienza in merito agli argomenti o alle tecnologie con cui ero meno familiare.


== Metodo di lavoro

=== Metodologia Agile e Scrum???
// TODO: chiedere a matteo se gli okr ha senso nominarli qui? sono legati a degli """sprint""" o non esiste nulla del genere; in più chiedere se ci sono altri aspetti rilevanti del metodo di lavoro
// TODO: aggiungere loghi

=== Git e GitHub
Per il *versionamento* di tutta la codebase e la documentazione di KanbanBOX viene utilizzato *Git*, un sistema di controllo di versione distribuito.

I repository Git sono ospitati su *GitHub*, una piattaforma di hosting per progetti software che fornisce funzionalità aggiuntive usate dal team di KanbanBox come la gestione delle issue, le pull request con relative verifiche del codice e l'integrazione continua.

Nel repository di KanbanBOX, ovvero quello contentente tutta la codebase del prodotto, viene usato il flusso di lavoro *Git Flow*, che prevede l'utilizzo di due rami principali, `master` e `development`. \
In `master` viene mantenuta sempre la versione stabile e in produzione, mentre in `development` viene costruito lo _snapshot_ della prossima _release_.
In aggiunta a questi due rami principali, ne esistono altri con scopi specifici che seguono la seguente nomenclatura:
- `feature/nome-feature`: rami usati per lo sviluppo di nuove funzionalità;
- `fix/nome-fix`: rami usati per la risoluzione di bug;
- `hotfix/nome-hotfix`: rami usati per la correzione di bug critici in produzione;
- `chore/nome-chore`: rami usati per attività di manutenzione o che in generale non apportano modifiche percebili dall'utente finale (aggiornamenti di librerie, configurazioni, implementazione di funzionalità esistenti che non prevedono risoluzione di bug).

Quando lo scopo di un ramo viene assolto interamente, viene aperta una *pull request* su GitHub per richiedere la revisione e l'integrazione delle modifiche nel ramo `development` (o `master` nel caso di hotfix).

Quando si individuano problemi o nuove esigenze internamente al team vengono create delle *issue* su GitHub dai membri interessati seguendo un modello predefinito che ne facilita la categorizzazione e la prioritizzazione. \
Oltre che dagli sviluppatori, anche i membri del team dei consulenti applicativi utilizzano i repository su GitHub per svolgere le attività di supporto ai clienti; infatti, ogni qualvolta viene aperta una richiesta di assistenza o di una nuova funzionalità da parte di un cliente, viene creata un'issue su GitHub in cui vengono documentati i dettagli della richiesta ricevuta.

=== Sentry
Sentry è una piattaforma di *monitoraggio degli errori* che consente di tracciare, analizzare e risolvere i problemi nelle applicazioni in tempo reale.\
All'interno di KanbanBOX viene utilizzato sia per ricevere notifiche automatiche sugli errori che si verificano in produzione, sia per gestire in modo più ordinato e collaborativo gli errori che si verificano aggiungendo dettagli utili ai bug su cui si sta lavorando e categorizzandoli.

Giornalmente viene scelto un membro del team di sviluppo viene che si dedicherà maggiormente a monitorare e analizzare le issue segnalate da Sentry in quella giornata.\
In più, settimanalmente viene organizzata una riunione dove il responsabile Sentry di quella giornata, assieme al resto del team, analizza e discute le issue più frequenti dell'ultimo periodo con l'obbiettivo di categorizzarle, documentarle nel modo più dettagliato possibile e assegnarle ai membri del team per la risoluzione.

=== PhpStorm
Per lo sviluppo di KanbanBOX viene utilizzato PhpStorm, un *ambiente di sviluppo integrato* (IDE) specifico per il linguaggio PHP che offre funzionalità avanzate come l'analisi statica del codice, refactoring automatizzato, il debugging e l'integrazione con sistemi di controllo di versione come Git.

=== Microsoft Teams
Per la *comunicazione* interna al team e con il resto dell'azienda viene utilizzato Microsoft Teams, una piattaforma di collaborazione che integra chat, videoconferenze, condivisione di file e integrazione con altre applicazioni Microsoft 365.

All'interno dell'azienda sono presenti sia canali generali per la comunicazione tra tutti i dipendenti, sia canali specifici per ogni team di lavoro. Inoltre sono presenti canali dedicati ad attività specifiche come le riunioni Dev+ weekly e le analisi delle issue di Sentry (vedi #ref(<sez:contesto-aziendale>)).

== Analisi dei rischi
I rischi individuati e analizzati nella fase iniziale del progetto si possono suddividere in tre categorie principali:
- rischi organizzativi;
- rischi tecnici;
- rischi di analisi e progettazione.

=== Rischi organizzativi

==== Gestione del tempo non ottimale
*Descrizione*: durante lo svolgimento dello stage potrebbe non essere sempre possibile gestire il tempo in modo ottimale a causa di attività aziendali ausiliarie o imprevisti.\
*Soluzione*: pianificazione intelligente degli appuntamenti secondari in modo che non vadano a interferire con le attività principali dello stage.

=== Rischi tecnici

==== Inesperienza con tecnologie usate in azienda
*Descrizione*: durante lo svolgimento dello stage potrebbero presentarsi dei rallentamenti dovuti alla mia inesperienza con alcune tecnologie o metodologie usate in azienda.\
*Soluzione*: dedicare la fase iniziale alla comprensione approfondita delle tecnologie ed interfacciarsi con i membri del team per chiedere supporto in caso di difficoltà bloccanti.

==== Influenze esterne
*Descrizione*: durante lo svolgimento dello stage potrebbero sorgere problemi tenici dovuti a fattori esterni all'azienda, come ad esempio bug o disservizi di dipendenze esterne del prodotto.\
*Soluzione*: analizzare il problema per identificare il prima possibile la reale causa, successivamente cercare di mitigarlo, se necessario coinvolgendo altri membri del team con maggiore esperienza; nel caso in cui il problema risultasse non risolvibile internamente ripianificare le attività in modo da minimizzare l'impatto sullo svolgimento dello stage.

=== Rischi di analisi e progettazione
// TODO: il tempo verbale è adeguato? Attualmente la fase di studio è conclusa, quindi forse sarebbe meglio usare il passato?
I rischi appartenenti a questa categoria derivano principalmente dal fatto che le tecnologie usate non sono ancora approfonditamente esplorate dal team di sviluppo, quindi è necessaria una fase di studio e sperimentazione per comprenderne al meglio le potenzialità, i limiti e le opzioni di integrazione con il prodotto.

==== Variazione dei requisti
*Descrizione*: durante la fase di studio potrebbero emergere nuove informazioni che potrebbero essere incongruenti con le aspettative o rendere obsoleti i requisiti inizialmente definiti.\
*Soluzione*: mantenere una comunicazione costante con il tutor aziendale per discutere eventuali cambiamenti nei requisiti.

==== Scelte progettuali non adeguate
*Descrizione*: durante la fase di integrazione e sviluppo potrebbero emergere nuove esigenze, limitazioni od opportunità date dalle tecnologie scelte.\
*Soluzione*: intervallare le fasi di integrazione o sviluppo con momenti di studio e sperimentazione mirati in modo da accertarsi che le scelte fatte siano adeguate, sfruttando anche le nuove informazioni derivanti dalle fasi di integrazione o sviluppo di altre tecnologie, svolte precedentemente.