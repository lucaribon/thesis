#import "../config/thesis-config.typ": gloss

#pagebreak(to: "odd")

= Descrizione dello stage // 2 pagine
<cap:descrizione-stage>

== Contesto aziendale <sez:contesto-aziendale>
Lo stage si è svolto in presenza presso la sede di Vicenza di KanbanBOX S.r.l.\
Sono stato inserito nel team sviluppatori software con il quale ho, fin da subito, partecipato a tutte le attività di routine previste per tutto il gruppo. \

Per tutta la durata dello stage ho avuto a disposizione il supporto del mio tutor aziendale e del mio _buddy_, i quali mi hanno guidato nell'inserimento all'interno dell'azienda, del team e del prodotto KanbanBOX su cui ho lavorato. \
Inoltre, ho avuto modo di collaborare anche con altri membri del team per discutere con chi aveva maggiore esperienza in merito agli argomenti o alle tecnologie con cui ero meno familiare.

Oltre al supporto _peer-to-peer_ ricevuto ho potuto seguire diversi corsi di formazione interna organizzati dall'azienda per approfondire i concetti, sia teorici che pratici, legati alla metodologia Lean, ai cartellini Kanban e all'utilizzo di KanbanBOX.

== Metodo di lavoro

// === Pianificazione e revisione delle attività
Per il team di sviluppo sono previste diverse occasioni ricorrenti per la pianificazione e la revisione delle attività svolte:
- *Daily stand-up meeting*: riunione giornaliera di circa 15 minuti in cui ogni membro del team condivide lo stato di avanzamento del proprio lavoro, le difficoltà incontrate e gli obiettivi per la giornata corrente;
- *Dev+ weekly*: riunione settimanale del team di sviluppo a cui partecipa anche un consulente esterno, con esperienza rilevante nel mondo PHP _open source_, con cui si affrontano i problemi più ostici e si analizzano approfonditamente potenziali soluzioni;
- *Analisi issue Sentry*: riunione settimanale tra tutti i membri del team in cui si analizza il report delle _issue_ tracciate da Sentry, uno strumento di monitoraggio degli errori in produzione; l'obbiettivo dell'incontro è quello di identificare i bug più critici e frequenti e di assegnarli ai membri del team per la risoluzione;
- *OKR (Objective and Key Results)*: riunione svolta su base trimestrale in cui, partendo da degli obiettivi aziendali più generici, si definiscono gli obiettivi specifici per il team di sviluppo e i risultati chiave che ne misurano il raggiungimento. \ Così facendo si assicura che ogni team si impegni a supportare gli obbiettivi aziendali e non solo le proprie esigenze interne o del cliente.


    // TODO: aggiungere loghi
    /*=*/=== Versionamento e integrazione continua
Per il *versionamento* di tutta la _codebase_ e la documentazione di KanbanBOX viene utilizzato *Git*, un sistema di controllo di versione distribuito.

I repository Git sono ospitati su *GitHub*, una piattaforma utilizzata per la gestione del codice sorgente e la collaborazione tra sviluppatori, che fornisce funzionalità aggiuntive, oltre al semplice versionamento, usate dal team di KanbanBox come la gestione delle _issue_, le _pull request_ con relative verifiche del codice e l'integrazione continua.

Nel repository di KanbanBOX, ovvero quello contentente tutta la _codebase_ del prodotto, viene usato il flusso di lavoro *Git Flow*, che prevede l'utilizzo di due rami principali, `master` e `development`. \
In `master` viene mantenuta sempre la versione stabile e in produzione, mentre in `development` viene costruito lo _snapshot_ della prossima _release_.
In aggiunta a questi due rami principali, ne esistono altri con scopi specifici che seguono la seguente nomenclatura:
- `feature/nome-feature`: rami usati per lo sviluppo di nuove funzionalità;
- `fix/nome-fix`: rami usati per la risoluzione di bug;
- `hotfix/nome-hotfix`: rami usati per la correzione di bug critici in produzione;
- `chore/nome-chore`: rami usati per attività di manutenzione o che in generale non apportano modifiche percebili dall'utente finale (aggiornamenti di librerie, configurazioni, implementazione di funzionalità esistenti che non prevedono risoluzione di bug).

Quando lo scopo di un ramo viene assolto interamente, viene aperta una *pull request* su GitHub per richiedere la revisione e l'integrazione delle modifiche nel ramo `development` (o `master` nel caso di hotfix).\
Ad ogni pull request si applicano delle *politiche di revisione* in base all'impatto che l'_issue_ risolta ha sul prodotto:
- _low_: nessuna revisione richiesta;
- _average_: revisione da parte di almeno un altro sviluppatore;
- _high_: revisione da parte di almeno due altri sviluppatori.

