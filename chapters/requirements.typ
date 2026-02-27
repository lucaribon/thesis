#import "../config/thesis-config.typ": useCase
#import "../config/thesis-config.typ": gloss

#pagebreak(to: "odd")

= Analisi dei requisiti // 10-20 pagine
<cap:analisi-requisiti>

== Panoramica delle funzionalità
=== Gestione dei reader RFID
Dall'interfaccia di gestione dei reader RFID, strutturata come tabella, l'amministratore deve poter eseguire le seguenti operazioni:
- *Aggiunta* di un nuovo reader RFID, inserendo i seguenti dati:
    - _nome_: nome che aiuta l'utente a identificare il reader;
    - _produttore_: nome dell'azienda che ha prodotto il reader, attualmente sono disponibili solo reader prodotti da Zebra;
    - _modello_: nome o numero di modello del reader, attualmente sono disponibili solo reader della serie FX7500 e FX9600;
    - _indirizzo MAC_: indirizzo MAC del reader; campo opzionale poiché viene usato uno UUID generato dal backend di KanbanBox che risulta più affidabile, in quanto il MAC address può essere facilmente manipolato da chiunque abbia accesso al reader;
    - _abilitazione_: indica se il reader è abilitato e quindi utilizzabile o meno, permette di rendere temporaneamente inutilizzabile un reader senza doverlo eliminare e riconfigurare successivamente.
    L'aggiunta deve scaturire sia la registrazione del reader nel database di KanbanBox, che la creazione delle entità corrispondenti al reader e al certificato in Aws IoT.
