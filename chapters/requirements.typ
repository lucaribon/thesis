#import "../config/thesis-config.typ": useCase

#pagebreak(to:"odd")

= Analisi dei requisiti // 10-20 pagine
<cap:analisi-requisiti>
== Attori
*Sistema di lettura RFID*: rappresenta l'insieme di dispositivi hardware che si occupano di leggere e trasmettere le informazioni dei tag RFID che attraversano la loro area di copertura.

*Amministratore*: nel backend di KanbanBOX sono presenti diversi ruoli utilizzati per definire i permessi all'interno della piattaforma. Nonostante ciò, le funzionalità che ho implementato sono accessibili in egual modo da tutti i ruoli da sviluppatore, amministratore o supporto applicativo, poiché è necessario che possano essere utilizzate da qualsiasi figura tecnica che si occupi di sviluppo o manutenzione dell'applicativo.\ 
Per questo motivo, in questa sede, ho deciso di raggruppare tutti i ruoli al di sotto dell'attore "Amministratore".

== Casi d'uso
Per lo studio dei casi di utilizzo del prodotto sono stati creati dei diagrammi.
I diagrammi dei casi d'uso (in inglese _Use Case Diagram_) sono diagrammi di tipo UML dedicati alla descrizione delle funzioni o servizi offerti da un sistema, così come sono percepiti e utilizzati dagli attori che interagiscono col sistema stesso.
Essendo il progetto finalizzato alla creazione di un tool per l'automazione di un processo, le interazioni da parte dell'utilizzatore devono essere ovviamente ridotte allo stretto necessario. Per questi motivi i diagrammi dei casi d'uso risultano semplici e in numero ridotto.

#figure(
    image("../images/usecase/scenario-principale.png", width: 100%),
    caption: "Use Case - UC0: Scenario principale"
) <uc:scenario-principale>

// L'ordine e i nomi delle chiavi sono arbitrari, vedere la funzione nel file ..config/thesis-config.typ
#useCase(
    (
        number: 0,
        name: "Aggiunta reader RFID",
        "Attore principale": "Sviluppatore applicativi",
        "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
        "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
        "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione"
    )
)
<uc:0>

#useCase(
    (
        number: 1,
        name: "Configurazione reader RFID",
        "Attore principale": "Sviluppatore applicativi",
        "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
        "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
        "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione"
    )
)
<uc:1>

#useCase(
  (
      number: 2,
      name: "Eliminazione reader RFID",
      "Attore principale": "Sviluppatore applicativi",
      "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
      "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
      "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione",
  )
)
<uc:2>

#useCase(
    (
        number: 3,
        name: "Download del certificato associato al reader",
        "Attore principale": "Sviluppatore applicativi",
        "Precondizioni": "Lo sviluppatore è entrato nel plug-in di simulazione all'interno dell'IDE",
        "Postcondizioni": "Il sistema ha salvato la configurazione del test automatico",
        "Scenario principale": "Lo sviluppatore configura i parametri del test automatico tramite l'interfaccia grafica e salva la configurazione",
    ),
)
<uc:3>


== Tracciamento dei requisiti

// Da un'attenta analisi dei requisiti e degli use case effettuata sul progetto è stata stilata la tabella che traccia i requisiti in rapporto agli use case.

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

== Panoramica funzionalità