Quando si individuano problemi o nuove esigenze internamente al team vengono create delle *issue* su GitHub dai membri interessati seguendo un modello predefinito che ne facilita la categorizzazione e la prioritizzazione. \
Oltre agli sviluppatori, anche il team dei consulenti applicativi utilizza i repository su GitHub per svolgere le attività di supporto ai clienti; infatti, ogni qualvolta viene aperta una richiesta di assistenza o di una nuova funzionalità da parte di un cliente, questa viene trasformata in un'_issue_ su GitHub in cui vengono documentati i dettagli della richiesta ricevuta. \
Infine le _issue_ possono anche essere il risultato delle riunioni OKR.

L'assegnazione delle _issue_ ai singoli membri avviene su base volontaria; ci sono però dei casi in cui l'assegnazione viene fatta in modo diretto, solitamente quando si hanno delle scadenze stringenti, così da essere sicuri di assegnare le _issue_ ai membri con maggiore _ownership_ tecnica sull'argomento trattato.\
Inoltre, capita di scegliere volontariamente di mantenere certe _issue_ a granularità meno fine, così che stia agli sviluppatori con più esperienza la decisione sul come suddividerle o se assegnarle ad un sotto-team dedicato.

Per ogni pull request aperta su GitHub vengono eseguite automaticamente le seguenti GitHub *Actions*:
- *PHPUnit*: esecuzione di test di unità, di integrazione ed _end-to-end_;
- *Playwright*: esecuzione di test _end-to-end_ che simulano le operazioni utente tramite _browser_ automatizzati;
- *PSALM*: analisi statica del codice PHP per individuare potenziali _bug_ e problemi di sicurezza.

Tutti i test vengono eseguiti sia simulando il nuovo prodotto nella sua interezza, sia nelle seguenti casistiche meno comuni:
- esecuzione di nuove implementazioni o integrazioni nel codice in ambienti con le configurazioni della release stabile corrente; questo permette di individuare potenziali *problemi di retro-compatibilità*;
- esecuzione del vecchio codice con in ambienti con le nuove configurazioni previste per la prossima release; questo permette di misurare la capacità di fare *_rollback_* in caso di problemi con la nuova release.

Anche per i test vengono usati dei _container_ in modo da isolare l'ambiente di esecuzione e garantire che i test siano più semplici da automatizzare e sempre riproducibili in modo consistente.

*Giornalmente* viene distribuita una *release* che include tutte le pull request approvate e integrate nel ramo `development`.\

Rilevante è l'impegno che KanbanBOX sta impiegando per automatizzare il più possibile il processo di distribuzione, sfruttando, anche in questo caso, i Docker _container_.

=== Monitoraggio
*Sentry* è una piattaforma di *monitoraggio degli errori* che consente di tracciare, analizzare e risolvere i problemi nelle applicazioni in tempo reale.\
All'interno di KanbanBOX viene utilizzata sia per ricevere notifiche automatiche sugli errori che si verificano in produzione, sia per gestire in modo più ordinato e collaborativo gli errori che si verificano aggiungendo dettagli utili ai _bug_ su cui si sta lavorando e categorizzandoli.

Giornalmente viene scelto un membro del team di sviluppo viene che si dedicherà maggiormente a monitorare e analizzare le issue segnalate da Sentry in quella giornata.\
In più, settimanalmente viene organizzata una riunione dove il *responsabile Sentry* di quella giornata, assieme al resto del team, analizza e discute le issue più frequenti dell'ultimo periodo con l'obbiettivo di categorizzarle, documentarle nel modo più dettagliato possibile e assegnarle ai membri del team per la risoluzione.

=== Altri strumenti a supporto dello sviluppo