- *Aggiornamento* dei dati di un reader già registrato nel sistema, con parametri e modalità coerenti con la procedura di aggiunta;
- *Configurazione*
    - del *sistema*: permette di configurare i parametri per la connessione al broker MQTT, in questo caso integrato in AWS IoT Core, tra cui anche i certificati per autenticare il reader durante la comunicazione con AWS IoT;
    - della *modalità operativa*: e i parametri della comunicazione tramite MQTT (ad esempio topic o #gloss("Quality of Service", <glossary-qos>));
    - *modalità operativa*: permette di determinare i parametri di lettura dei tag RFID, come ad esempio la frequenza di rilettura, il batching e la potenza dell'antenna radio.
    Le configurazioni, una volta applicate, dovranno essere salvate a database per poterle modificare più rapidamente in futuro.
- *Eliminazione* di un reader, che comporta anche l'eliminazione delle entità corrispondenti al reader e al certificato in Aws IoT;
- *Download  del certificato* associato al reader, necessario per la comunicazione con AWS IoT, che può essere scaricato una sola volta per motivi di sicurezza. \ Nello specifico il certificato deve essere facilmente fruibile per utenti con meno dimestichezza come i consulenti che si occupano di configurare i reader presso i clienti.

=== Ricezione e visualizzazione dei cartellini letti dai reader
La piattaforma prevede già un'interfaccia per visualizzare i cartellini letti dai reader, con elementi grafici intuitivi e individuabili in modo chiaro, che permette di distinguere facilmente i cartellini processati da quelli scartati anche in ambienti meno agevoli come le linee di produzione delle aziende clienti.

La migrazione da HTTP a MQTT comporta però un'incompatibilità nella comunicazione tra i reader e KanbanBox; è quindi necessario *adattare l'implementazione* del *_pull_* dei cartellini da AWS SQS e dell'*interpretazione* dei dati trasmessi attraverso i tag letti, in modo che questi rimangano associabili ai cartellini kanban e al loro cambio stato, e che continuino ad essere distinti tra cartellini processati e scartati.

=== Errori e notifiche all'utente
In caso di *errori*, il sistema deve notificare all'amministratore l'impossibilità di completare l'operazione richiesta e l'errore riscontrato tramite dei *pop-up* a scomparsa, mostrati direttamente nella pagina in cui l'utente sta operando.

Il contenuto dei messaggi di errore deve racchiudere una breve descrizione dell'errore riscontrato, comprensibile anche per utenti non tecnici; inoltre, ove possibile, deve fornire dettagli utili a comprendere il problema, come ad esempio l'identificativo della risorsa su cui si stava operando.

== Attori
*Amministratore*: nel backend di KanbanBOX sono presenti diversi ruoli utilizzati per definire i permessi all'interno della piattaforma. Nonostante ciò, le funzionalità implementate durante questo progetto di tesi sono accessibili in egual modo dai ruoli sviluppatore, amministratore o consulente applicativo, poiché è necessario che possano essere utilizzate da qualsiasi figura tecnica che si occupi di sviluppo o manutenzione della piattaforma.\
Per questo motivo, in questa sede, ho deciso di raggruppare tutti i ruoli al di sotto dell'attore "Amministratore".

== Casi d'uso
In questa sezione sono presenti i diagrammi #gloss("UML", <glossary-uml>) che rappresentano i casi d'uso principali del sistema e le loro descrizioni.

Il progetto è focalizzato principalmente sulla creazione di un driver di interfacciamento, ovvero un componente software che si occupa di gestire la comunicazione tra i reader RFID, AWS IoT Core e la piattaforma web KanbanBox, e sulla progettazione dell'architettura del sistema che include reader, servizi AWS e backend di KanbanBox.
Inoltre molte delle funzionalità direttamente o indirettamente legate alle modifiche o aggiunte fatte erano già implementate in origine e sono rimaste invariate e funzionanti.
Per questo i casi d'uso relativi al progetto sono in numero ridotto e semplici.

// TODO: quando si scrive al relatore specificare che i diagrammi non ci sono perché aspetto che gli UC siano definitivi
// TODO: integrare la figure nello use case in modo che venga mostrata sotto al titolo del caso d'uso. A MENO CHE non si decida/riesca a fare una solo figure per più use case, visto che sono molto legati e pochi.
// #figure(
//     image("../images/usecase/scenario-principale.png", width: 100%),
//     caption: "Use Case - UC0: Scenario principale",
// ) <uc:scenario-principale>

#useCase(
    (
        number: 1,
        name: "Aggiunta di un reader RFID",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di aggiungere un nuovo reader RFID alla piattaforma, configurando i parametri necessari per la comunicazione con AWS IoT.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT.",
        ),
        postcondizioni: (
            "Il reader RFID viene registrato nella piattaforma KanbanBox;",
            "Il reader RFID viene registrato nei servizi cloud esterni.",
        ),
        scenario_principale: (
            "L'amministratore inserisce i dati del reader RFID negli appositi campi:
                - nome;
                - produttore;
                - modello;
                - indirizzo MAC;
                - abilitazione.
            Tutti i campi sono configurati in modo da accettare solo dati nel formato valido;",
            "L'amministratore invia i dati del reader tramite il pulsante di salvataggio.",
        ),
        estensioni: (
            "Errore: sistema non raggiungibile;",
            "Errore: servizi cloud esterni non raggiungibili.",
        ),
    ),
)
<uc:1>

#useCase(
    (
        number: 2,
        name: "Aggiornamento dati del reader RFID",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di aggiornare i dati di un reader RFID già registrato nella piattaforma.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "Il reader RFID è già registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: (
            "Il sistema ha aggiornato i dati del reader RFID nella piattaforma KanbanBox.",
        ),
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per modificare i dati del reader scelto;",
            "L'amministratore inserisce i dati aggiornati del reader RFID negli appositi campi, configurati in modo da accettare solo dati nel formato valido:
                - nome;
                - produttore;
                - modello;
                - indirizzo MAC;
                - abilitazione.",
            "L'amministratore invia le modifiche da applicare al reader tramite il pulsante di salvataggio.",
        ),
        estensioni: (
            "Errore: sistema non raggiungibile;",
            "Errore: servizi cloud esterni non raggiungibili.",
        ),
    ),
)
<uc:2>

