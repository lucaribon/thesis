// TODO: capitoli di sicuro da sistemare (aggiungere/togliere/cambiare capitoli) // contenuti e lunghezza molto variabili in base all'argomento scelto, indicativamente tra le 20 e le 40 pagine (comprensive di tabelle e immagini), distribuite tra 1-3 capitoli
#pagebreak(to:"odd")

#set par(justify: false)
// = Descrizione del lavoro svolto

// ?Oppure separare architettura e progettazione?
= Architettura e progettazione
<cap:architettura>
#v(1em)
#text(style: "italic", [
    // Breve introduzione al capitolo
])

#v(1em)

== Flusso del sistema
// TODO: figure flusso del sistema
1. *Reader RFID*: dispositivo hardware che legge i tag RFID e invia i dati dei tag letti ad AWS IoT tramite il protocollo MQTT;
2. *AWS IoT*: piattaforma cloud che funge da broker MQTT, gestendo autenticazione, autorizzazione e instradamento dei messaggi tra i reader RFID e il backend di KanbanBox;
3. *AWS SQS*: servizio di code di messaggi che riceve i messaggi contenenti i dati dei tag letti da AWS IoT e li rende disponibili per il backend di KanbanBox;
4. *KanbanBOX*: backend che elabora i dati dei tag RFID ricevuti da AWS SQS per aggiornare lo stato delle schede Kanban. \ KanbanBox permette anche di gestire i reader e la loro configurazione di comunicazione con l'endpoint di AWS IoT e l'operating mode (Simple, Conveyor, Inventory, ecc.); questo avviene tramite un form raggiungibile tramite _row operation_ nella tabella dei reader.

== AWS
// IOT e SQS

=== Struttura del topic



= Codifica

== Design pattern utilizzati
// ?forse no?

== Gestione dei reader RFID
// TODO: descrizione dello scopo
// TODO: figure grafico UML classe/classi
// ?FE separato o unito a BE
// TODO: descrizione dettagliata di classi, campi, metodi come in specifica tecnica, con esempi di codice

== Configurazione dei reader RFID

== Ricezione dei tag RFID letti




= Verifica e validazione
