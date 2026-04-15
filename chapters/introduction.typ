// Non su primo capitolo
//#pagebreak(to:"odd")

// TODO: replace di tutti i KanbanBOX con KanbanBox, o viceversa
#import "../config/thesis-config.typ" : gloss

= Introduzione // 2 pagine
<cap:introduzione> 

== Organizzazione del testo
// TODO: sistemare

Il documento è strutturato in otto capitoli principali:
#set par(first-line-indent: 0pt)
+ #link(<cap:introduzione>)[*Introduzione*]: descrive il contesto e l'obbiettivo del progetto di stage;
+ #link(<cap:descrizione-stage>
)[*Descrizione dello stage*]: fornisce una descrizione dettagliata del progetto di stage, delle tecnologie utilizzate e un'analisi dei rischi che si sarebbero potuti presentare durante lo svolgimento del progetto;
+ #link(<cap:analisi-requisiti>)[*Analisi dei requisiti*]: presenta funzionalità implementate, casi d'uso e requisiti definiti dall'azienda ospitante;
+ #link(<cap:introduzione-teorica>)[*Introduzione teorica*]: espone concetti teorici, approfonditi durante lo svolgimento del progetto, utili per la comprensione del documento e mostra il processo di scelta delle tecnologie utilizzate;
+ #link(<cap:architettura>)[*Architettura*]: descrive l'architettura del sistema implementato, con particolare attenzione alla comunicazione tra i componenti;
+ #link(<cap:codifica>)[*Codifica*]: descrive e mostra, tramite l'inserimento di blocchi di codice, l'implementazione delle funzionalità sviluppate;
+ #link(<cap:verifica-validazione>)[*Verifica e validazione*]: descrive l'analisi statica del codice e le strategie di _testing_ adottate;
+ #link(<cap:conclusioni>)[*Conclusioni*]: presenta una riflessione personale sull'esperienza di stage, sui risultati raggiunti e su potenziali sviluppi futuri.  


Riguardo la stesura del testo, sono state adottate le seguenti convenzioni tipografiche:

- gli acronimi, le abbreviazioni e i termini ambigui o di uso non comune vengono definiti nel glossario, situato alla fine del presente documento; per la prima occorrenza dei termini riportati nel glossario viene utilizzato il seguente stile: #gloss("termine", <glossary>) ;
- i termini in lingua straniera o facenti parti del gergo tecnico sono evidenziati con il carattere _corsivo_.

== L'azienda
KanbanBOX S.r.l. è un'azienda con sede a Vicenza che si occupa dello sviluppo, della commercializzazione e della consulenza relativi alla piattaforma web KanbanBOX.

KanbanBOX è uno strumento progettato per supportare le aziende nell'implementazione di metodologie #gloss("Lean", <glossary-lean>) nella gestione della produzione e della logistica delle aziende.\
Più nello specifico, la piattaforma consente di tracciare e gestire lo stato dei materiali grezzi, semilavorati e finiti, durante le fasi di approvvigionamento e produzione.
Ciò è reso possibile attraverso l'utilizzo di cartellini #gloss("Kanban", <glossary-kanban>) elettronici, che permettono di identificare e tracciare i prodotti man mano che vengono consumati o resi disponibili dai processi aziendali.

== Il progetto
KanbanBOX prevede due metodi di lettura dei cartellini Kanban:
- scansione di *codici a barre*: per ogni cartellino vengono stampata un'etichetta su cui sono presenti dei codici a barre che possono essere scansionati tramite appositi lettori ottici o tramite la fotocamera di comuni dispositivi mobili; 
- lettura di chip *RFID*: per ogni cartellino viene stampata un'etichetta RFID, ovvero un'etichetta dotata di un _chip_ che può essere letto da apposite antenne RFID.

In entrambi i casi le operazioni svolte sui cartellini vengono comunicate a KanbanBOX tramite delle _#gloss("API", <glossary-api>) RESTful_ che sfruttano il protocollo HTTP per la trasmissione dei dati.
In particolare, nel caso della lettura tramite RFID, il lettore RFID mette a disposizione delle API HTTP, eseguite in locale sul lettore stesso, che consentono la comunicazione con esso. \ 
I modelli di lettori RFID utilizzati da KanbanBOX supportano anche la comunicazione tramite protocollo MQTT, un protocollo di comunicazione del livello applicativo, basato su un meccanismo _publish/subscribe_; in aggiunta i lettori implementano nativamente un metodo di connessione sicuro e pratico al servizio AWS IoT Core. \
MQTT è particolarmente adatto per la comunicazione con dispositivi _IoT_, in quanto progettato per essere meno oneroso in termini di consumo di banda e risorse computazionali rispetto a HTTP; inoltre prevede dei meccanismi di _Quality of Service (QoS)_ e di memorizzazione dei messaggi che lo rendono più affidabile in scenari in cui la connettività di rete non è necessariamente stabile.

Per questi motivi il progetto di stage si è focalizzato sulla sostituzione del protocollo HTTP con MQTT per la trasmissione dei tag letti tra lettori RFID e KanbanBOX con l'obbiettivo di migliorare l'affidabilità e l'efficienza della comunicazione; inoltre è stata prevista l'implementazione di funzionalità di configurazione dei lettori direttamente all'interno di KanbanBOX, operazioni che in precedenza dovevano essere eseguite manualmente tramite l'interfaccia web fornita dal produttore del lettore.    

Ho scelto questo progetto perché prometteva di approfondire e di maturare esperienza con temi e tecnologie che mi incuriosiscono, come l'_Internet of Things_, i protocolli di comunicazione e le infrastrutture _cloud_. Un altro fattore interessante è stato il contatto diretto e concreto con il prodotto su cui ho lavorato che ho potuto vedere all'opera in un contesti reali.