#useCase(
    (
        number: 3,
        name: "Configurazione reader RFID",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di configurare un reader RFID già registrato nella piattaforma.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "Il reader RFID è già registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: (
            parts: (
                "Il sistema ha aggiornato la configurazione di sistema e/o della modalità operativa del reader RFID e ne ha creato un ",
                (body: "backup", target: <glossary-backup>),
                " salvato a database.",
            ),
        ),
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per configurare il reader scelto;",
            "L'amministratore inserisce le configurazioni di sistema, della modalità operativa e dell'ambiente di comunicazione del reader, separatamente, negli appositi campi di testo;",
            "L'amministratore invia le configurazioni del reader tramite il pulsante di salvataggio.",
        ),
        estensioni: (
            "Errore: sistema non raggiungibile;",
            "Errore: servizi cloud esterni non raggiungibili.",
        ),
        inclusioni: (
            "Modifica della configurazione di sistema del reader RFID;",
            "Modifica della modalità operativa del reader RFID.",
        ),
    ),
)
<uc:3>

#useCase(
    (
        number: 3.1,
        name: "Modifica della configurazione di sistema del reader RFID",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di modificare la configurazione di sistema del reader RFID, che include parametri utili per l'utilizzo di certificati di AWS IoT o la configurazione relativa a MQTT.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "Il reader RFID è già registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: (
            "L'amministratore ha inserito la configurazione di sistema nel formato apposito.",
        ),
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per configurare il reader scelto;",
            "L'amministratore inserisce la configurazione di sistema del reader in formato JSON, che può anche essere generata tramite un form creato basandosi su uno schema apposito.",
        ),
        estensioni: (
            "Errore: configurazione non valida.",
        ),
    ),
)
<uc:3.1>

#useCase(
    (
        number: 3.2,
        name: "Modifica della modalità operativa del reader RFID",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di modificare la modalità operativa del reader RFID, che include parametri come la configurazione delle antenne radio, la frequenza di lettura dei tag, i dati inseriti nei messaggi MQTT e altri.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "Il reader RFID è già registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: (
            "L'amministratore ha inserito la configurazione della modalità operativa nel formato apposito.",
        ),
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per configurare il reader scelto;",
            "L'amministratore inserisce la modalità operativa del reader in formato JSON, che può anche essere generata tramite un form creato basandosi su uno schema apposito.",
        ),
        estensioni: (
            "Errore: configurazione non valida.",
        ),
    ),
)
<uc:3.2>

#useCase(
    (
        number: 4,
        name: "Eliminazione reader RFID",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di eliminare un reader RFID già registrato nella piattaforma.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "Il reader RFID è registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: (
            "Il reader RFID viene eliminato dalla piattaforma KanbanBox;",
            "Il reader RFID viene eliminato dai servizi cloud esterni.",
        ),
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per eliminare il reader scelto;",
            "Tramite un pop-up viene chiesta conferma dell'eliminazione del reader RFID;",
            "Se viene confermata l'eliminazione, il sistema procede a eliminare il reader RFID dalla piattaforma KanbanBox e dai servizi cloud esterni.",
        ),
        estensioni: (
            "Errore: sistema non raggiungibile;",
            "Errore: servizi cloud esterni non raggiungibili;",
            "Errore: eliminazione già effettuata.",
        ),
    ),
)
<uc:4>

