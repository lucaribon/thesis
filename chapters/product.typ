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

=== Reader RFID
I reader RFID Zebra sono dei dispositivi hardware che, se muniti di uno o più moduli esterni che fungono da antenne, sono in grado di leggere i tag RFID presenti nell'ambiente circostante. \
Per poter trasmettere dati e comandi, da e verso il reader, è necessario configurare la connessione ad un endpoint esterno; nel nostro caso, in cui la scelta del broker MQTT è ricaduta su AWS IoT Core, è stato necessario configurare un endpoint di tipo *AWS IoT Connector*, ovvero un'interfaccia implementata da Zebra nei propri reader che consente di farli comunicare con AWS IoT Core tramite MQTT, configurando un numero ridotto di parametri. \ 
La configurazione, infatti, richiede di definire:
- il _domain name_ di AWS IoT Core;
- la porta da utilizzare per la trasmissione;
- l'identificativo che si vuole usare per il dispositivo che si sta configurando;
- il certificato, già memorizzato nel reader, da utilizzare per l'autenticazione con AWS IoT Core e la relativa _passphrase_.
Inoltre i reader Zebra permettono di definire quale topic utilizzare per le seguenti macro-categorie di messaggi:
- *_management events_*: utilizzato principalmente come log di sistema e messaggi di diagnostica, nel nostro caso è utilizzato principalmente per trasmettere l'*heartbeat* del reader, ovvero un messaggio periodico che contiene diversi parametri di stato del reader;
- *_tag data events_*: utilizzato per trasmettere i dati dei tag RFID letti dal reader, è il topic più importante per il nostro sistema in quanto contiene i dati che ci interessano per la gestione dei *kanban*;
- *_management_*:
    - _command_: comandi di gestione del sistema, aggiornamenti, configurazione dell'endpoint e della connessione, ecc.;
    - _response_: risposte ai comandi sopra elencati che comunicano il successo o il fallimento e il relativo messaggio di errore;
- *_control_*:
    - _command_: comandi di controllo della lettura dei tag, quindi configurazione delle antenne come potenza, modalità di lettura, ecc.;
    - _response_: risposte ai comandi di controllo sopra elencati che comunicano il successo o il fallimento e il relativo messaggio di errore.

Una volta configurati tutti i parametri elencati il reader potrà connettersi al broker MQTT integrato in AWS IoT Core e iniziare a trasmettere i messaggi in base alla configurazione dei topic sopra descritta. \

Oltre ai parametri di connessione, anche la modalità di lettura (detta *modalità operativa*) è configurabile tramite un'apposita interfaccia web in esecuzione sui reader stessi, e quindi raggiungibile collegandosi direttamente all'IP del reader tramite un browser web; in alternativa è possibile configurare i parametri sopracitati tramite dei comandi MQTT, inviati su appositi topic configurati nel reader, che seguono uno schema JSON definito da Zebra.
Per poter configurare il reader (sia i parametri di connessione che la modalità operativa) *direttamente dall'interfaccia di KanbanBOX* abbiamo deciso di sfruttare i comandi MQTT, usando lo stesso flusso di dati MQTT utilizzato per trasmettere messaggi dei tag e di diagnostica, per questo è necessario poter trasmettere messaggi MQTT anche dal backend di KanbanBOX verso il reader, passando per AWS IoT Core. Per adempiere a questo requisito è stata sfruttata e la libreria *php-mqtt* (@php-mqtt). \

== AWS
=== AWS IoT Core
// TODO: scopo già spiegato in cap4 ma controllare cosa manca, di sicuro la descrizione di tutte le entità
Come già accennato in precedenza, AWS IoT Core è un servizio di Amazon Web Services che integra un broker MQTT e una serie di funzionalità a supporto della gestione di dispositivi IoT e della raccolta, elaborazione o distribuzione dei dati da essi generati. \

In AWS IoT ogni reader RFID è rappresentato da una *Thing*, ovvero un'entità che rappresenta un dispositivo fisico; ogni _Thing_ registrata in un account AWS è identificata da un nome univoco a livello di regione AWS.
Nell'infrastruttura di KanbanBOX avremo una _Thing_ che permette al backend di connettersi ad AWS IoT come se fosse un client MQTT in modo che questo possa inviare e ricevere i messaggi usando il broker integrato, e una _Thing_ per ogni reader RFID configurato. \
// TODO: decidere se sostituire tutti i topic con la nuova gerarchia o lasciare quelli vecchi
Per ogni _Thing_ è possibile definire degli attributi, un gruppo di appartenenza e un tipo. In questo caso si è deciso di definire un *tipo di _Thing_* per ogni modello di reader RFID, attualmente Zebra FX7500 e Zebra FX9600, in modo da poter operare su tutti i reader di uno stesso modello più comodamente nel caso in cui fosse necessario per sviluppi futuri. Inoltre è stato definito *l'attributo licenseId* per ogni _Thing_ in modo da poter salvare anche su AWS IoT, al momento della creazione dell'entità, la licenza (che identifica uno specifico cliente) in cui è configurato il reader. \

Al momento della creazione di una _Thing_ è necessario anche *associare un certificato*, che viene utilizzato per l'autenticazione del dispositivo rappresentato dalla _Thing_ quando questo si connette ad AWS IoT Core. \
AWS IoT permette di scegliere se generare un certificato X.509 direttamente da AWS o se utilizzare un certificato generato esternamente; dato che si è deciso di gestire, e quindi anche di creare, le _Thing_ associate ai reader registrati su KanbanBOX tramite l'SDK di AWS IoT per PHP, è risultato molto più pratico utilizzare certificati generati da AWS ottenibili e assegnabili alle _Thing_ tramite i metodi implementati dall'SDK stesso.

Ad ogni certificato viene poi associata una *policy*, ovvero un file JSON che definisce i permessi di accesso alle risorse AWS per le _Thing_ (nel nostro caso ogni certificato sarà associato ad una sola _Thing_) a cui è associato il certificato. \
Per l'infrastruttura di KanbanBOX sono state definite due policy:
// TODO: mettere json delle policy modificando i topic che tengono la stessa gerarchia di prima ma usando le variabili ThingName per il clientId
- *_Administration_*: ha accesso completo 
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "*",
                "Resource": "*"
            }
        ]
    }
    ```
una per backend infatti il backend è rappresentato da una thing ecc...
nelle policy di AWS è possibile usare delle variabili...in questo modo è possibile definire delle policy generiche...


=== AWS SQS
// TODO: scopo già spiegato in cap4 ma controllare cosa manca, di sicuro la descrizione di tutte le entità

=== Struttura dei topic
// TODO: scrivere dopo aver descritto per intero il flusso di reader e AWS IoT, così si possono citare le IoT Rule spiegando perché per i topic dei tag data è stata usata una gerarchia più semplice (testing/events e production/events)



= Codifica

== Design pattern utilizzati
// ?forse no?

== Gestione dei reader RFID
// TODO: descrizione dello scopo
// TODO: figure grafico UML classe/classi
// ?FE separato o unito a BE
// TODO: descrizione dettagliata di classi, campi, metodi come in specifica tecnica, con esempi di codice

== Configurazione dei reader RFID

= Ricezione dei tag RFID letti
== Architettura


== Progettazione

== Codifica
=== ReadTagEventsMessageSerializer
=== ReadTagEventsMessage
=== ReadTagEventsMessageHandler