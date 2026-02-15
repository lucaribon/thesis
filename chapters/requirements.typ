#import "../config/thesis-config.typ": useCase
#import "../config/thesis-config.typ": gloss

#pagebreak(to: "odd")

= Analisi dei requisiti // 10-20 pagine
<cap:analisi-requisiti>
== Attori
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
- O05: Realizzazione di una demo funzionante che dimostri l’integrazione completa tra RFID,
AWS IoT Core e sistema aziendale.
• Desiderabili
- D01: Redazione della documentazione tecnica relativa all’architettura del progetto, configurazioni e utilizzo del driver.
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
// TODO: Essendo il progetto finalizzato alla creazione di un tool per l'automazione di un processo, le interazioni da parte dell'utilizzatore devono essere ovviamente ridotte allo stretto necessario. Per questi motivi i diagrammi dei casi d'uso risultano semplici e in numero ridotto.

// FIXME: integrare la figure nello use case in modo che venga mostrata sotto al titolo del caso d'uso. A MENO CHE non si decida/riesca a fare una solo figure per più use case, visto che sono molto legati e pochi.
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
        precondizioni: "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT.",
        postcondizioni: "Il reader RFID viene registrato nella piattaforma KanbanBox.",
        scenario_principale: (
            "L'amministratore inserisce i dati del reader RFID negli appositi campi di testo:
                - nome;
                - produttore;
                - modello;
                - indirizzo MAC;
                - abilitazione.",
            "L'amministratore invia i dati del reader tramite il pulsante di salvataggio.",
        ),
        estensioni: (
            "Errore: sistema non raggiungibile",
            "Errore: servizi cloud esterni non raggiungibili",
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
            "Il reader RFID è configurato per poter comunicare in rete e con AWS IoT.",
            "Il reader RFID è già registrato nella piattaforma KanbanBox.",
        ),
        postcondizioni: (
            "Il sistema ha aggiornato i dati del reader RFID nella piattaforma KanbanBox.",
        ),
        scenario_principale: (
            "L'amministratore, dalla tabella dei reader, preme il bottone per modificare i dati del reader scelto.",
            "L'amministratore modifica i dati del reader RFID negli appositi campi di testo:
                - nome;
                - produttore;
                - modello;
                - indirizzo MAC;
                - abilitazione.",
            ".",
            "L'amministratore invia i dati aggiornati del reader tramite il pulsante di salvataggio.",
        ),
    ),
)
<uc:2>

#useCase(
    (
        number: 2,
        name: "Configurazione reader RFID",
        "Attore principale": "Sviluppatore applicativi",
        "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
        "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
        "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione",
        Inclusioni: (
            "Inserimento configurazione di sistema del reader RFID",
            "Inserimento configurazione della modalità operativa del reader RFID",
            "Scelta dell'ambiente in cui il reader deve comunicare i dati dei cartellini",
        ),
    ),
)
<uc:1>

#useCase(
    (
        number: 99,
        name: "Inserimento configurazione di sistema del reader RFID",
    ),
)
<uc:1>

#useCase(
    (
        number: 99,
        name: "Inserimento configurazione della modalità operativa del reader RFID",
    ),
)
<uc:1>

#useCase(
    (
        number: 99,
        name: "Scelta dell'ambiente in cui il reader deve comunicare i dati dei cartellini",
    ),
)
<uc:1>

#useCase(
    (
        number: 3,
        name: "Eliminazione reader RFID",
        "Attore principale": "Sviluppatore applicativi",
        "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
        "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
        "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione",
    ),
)
<uc:2>

#useCase(
    (
        number: 4,
        name: "Download del certificato associato al reader",
        "Attore principale": "Sviluppatore applicativi",
        "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
        "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
        "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione",
    ),
)
<uc:3>

#useCase(
    (
        number: 99,
        name: "Visualizzazione dei cartellini letti dal reader",
        generalizzazioni: (
            "Visualizzazione dei cartellini processati",
            "Visualizzazione dei cartellini scartati",
        ),
    ),
)
<uc:3>


#useCase(
    (
        number: 99,
        name: "Errore: sistema non raggiungibile",
    ),
)
<uc:3>

#useCase(
    (
        number: 99,
        name: "Errore: servizi cloud esterni non raggiungibili",
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
//     caption: "Tabella del tracciamento dei requisti funzionali",
// )
// <tab:requisiti-qualitativi>

// #figure(
//     table(
//         columns: (auto, auto, auto),
//         align: (center, left, center),
//         [*Requisito*], [*Descrizione*], [*Use Case*],
//         [RVQ-1], [La libreria per l'esecuzione dei test automatici deve essere riutilizzabili], [#sym.dash],
//     ),
//     caption: "Tabella del tracciamento dei requisti funzionali",
// )
// <tab:requisiti-vincolo>
                                                                                                                                 