#useCase(
    (
        number: 5,
        name: "Download del certificato associato al reader",
        attore_principale: "Amministratore",
        descrizione: "Il sistema consente all'amministratore di scaricare, solamente una volta, il certificato associato al reader RFID, necessario per la comunicazione con AWS IoT.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "Il reader RFID è già registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: "Viene fornito il file del certificato, che può essere scaricato in locale una sola volta per motivi di sicurezza.",
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per scaricare il certificato del reader scelto;",
            "Viene mostrato un pop-up per notificare all'amministratore che il certificato può essere scaricato una sola volta e per richiedere la conferma dell'operazione;",
            "Se viene confermata l'operazione, il sistema fornisce il file del certificato da scaricare in locale.",
        ),
        estensioni: (
            "Errore: sistema non raggiungibile;",
            "Errore: servizi cloud esterni non raggiungibili;",
            "Errore: certificato già scaricato.",
        ),
    ),
)
<uc:5>

#useCase(
    (
        number: 6,
        name: "Visualizzazione dei cartellini letti dal reader",
        attore_principale: "Amministratore",
        descrizione: "Il sistema implementa una dashboard da cui è possibile vedere i cartellini letti dai reader e il loro stato.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Almeno un reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "I reader hanno letto almeno un cartellino.",
        ),
        postcondizioni: "Viene mostrata una dashboard con i cartellini letti dai reader e il loro stato.",
        scenario_principale: (
            "L'amministratore accede alla dashboard dei cartellini letti dai reader;",
            "Viene mostrata una tabella con i cartellini letti dai reader e il loro stato;",
            "Ogni cartellino letto persiste nella dashboard per un periodo di tempo configurabile dall'utente, dopo il quale viene rimosso dalla visualizzazione;",
            "Un cartellino può essere visualizzato nuovamente solo se uno dei reader attivi continua a leggerlo.",
        ),
        generalizzazioni: (
            "Visualizzazione dei cartellini processati;",
            "Visualizzazione dei cartellini scartati.",
        ),
    ),
)
<uc:6>

#useCase(
    (
        number: 6.1,
        name: "Visualizzazione dei cartellini processati",
        attore_principale: "Amministratore",
        descrizione: "Nella dashboard di visualizzazione dei cartellini letti è presente una colonna dedicata ai cartellini processati dai reader.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Almeno un reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "I reader hanno letto almeno un cartellino;",
            "Almeno uno dei cartellini letti dai reader contiene un identificatore, del reader da cui è stato letto, corrispondente a quello di uno dei reader attivi.",
        ),
        postcondizioni: "Il cartellino processato viene mostrato nella colonna dedicata.",
        scenario_principale: (
            "L'amministratore accede alla dashboard dei cartellini letti dai reader;",
            "I cartellini che riportano un identificatore del reader da cui sono stati letti conforme vengono mostrati nella colonna dedicata ai cartellini processati.",
        ),
    ),
)
<uc:6.1>

#useCase(
    (
        number: 6.2,
        name: "Visualizzazione dei cartellini scartati",
        attore_principale: "Amministratore",
        descrizione: "Nella dashboard di visualizzazione dei cartellini letti è presente una colonna dedicata ai cartellini scartati dai reader.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "Almeno un reader RFID è configurato per poter comunicare in rete e con AWS IoT;",
            "I reader hanno letto almeno un cartellino;",
            "Almeno uno dei cartellini letti dai reader contiene un identificatore, del reader da cui è stato letto, incompleto o che non corrisponde a nessuno dei reader attivi.",
        ),
        postcondizioni: "Il cartellino scartato viene mostrato nella colonna dedicata.",
        scenario_principale: (
            "L'amministratore accede alla dashboard dei cartellini letti dai reader;",
            "I cartellini che riportano un identificatore del reader da cui sono stati letti non conforme vengono mostrati nella colonna dedicata ai cartellini scartati.",
        ),
    ),
)
<uc:6.2>


