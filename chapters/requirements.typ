#import "../config/thesis-config.typ": useCase
#import "../config/thesis-config.typ": gloss

#pagebreak(to: "odd")

= Analisi dei requisiti // 10-20 pagine
<cap:analisi-requisiti>
== Attori
// FIXME: ha senso il sistema? mi sa di no?
*Sistema di lettura RFID*: rappresenta l'insieme di dispositivi hardware che si occupano di leggere e trasmettere le informazioni dei tag RFID che attraversano la loro area di copertura.

*Amministratore*: nel backend di KanbanBOX sono presenti diversi ruoli utilizzati per definire i permessi all'interno della piattaforma. Nonostante ciò, le funzionalità implementate sono accessibili in egual modo dai ruoli sviluppatore, amministratore o consulente applicativo, poiché è necessario che possano essere utilizzate da qualsiasi figura tecnica che si occupi di sviluppo o manutenzione dell'applicativo.\
Per questo motivo, in questa sede, ho deciso di raggruppare tutti i ruoli al di sotto dell'attore "Amministratore".

== Obbiettivi
Si prevede lo svolgimento dei seguenti obiettivi:
• Obbligatori
- O01: Studio e comprensione del protocollo MQTT e delle sue modalità di integrazione con
dispositivi IoT.
- O02: Analisi del sistema RFID aziendale e dei lettori Zebra, comprendendo flussi dati e punti
di integrazione.
- O03: Sviluppo del driver di interfacciamento tra antenna RFID Zebra e AWS IoT Core, con
gestione della comunicazione tramite MQTT.
- O04: Test e validazione funzionale del driver sviluppato.
- O05: Realizzazione di una demo funzionante che dimostri l'integrazione completa tra RFID,
AWS IoT Core e sistema aziendale.
• Desiderabili
- D01: Redazione della documentazione tecnica relativa all'architettura del progetto, configurazioni e utilizzo del driver.
- D02: Ottimizzazione delle performance del driver e gestione avanzata degli errori e dei log.
• Facoltativi
- F01: Sperimentazione di scenari avanzati di lettura multipla di tag RFID e gestione dei conflitti.
- F02: Implementazione di notifiche o alert automatici basati sugli eventi rilevati dai tag RFID
tramite AWS IoT Core.

== Panoramica funzionalità

== Casi d'uso
In questa sezione sono presenti i diagrammi #gloss("UML", <glossary-uml>) che rappresentano i casi d'uso principali del sistema e le loro descrizioni.

// Per lo studio dei casi di utilizzo del prodotto sono stati creati dei diagrammi.
// I diagrammi dei casi d'uso (in inglese _Use Case Diagram_) sono diagrammi di tipo UML dedicati alla descrizione delle funzioni o servizi offerti da un sistema, così come sono percepiti e utilizzati dagli attori che interagiscono col sistema stesso.

// TODO: Essendo il progetto finalizzato alla creazione di un tool per l'automazione di un processo E in più molte funzionalità appartenenti allo stesso dominio su cui si è lavorato erano già state implementate e sono risultate compatibili con la nuova architettura del sistema, le interazioni da parte dell'utilizzatore devono essere ovviamente ridotte allo stretto necessario. Per questi motivi i diagrammi dei casi d'uso risultano semplici e in numero ridotto.

// FIXME: integrare la figure nello use case in modo che venga mostrata sotto al titolo del caso d'uso. A MENO CHE non si decida/riesca a fare una solo figure per più use case, visto che sono molto legati e pochi.

// TODO: quando si scrive a relatore specificare che i diagrammi non ci sono perché aspetto che gli UC siano definitivi
#figure(
    image("../images/usecase/scenario-principale.png", width: 100%),
    caption: "Use Case - UC0: Scenario principale",
) <uc:scenario-principale>

#useCase(
    (
        number: 1,
        name: "Aggiunta reader RFID",
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
<uc:3>


== Tracciamento dei requisiti

// Da un'attenta analisi dei requisiti e degli ``use ``case effettuata sul progetto è stata stilata la tabella che traccia i requisiti in rapporto agli use case.

// Sono stati individuati diversi tipi di requisiti e si è quindi fatto utilizzo di un codice identificativo per distinguerli.

// Il codice dei requisiti è così strutturato R(F/Q/V)(N/D/O) dove:

// #set list(marker: none)
// - R = requisito
// - F = funzionale
// - Q = qualitativo
// - V = di vincolo
// - N = obbligatorio (necessario)
// - D = desiderabile
// - Z = opzionale

// Nelle tabelle @tab:requisiti-funzionali, @tab:requisiti-qualitativi e @tab:requisiti-vincolo sono riassunti i requisiti e il loro tracciamento con gli use case delineati in fase di analisi.

// #figure(
//     table(
//         columns: (auto, auto, auto),
//         align: (center, left, center),
//         [*Requisito*], [*Descrizione*], [*Use Case*],
//         [RFN-1], [L'interfaccia permette di configurare il tipo di sonde del test], [UC1],
//     ),
//     caption: "Tabella del tracciamento dei requisti funzionali",
// )
// <tab:requisiti-funzionali>

// #figure(
//     table(
//         columns: (auto, auto, auto),
//         align: (center, left, center),
//         [*Requisito*], [*Descrizione*], [*Use Case*],
//         [RQD-1], [Le prestazioni del simulatore hardware deve garantire la giusta esecuzione dei test e non la generazione di falsi negativi], [#sym.dash],
//     ),
//     caption:
