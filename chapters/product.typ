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
Per ogni _Thing_ è possibile definire degli attributi, un gruppo di appartenenza e un tipo. In questo caso si è deciso di definire gli attributi *manufacturer* e *model* che rappresentano rispettivamente il produttore e il modello del dispositivo rappresentato dalla _Thing_; attualmente questi attributi sono utilizzati per definire la *gerarchia dei topic* ma, in futuro, potrebbero essere utili per operare su insiemi di dispositivi raggruppandoli per produttore o modello. \

Al momento della creazione di una _Thing_ è necessario anche *associare un certificato*, che viene utilizzato per l'autenticazione del dispositivo rappresentato dalla _Thing_ quando questo si connette ad AWS IoT Core. \
AWS IoT permette di scegliere se generare un certificato X.509 direttamente da AWS o se utilizzare un certificato generato esternamente; dato che si è deciso di gestire, e quindi anche di creare, le _Thing_ associate ai reader registrati su KanbanBOX tramite l'SDK di AWS IoT per PHP, è risultato molto più pratico utilizzare certificati generati da AWS ottenibili e assegnabili alle _Thing_ tramite i metodi implementati dall'SDK stesso.

Ad ogni certificato viene poi associata una *policy*, ovvero un file JSON che definisce i permessi di accesso alle risorse AWS per le _Thing_ (nel nostro caso ogni certificato sarà dedicato ad una sola _Thing_) a cui è associato il certificato. \
Per l'infrastruttura di KanbanBOX sono state definite due policy:
- *_Administration_*: questa policy è associata alla _Thing_ che rappresenta il *backend di KanbanBOX*, e permette a questa di connettersi ad AWS IoT Core, pubblicare e ricevere messaggi su tutti i topic, creare e gestire le _Thing_ associate ai reader RFID, e gestire i certificati associati a queste ultime; 
    ```json
{
    "Version": "2012-10-17",
    "Statement": 
    [
        {
            "Effect": "Allow",
            "Action": [
                "iot:Publish",
                "iot:Receive",
                "iot:Republish",
                "iot:Subscribe",
                "iot:Connect",
                "iot:GetRetainedMessage",
                "iot:ListRetainedMessages",
                "iot:RetainPublish",
                "iot:CreateKeysAndCertificate",
                "iot:DeleteCertificate",
                "iot:AttachPolicy",
                "iot:DetachPolicy"
            ],
            "Resource": "*"
        }
    ]
}
    ```
- *_Connect_Publish_Subscribe_Receive_ByThingName_*: questa policy è associata ad ogni _Thing_ che rappresenta un reader RFID; in questo caso vengono usate le *variabili* messe a disposizione da *AWS IoT Core nelle policy* per ottenere, dinamicamente, parametri relativi alla connessione MQTT in corso. \ \ Di seguito è stata inserita una parte della policy dove vengono mostrati i permessi di connessione e pubblicazione (dato che gli altri permessi presenti sono analoghi a quello di pubblicazione); si può notare come per la connessione venga usata la variabile _*\${iot:Connection.Thing.ThingName}*_ per obbligare il reader a connettersi solamente usando il _clientId_ (che è equivalente al _ThingName_ su AWS) associato al certificato che sta utilizzando; infatti AWS IoT, una volta ricevuta la richiesta di connessione, verificherà che il certificato usato dal reader sia associato alla _Thing_ corrispondente al _clientId_ usato in questa fase dal reader. \ \ Il permesso di pubblicazione sfrutta anche la variabile _*\${iot:Connection.Thing.Attributes[...]}*_ per recuperare gli attributi della _Thing_, e imporre al reader di pubblicare solo sui topic a lui dedicati.
    ```json
    {
        "Version": "2012-10-17",
        "Statement": 
        [
            {
                "Effect": "Allow",
                "Action": "iot:Connect",
                "Resource": "<endpoint-arn>:client/${iot:Connection.Thing.ThingName}"
            },
            {
                "Effect": "Allow",
                "Action": "iot:Publish",
                "Resource": [
                    "arn:aws:iot:eu-north-1:396913738910:topic/${iot:Connection.Thing.Attributes[manufacturer]}/${iot:Connection.Thing.Attributes[model]}/${iot:Connection.Thing.ThingName}/*",
                    "arn:aws:iot:eu-north-1:396913738910:topic/${iot:Connection.Thing.Attributes[manufacturer]}/${iot:Connection.Thing.Attributes[model]}/events"
                ]
            },
            // altri permessi ...
        ]
    }
    ```
    L'`endpoint-arn` è un _placeholder_ che va sostituito con l'ARN dell'endpoint di AWS IoT Core utilizzato per la connessione al broker MQTT.

L'ultimo elemento necessario nell'infrastruttura progettata sono le *IoT Rule*, ovvero uno strumento che permette di *instradare i messaggi* ricevuti su determinati topic nel broker MQTT di AWS IoT Core verso altre risorse AWS. \ In questo caso è bastato configurare una sola IoT Rule che instradasse i messaggi ricevuti sul topic dedicato ai tag RFID e agli _heartbeat_ (topic che è lo stesso per tutti i reader) verso una coda SQS; così facendo abbiamo potuto implementare un worker nel backend di KanbanBOX che può estrarre i messaggi dalla cosa in modalità _pull_ e processarli.

Le _IoT Rule_ vengono configurate tramite una query in linguaggio SQL @aws-iot-sql, arricchito con delle funzioni specifiche per AWS IoT, che permette di filtrare i messaggi in ingresso e di estrarre i dati che ci interessano. Di seguito viene riportata la query utilizzata:
```sql
SELECT *, clientId() AS clientId FROM '#' WHERE topic(3) = 'events'
```
Come vediamo dalla clausola `FROM`, la query recupera i messaggi ricevuti su tutti i topic (*wildcard `#`*) e usando la clausola `WHERE`, abbinata alla *funzione `topic(n)`* che ritorna l'n-esimo livello del topic, filtra i messaggi per ottenere solo quelli ricevuti sui topic che terminano con `events`, ovvero i topic dedicati ai messaggi dei tag RFID e degli _heartbeat_; come anticipato, nel nostro caso il topic è lo stesso per tutti i reader ma si è deciso di usare una regola dinamica in caso di futuri cambiamenti nella struttura dei topic. \

Altro aspetto peculiare è l'utilizzo della *funzione `clientId()`* che, come per la funzione `topic()`, è implementata nativamente da AWS IoT; questa viene usata per integrare il _clientId_ nel payload del messaggio, così da poter identificare il reader che lo ha generato e quindi associare i dati del tag o dell'heartbeat al reader corretto direttamente dal backend di KanbanBOX, senza dover configurare un topic ed una _IoT Rule_ dedicati per ogni reader, per poi utilizzare quest'ultimi come "canali identificativi". \
In aggiunta al _clientId_, ovviamente, vengono inclusi anche tutti gli altri dati del messaggio (payload, timestamp, tipo, ...) usando *l'asterisco (`*`)*.


=== AWS SQS
// TODO: scopo già spiegato in cap4 ma controllare cosa manca, di sicuro la descrizione di tutte le entità

=== Struttura dei topic
// TODO: decidere se metterlo prima delle descrizioni di reader e AWS Iot
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