#useCase(
    (
        number: 7,
        name: "Errore: sistema non raggiungibile",
        attore_principale: "Amministratore",
        descrizione: (
            parts: (
                "Il ",
                (body: "backend", target: <glossary-backend>),
                " di KanbanBOX non è raggiungibile a causa di un malfunzionamento del sistema o di problemi di rete. In questo caso, il sistema deve notificare all'amministratore l'impossibilità di completare l'operazione richiesta.",
            ),
        ),
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "L'amministratore sta tentando di eseguire un'operazione che richiede la comunicazione con il backend di KanbanBOX.",
        ),
        postcondizioni: (
            "Il sistema mostra un messaggio di errore all'amministratore, indicando che l'operazione richiesta non può essere completata.",
        ),
        scenario_principale: (
            "L'amministratore tenta di eseguire un'operazione che richiede la comunicazione con il backend di KanbanBOX;",
            "Il sistema rileva che il backend di KanbanBOX non è raggiungibile;",
            "Il sistema mostra un messaggio di errore all'amministratore.",
        ),
    ),
)
<uc:7>

#useCase(
    (
        number: 8,
        name: "Errore: servizi cloud esterni non raggiungibili",
        attore_principale: "Amministratore",
        descrizione: "I servizi cloud esterni, come AWS IoT, non sono raggiungibili a causa di un problema di configurazione o di un errore nel backend di KanbanBox. In questo caso, il sistema deve notificare all'amministratore l'impossibilità di inoltrare la richiesta al servizio cloud esterno e di completare l'operazione richiesta.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "L'amministratore sta tentando di eseguire un'operazione che richiede la comunicazione con un servizio cloud esterno.",
        ),
        postcondizioni: "Il sistema mostra un messaggio di errore all'amministratore, indicando che l'operazione richiesta non può essere completata.",
        scenario_principale: (
            "L'amministratore tenta di eseguire un'operazione che richiede la comunicazione con un servizio cloud esterno;",
            "Il backend rileva che il servizio cloud esterno non è raggiungibile;",
            "Il sistema mostra un messaggio di errore all'amministratore.",
        ),
    ),
)
<uc:8>

#useCase(
    (
        number: 9,
        name: "Errore: configurazione non valida",
        attore_principale: "Amministratore",
        descrizione: "La configurazione inserita dall'amministratore per un reader RFID non è valida, a causa della mancanza di alcuni dati o del mancato rispetto dei vincoli imposti dallo schema di validazione.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "L'amministratore ha tentato di configurare un reader RFID.",
        ),
        postcondizioni: "Il sistema mostra un messaggio di errore all'amministratore, indicando che la configurazione inserita non è valida e specificando i motivi dell'invalidità.",
        scenario_principale: (
            "L'amministratore tenta di configurare un reader RFID;",
            "Il sistema valida la configurazione inserita dall'amministratore;",
            "Il sistema rileva che la configurazione non è valida;",
            "Il sistema mostra un messaggio di errore all'amministratore, indicando i motivi dell'invalidità della configurazione.",
        ),
    ),
)
<uc:9>

#useCase(
    (
        number: 10,
        name: "Errore: eliminazione già effettuata",
        attore_principale: "Amministratore",
        descrizione: "Il sistema restituisce un messaggio di errore all'amministratore quando tenta di eliminare un reader RFID che è già stato eliminato.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "L'amministratore ha tentato di eliminare un reader RFID;",
            "Il reader RFID in questione è già stato eliminato dalla piattaforma KanbanBox e dai servizi cloud esterni.",
        ),
        postcondizioni: "Il sistema mostra un messaggio di errore all'amministratore, indicando che il reader RFID è già stato eliminato.",
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per eliminare il reader scelto;",
            "Tramite un pop-up viene chiesta conferma dell'eliminazione del reader RFID;",
            "Un altro utente conferma l'eliminazione del reader RFID;",
            "L'amministratore conferma l'eliminazione del reader RFID;",
            "Il sistema procede ad eseguire la richiesta dell'amministratore, ma rileva che il reader RFID è già stato eliminato;",
            "Il sistema mostra un messaggio di errore all'amministratore, indicando che il reader RFID è già stato eliminato.",
        ),
    ),
)
<uc:10>