Per lo sviluppo di KanbanBOX viene utilizzato *PhpStorm*, un *ambiente di sviluppo integrato (#gloss("IDE", <glossary-ide>))* specifico per il linguaggio PHP che offre funzionalità avanzate come l'analisi statica del codice, _refactoring_ automatizzato, il _debugging_ e l'integrazione con sistemi di controllo di versione come Git.

Tutti i servizi che compongono KanbanBOX, o che ne supportano lo sviluppo e il _testing_, sono eseguiti in dei _container_.\
*Docker* è la piattaforma utilizzata per creare, distribuire e gestire questi container in modo efficiente; nel caso di KanbanBOX vengono utilizzati dei Dockerfile per istanziare e orchestrare i container, e dei file `docker-compose.yml` per definire la loro configurazione.

Per la *comunicazione* interna al team e con il resto dell'azienda viene utilizzato *Microsoft Teams*, una piattaforma di collaborazione che integra chat, videoconferenze, condivisione di file e integrazione con altre applicazioni Microsoft 365.\
All'interno dell'azienda sono presenti sia canali generali per la comunicazione tra tutti i dipendenti, sia canali specifici per ogni team di lavoro. Inoltre sono presenti canali dedicati ad attività specifiche come le riunioni Dev+ weekly e le analisi delle issue di Sentry (vedi #ref(<sez:contesto-aziendale>)).


== Analisi dei rischi
I rischi individuati e analizzati nella fase iniziale del progetto vengono identificati usando la seguente codifica:
#align(center, [*R[categoria] - [numero]*])
Dove:
- *R*: indica che si tratta di un rischio;
- *[categoria]*: indica la categoria di appartenenza del rischio (A: di analisi e progettazione, O: organizzativo, T: tecnico);
- *[numero]*: indica il numero progressivo del rischio all'interno della categoria.

I rischi di analisi e progettazione derivano principalmente dal fatto che le tecnologie usate non sono ancora approfonditamente esplorate dal team di sviluppo, quindi è necessaria una fase di studio e sperimentazione per comprenderne al meglio le potenzialità, i limiti e le opzioni di integrazione con il prodotto.

=== RA-01 - Variazione dei requisti
*Descrizione*: durante la fase di studio potrebbero emergere nuove informazioni che potrebbero essere incongruenti con le aspettative o rendere obsoleti i requisiti inizialmente definiti.\
*Soluzione preventiva*: mantenere una comunicazione costante con il tutor aziendale per discutere eventuali cambiamenti nei requisiti.

=== RA-02 - Scelte progettuali non adeguate
*Descrizione*: durante la fase di integrazione e sviluppo potrebbero emergere nuove esigenze, limitazioni od opportunità date dalle tecnologie scelte.\
*Soluzione diagnostica*: intervallare le fasi di integrazione o sviluppo con momenti di studio e sperimentazione mirati in modo da accertarsi che le scelte fatte siano adeguate, sfruttando anche le nuove informazioni derivanti dalle fasi di integrazione o sviluppo di altre tecnologie, svolte precedentemente.

=== RO-01 - Gestione del tempo non ottimale
*Descrizione*: durante lo svolgimento dello stage potrebbe non essere sempre possibile gestire il tempo in modo ottimale a causa di attività aziendali ausiliarie o imprevisti.\
*Soluzione preventiva*: pianificazione intelligente degli appuntamenti di importanza secondaria in modo che non vadano a interferire con le attività principali dello stage.

=== RT-01 - Inesperienza con tecnologie usate in azienda
*Descrizione*: durante lo svolgimento dello stage potrebbero presentarsi dei rallentamenti dovuti alla mia inesperienza con alcune tecnologie o metodologie usate in azienda.\
*Soluzione preventiva e correttiva*: dedicare la fase iniziale alla comprensione approfondita delle tecnologie ed interfacciarsi con i membri del team per chiedere supporto in caso di difficoltà bloccanti.

=== RT-02 - Influenze esterne
*Descrizione*: durante lo svolgimento dello stage potrebbero sorgere problemi tenici dovuti a fattori esterni all'azienda, come ad esempio bug o disservizi di dipendenze esterne del prodotto.\
*Soluzione correttiva*: analizzare il problema per identificare il prima possibile la reale causa, successivamente cercare di mitigarlo, se necessario coinvolgendo altri membri del team con maggiore esperienza; nel caso in cui il problema risultasse non risolvibile internamente ripianificare le attività in modo da minimizzare l'impatto sullo svolgimento dello stage.

=== RT-03 - Messaggi duplicati
*Descrizione*: durante la fase di fornitura potrebbero emergere problemi legati alla ricezione di messaggi MQTT duplicati causati da malfunzionamenti o configurazioni poco precise dei lettori RFID.\
*Soluzione preventiva*:
- implementazione di un sistema di _debounce_ lato backend di KanbanBOX che filtri i messaggi duplicati in base ad un identificativo univoco e ad una finestra temporale configurabile;
- configurazione dei lettori RFID per minimizzare la probabilità di letture duplicate, ad esempio regolando la potenza di trasmissione o la sensibilità dell'antenna.\

=== RT-04 - Perdita di messaggi
*Descrizione*: durante la fase di fornitura potrebbero emergere problemi legati alla perdita di messaggi MQTT causati da malfunzionamenti della rete o dei servizi _middleware_.\
*Soluzione preventiva*:
- configurazione del _Quality of Service (QoS)_ di MQTT a livello 1 (ogni messaggio viene ricevuto almeno una volta) sia nei dispositivi che nel broker;
- configurazione della _message retention_ nel broker MQTT in modo da conservare i messaggi non recapitati per un periodo di tempo configurabile.

=== RT-05 - Sicurezza della comunicazione MQTT
*Descrizione*: in fase di progettazione sono stati individuati dei potenziali rischi legati alla sicurezza della connessione e comunicazione tra i client del broker, data dall'utilizzo di un solo broker MQTT (integrato in AWS IoT) condiviso tra tutti i clienti.\
Infatti, il broker di AWS IoT nella sua configurazione base permette a tutti i client di connettersi e comunicare tramite #gloss("topic", <glossary-topic>) liberamente.\
*Soluzione preventiva*: (vedi {reference a sezione dedicata}/*#ref(<sez:sicurezza-mqtt>)*/ per una descrizione più dettagliata)
- utilizzo di certificati X.509 per l'autenticazione dei client MQTT, in modo da garantire che solo i client autorizzati possano connettersi e comunicare;
- creazione di policy dinamiche (che variano in base al dispositivo), basate su dei template, per limitare i permessi e l'accesso ai topic del dispositivo;
- utilizzo di topic granulari e specifici per ogni dispositivo, in modo da limitare la visibilità dei messaggi solo ai dispositivi autorizzati.

=== RT-06 - Debugging difficoltoso
*Descrizione*: durante la fase di sviluppo e testing potrebbero emergere difficoltà nel monitorare ed eseguire il _debug_ i messaggi MQTT scambiati tra i dispositivi e il broker, e successivamente tra la coda SQS e il backend di KanbanBOX.\
*Soluzione preventiva*: \
- sfruttare il sistema di _logging_, già presente nel progetto, nel nuovo codice sviluppato;
- usare strumenti di test o simulazione come il test client di AWS IoT o ElasticMQ per simulare una coda in locale.

=== RT-07 - Errata configurazione dei lettori RFID
*Descrizione*: una configurazione non corretta dei lettori RFID (endpoint MQTT, certificati, QoS, topic, modalità operativa) potrebbe causare malfunzionamenti nella trasmissione dei messaggi o comportamenti non coerenti tra dispositivi diversi.\
*Soluzione preventiva*: fornire una configurazione standard funzionante che può essere facilmente usata e adattata dagli installatori.\

=== RT-08 - Disconnessioni dei dispositivi fisici
*Descrizione*: disconnessioni frequenti o prolungate dei lettori RFID potrebbero causare interruzioni nella trasmissione dei dati e perdita di messaggi importanti.\
*Soluzione preventiva*: implementare meccanismi di riconnessione automatica nei dispositivi, definendo parametri come il tempo di _keep-alive_ e il numero di tentativi di riconnessione nei dispositivi.\


#show par: set block(breakable: false)
// TODO: terminare con una tabella riassuntiva che riporta codice, nome breve, tipologia probabilità e impatto
=== Specifica dei Rischi

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RA-01 - Variazione dei requisiti*],
        [*Tipologia*], [Analisi e progettazione],
        [*Probabilità*], [Media],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RA-01",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RA-02 - Scelte progettuali non adeguate*],
        [*Tipologia*], [Analisi e progettazione],
        [*Probabilità*], [Media],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RA-02",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RO-01 - Gestione del tempo non ottimale*],
        [*Tipologia*], [Organizzativo],
        [*Probabilità*], [Alta],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RO-01",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-01 - Inesperienza con tecnologie usate in azienda*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Alta],
        [*Impatto*], [Basso],
    ),
    caption: "Dettagli relativi al rischio RT-01",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-02 - Influenze esterne*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Bassa],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RT-02",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-03 - Messaggi duplicati*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Bassa],
        [*Impatto*], [Medio],
    ),
    caption: "Dettagli relativi al rischio RT-03",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-04 - Perdita di messaggi*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Bassa],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RT-04",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-05 - Sicurezza della comunicazione MQTT*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Bassa],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RT-05",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-06 - Debugging difficoltoso*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Alta],
        [*Impatto*], [Medio],
    ),
    caption: "Dettagli relativi al rischio RT-06",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-07 - Errata configurazione dei lettori RFID*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Bassa],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RT-07",
)

#figure(
    table(
        columns: (1fr, 2fr),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(180) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.cell(colspan: 2)[*RT-08 - Disconnessioni dei dispositivi fisici*],
        [*Tipologia*], [Tecnico],
        [*Probabilità*], [Media],
        [*Impatto*], [Alto],
    ),
    caption: "Dettagli relativi al rischio RT-08",
)