#useCase(
    (
        number: 11,
        name: "Errore: certificato già scaricato",
        attore_principale: "Amministratore",
        descrizione: "Il sistema restituisce un messaggio di errore all'amministratore quando tenta di scaricare il certificato, associato ad un reader, che è già stato scaricato in precedenza, poiché per motivi di sicurezza il certificato può essere scaricato una sola volta.",
        precondizioni: (
            "L'amministratore deve essere autenticato;",
            "L'amministratore ha tentato di scaricare il certificato associato ad un reader RFID;",
            "Il certificato associato in questione è già stato scaricato in precedenza.",
        ),
        postcondizioni: "Il sistema mostra un messaggio di errore all'amministratore, indicando che il certificato è già stato scaricato.",
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per scaricare il certificato del reader scelto;",
            "Viene mostrato un pop-up per notificare all'amministratore che il certificato può essere scaricato una sola volta e per richiedere la conferma dell'operazione;",
            "Un altro utente conferma l'operazione di download del certificato;",
            "L'amministratore conferma l'operazione di download del certificato;",
            "Il sistema procede ad eseguire la richiesta dell'amministratore, ma rileva che il certificato è già stato scaricato;",
            "Il sistema mostra un messaggio di errore all'amministratore, indicando che il certificato è già stato scaricato.",
        ),
    ),
)
<uc:11>

== Requisiti
In questa sezione vengono elencati i requisiti dettati dal progetto. Essendo questo un progetto che ha richiesto un'ampia fase di esplorazione, i requisiti sono stati identificati in diversi momenti, partendo con un'analisi iniziale del piano di lavoro e, successivamente, approfondendo l'analisi attraverso riunioni interne con alcuni membri del team di sviluppo.

Ogni requisito è identificato da un codice alfanumerico costruito seguendo la struttura:
#align(center, [*R - [numero] - [tipo] - [priorità]*])
dove:
- *[numero]*: numero progressivo che identifica il requisito tra quelli dello stesso tipo;
- *[tipo]*: indica se il requisito è
    - *F*: funzionale, indica una funzionalità che il sistema deve implementare;
    - *Q*: di qualità, indica una caratteristica di qualità che il sistema deve soddisfare, come ad esempio prestazioni, sicurezza, usabilità, ecc.;
    - *V*: di vincolo, indica una limitazione che il sistema deve rispettare, imposta dagli stakeholder o da fattori esterni, come ad esempio l'utilizzo di determinate tecnologie, l'aderenza a standard specifici, ecc.;
- *[priorità]*: indica l'importanza del requisito, che può essere
    - *O*: obbligatorio, ovvero che deve essere necessariamente soddisfatto perché si possa considerare il progetto completato;
    - *D*: desiderabile, ovvero che sarebbe preferibile soddisfare, ma non è essenziale per considerare il progetto completato;
    - *FA*: facoltativo, ovvero un requisito migliorativo che può essere soddisfatto se ci sono risorse e tempo sufficienti.

Nelle tabelle @tab:requisiti-funzionali, @tab:requisiti-qualitativi e @tab:requisiti-vincolo sono riassunti i requisiti, le fonti da cui sono stati ricavati e il loro stato di raggiungimento.

// TODO: domandare a relatore: ho escluso i requisti relativi a studio o comunque azioni che dovevo svolgere io, tenendo solo quelli relativi al sistema, va bene? oppure devo includere anche quelli relativi a me come studente? (es. O01, O02, D01, ecc.)

=== Requisiti funzionali
#figure(
    table(
        columns: (auto, auto, auto, auto),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(190) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.header([*Requisito*], [*Descrizione*], [*Fonti*], [*Stato*]),
        [R-01-F-O],
        [Sviluppo del driver di interfacciamento tra antenna RFID Zebra e AWS IoT Core],
        [Piano di lavoro, UC3, UC3.1, UC3.2, UC6],
        [Raggiunto],

        [R-02-F-O],
        [L'amministratore deve poter aggiungere un reader al backend di KanbanBox e ad AWS IoT],
        [UC1],
        [Raggiunto],

        [R-03-F-O],
        [L'amministratore deve poter aggiornare i dati di un reader già registrato nel sistema],
        [UC2],
        [Raggiunto],

        [R-04-F-O],
        [L'amministratore deve poter configurare il sistema è la modalità operativa di un reader già registrato nel sistema],
        [UC3, UC3.1, UC3.2],
        [Raggiunto],

        [R-05-F-O], [L'amministratore deve poter eliminare un reader già registrato nel sistema], [UC4], [Raggiunto],

        [R-06-F-O],
        [L'amministratore deve poter scaricare il certificato associato ad un reader, una sola volta],
        [UC5],
        [Raggiunto],

        [R-07-F-O],
        [Il sistema deve implementare una dashboard da cui è possibile vedere i cartellini letti dai reader e il loro stato],
        [UC6, UC6.1, UC6.2],
        [Raggiunto],

        [R-08-F-O],
        [Il sistema deve notificare all'amministratore l'impossibilità di completare l'operazione richiesta e l'errore riscontrato],
        [UC7, UC8, UC9, UC10, UC11],
        [Raggiunto],
    ),
    caption: "Tabella del tracciamento dei requisti funzionali",
)
<tab:requisiti-funzionali>

=== Requisiti di qualità
#figure(
    table(
        columns: (auto, auto, auto, auto),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(190) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.header([*Requisito*], [*Descrizione*], [*Fonti*], [*Stato*]),
        [R-01-Q-O], [Test e validazione funzionale del driver sviluppato], [Piano di lavoro], [Raggiunto],

        [R-02-Q-O],
        [Implementazione di meccanismi atti a garantire la sicurezza della comunicazione],
        [Riunioni interne],
        [Raggiunto],

        [R-02-Q-D],
        [Ottimizzazione delle performance del driver e gestione avanzata degli errori e dei log],
        [Piano di lavoro],
        [Raggiunto parzialmente],

        [R-03-Q-FA],
        [Redazione della documentazione tecnica relativa all'architettura del progetto, configurazioni e utilizzo del driver],
        [Piano di lavoro],
        [Raggiunto],

        [R-04-Q-FA],
        [Sperimentazione di scenari avanzati di lettura multipla di tag RFID e gestione dei conflitti],
        [Piano di lavoro],
        [Raggiunto],
    ),
    caption: "Tabella del tracciamento dei requisti di qualità",
)
<tab:requisiti-qualitativi>

=== Requisiti di vincolo
#figure(
    table(
        columns: (auto, auto, auto, auto),
        inset: 8pt,
        align: (x, y) => if y > 0 { left } else { center + horizon },
        fill: (x, y) => if y == 0 { luma(190) } else if (y == 2 or y == 4 or y == 6 or y == 8) { luma(230) },

        table.header([*Requisito*], [*Descrizione*], [*Fonti*], [*Stato*]),
        [R-01-V-O],
        [Utilizzo del protocollo MQTT per la comunicazione tra i reader RFID, AWS IoT Core e il backend di KanbanBox],
        [Piano di lavoro, UC3, UC3.1, UC3.2],
        [Raggiunto],

        [R-02-V-O],
        [Utilizzo di AWS IoT Core come servizio cloud per la gestione della comunicazione tra i reader RFID e il backend di KanbanBox],
        [Piano di lavoro, UC6],
        [Raggiunto],

        [R-03-V-O],
        [Utilizzo di AWS SQS come servizio cloud per la gestione delle letture dei tag RFID asincrona],
        [Riunioni interne],
        [Raggiunto],

        [R-04-V-O],
        [Utilizzo di PHP per l'implementazione delle funzionalità richieste],
        [Riunioni interne],
        [Raggiunto],
    ),
    caption: "Tabella del tracciamento dei requisti di vincolo",
)
<tab:requisiti-vincolo>