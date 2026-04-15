#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "../config/thesis-config.typ": gloss

#show: codly-init.with()
#codly(languages: (php: (name: "PHP")))

// contenuti e lunghezza molto variabili in base all'argomento scelto, indicativamente tra le 20 e le 40 pagine (comprensive di tabelle e immagini), distribuite tra 1-3 capitoli
#pagebreak(to: "odd")

#set par(justify: false)

= Architettura e progettazione
<cap:architettura>

== Flusso del sistema
<cap:flusso-del-sistema>
#figure(
    image("../images/data_flow_diagram.png"),
    caption: "Flusso del sistema",
)


=== RFID Reader
<cap:rfid-reader>
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
Per poter configurare il reader (sia i parametri di connessione che la modalità operativa) *direttamente dall'interfaccia di KanbanBOX* abbiamo deciso di sfruttare i comandi MQTT, usando lo stesso flusso di dati MQTT utilizzato per trasmettere messaggi dei tag e di diagnostica, per questo è necessario poter trasmettere messaggi MQTT anche dal backend di KanbanBOX verso i reader, passando per AWS IoT Core. Per adempiere a questo requisito è stata sfruttata e la libreria *php-mqtt* (@php-mqtt). \

Nel dominio di KanbanBOX ogni reader RFID può essere associato ad una o più *aree*; ogni area rappresenta un insieme di una o più *antenne RFID*.\
In questo modo si riescono a rappresentare, dal punto di vista della logica di dominio, le antenne fisiche installate nelle linee di produzione che vengono collegate ai reader RFID. \
Inoltre ad ogni area viene associato un *cambio stato* @stati-kanban del cartellino, di conseguenza, nella logica di dominio, basterà associare l'antenna che ha eseguito la lettura all'area corrispondente (tramite le relazioni definite a DB) per poter associare le letture dei tag ad un cambio stato del cartellino kanban.

=== Struttura dei topic
<cap:struttura-topic>
La struttura dei topic è stata *standardizzata* in modo da poterla replicare per tutti i reader senza incorrere in problemi di incongruenza tra le varie configurazioni.

Nei primi livelli della struttura sono stati sfruttati nome del *produttore* e del *modello* del dispositivo così da poter raggrupparli basandosi su dei parametri potenzialmente utili, dato che in un futuro potrebbe essere necessario poter operare su insiemi di dispositivi usando una _wildcard_ simile a questa "`<manufacturer>/<model>/#`" senza, quindi, essere costretti ad utilizzare un numero elevato di topic più specifici.

Successivamente, per alcuni canali di comunicazione, è stato aggiunto l'*identificativo* del dispositivo; questo perché per le categorie di messaggi `management` e `control` è necessario, per il backend di KanbanBOX, poter leggere la risposta ad un comando inviato ad un dispositivo specifico per poter dare un feedback corretto all'utente, quindi la soluzione più conveniente è stata quella di usare un topic dedicato per ogni dispositivo, così da poter rimanere in ascolto sul topic di risposta usato dal dispositivo. \ Rimane comunque possibile usare una _wildcard_ per operare raggruppando i dispositivi per produttore e modello.

Infine, all'ultimo livello della gerarchia si trova la *macro-categoria di messaggi* per cui quel topic viene utilizzato.

Di seguito viene riportata la struttura dei topic attualmente in uso, associata alla categoria del topic per cui viene usata:
- *_management events_* e *_tag data events_*: `<manufacturer>/<model>/events`, in questo caso si è deciso di usare un solo topic per entrambe le categorie di messaggi dato che tramite la _IoT Rule_ implementata [@cap:aws-iot-core] il _clientId_ viene incluso nel payload del messaggio prima di essere inserito nella coda SQS; così facendo di evita di dover configurare due _rule_ diverse per instradare le due categorie di messaggi verso la stessa coda;
- *_management_*: come già accennato, è necessario usare dei topic dedicati per ogni dispositivo dato che è necessario leggere le risposte ai comandi inviati
    - `<manufacturer>/<model>/<clientId>/management_commands`
    - `<manufacturer>/<model>/<clientId>/management_responses`
- *_control_*: anche in questo caso sono necessari dei topic dedicati
    - `<manufacturer>/<model>/<clientId>/control_commands`
    - `<manufacturer>/<model>/<clientId>/control_responses`

=== AWS IoT Core
<cap:aws-iot-core>
Come già accennato in precedenza, AWS IoT Core è un servizio di Amazon Web Services che integra un broker MQTT e una serie di funzionalità a supporto della gestione di dispositivi IoT e della raccolta, elaborazione o distribuzione dei dati da essi generati. \

In AWS IoT ogni reader RFID è rappresentato da una *_Thing_*, ovvero un'entità che rappresenta un dispositivo fisico; ogni _Thing_ registrata in un account AWS è identificata da un nome univoco a livello di regione AWS.
Nell'infrastruttura di KanbanBOX avremo una _Thing_ che permette al backend di connettersi ad AWS IoT come se fosse un client MQTT in modo che questo possa inviare e ricevere i messaggi usando il broker integrato, e una _Thing_ per ogni reader RFID configurato. \
Per ogni _Thing_ è possibile definire degli attributi, un gruppo di appartenenza e un tipo. In questo caso si è deciso di definire gli attributi *manufacturer* e *model* che rappresentano rispettivamente il produttore e il modello del dispositivo rappresentato dalla _Thing_; attualmente questi attributi sono utilizzati per definire la *struttura dei topic* [@cap:struttura-topic] ma, in futuro, potrebbero essere utili per operare su insiemi di dispositivi raggruppandoli per produttore o modello. \

Al momento della creazione di una _Thing_ è necessario anche *associare un certificato*, che viene utilizzato per l'autenticazione del dispositivo rappresentato dalla _Thing_ quando questo si connette ad AWS IoT Core. \
AWS IoT permette di scegliere se generare un certificato X.509 direttamente da AWS o se utilizzare un certificato generato esternamente; dato che si è deciso di gestire, e quindi anche di creare, le _Thing_ associate ai reader registrati su KanbanBOX tramite l'SDK di AWS IoT per PHP, è risultato molto più pratico utilizzare certificati generati da AWS ottenibili e assegnabili alle _Thing_ tramite i metodi implementati dall'SDK stesso.

Ad ogni certificato viene poi associata una *policy*, ovvero un file JSON che definisce i permessi di accesso alle risorse AWS per le _Thing_ (nel nostro caso ogni certificato sarà dedicato ad una sola _Thing_) a cui è associato il certificato. \
Per l'infrastruttura di KanbanBOX sono state definite due policy:
- *_Administration_*: questa policy è associata alla _Thing_ che rappresenta il *backend di KanbanBOX*, e permette a questa di connettersi ad AWS IoT Core, pubblicare e ricevere messaggi su tutti i topic, creare e gestire le _Thing_ associate ai reader RFID, e gestire i certificati e le policy
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
- *_Connect_Publish_Subscribe_Receive_ByThingName_*: questa policy è associata ad ogni _Thing_ che rappresenta un reader RFID; in questo caso vengono usate le *variabili* messe a disposizione da *AWS IoT Core nelle policy* per ottenere, dinamicamente, parametri relativi alla connessione MQTT in corso. \ \ Di seguito è stata inserita una parte della policy dove vengono mostrati solamente i permessi di connessione e pubblicazione (dato che gli altri permessi presenti sono analoghi a quello di pubblicazione); si può notare come per la connessione venga usata la variabile _*\${iot:Connection.Thing.ThingName}*_ per obbligare il reader a connettersi solamente usando il _clientId_ (che è equivalente al _ThingName_ su AWS) associato al certificato che sta utilizzando; infatti AWS IoT, una volta ricevuta la richiesta di connessione, verificherà che il certificato usato dal reader sia associato alla _Thing_ corrispondente al _clientId_ usato in questa fase dal reader. \ \ Il permesso di pubblicazione sfrutta anche la variabile _*\${iot:Connection.Thing.Attributes[...]}*_ per recuperare gli attributi della _Thing_, e imporre al reader di pubblicare solo sui topic a lui dedicati.
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
                    "<endpoint-arn>:topic/${iot:Connection.Thing.Attributes[manufacturer]}/${iot:Connection.Thing.Attributes[model]}/${iot:Connection.Thing.ThingName}/*",
                    "<endpoint-arn>:topic/${iot:Connection.Thing.Attributes[manufacturer]}/${iot:Connection.Thing.Attributes[model]}/events"
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
In aggiunta al _clientId_, ovviamente, vengono inclusi anche tutti gli altri dati del messaggio (_payload_, _timestamp_, tipo, ...) usando *l'asterisco (`*`)*.


=== AWS SQS
AWS *Simple Queue Service* (SQS) è un servizio di *message queuing* che consente di stabilire una comunicazione *asincrona* tra componenti di un sistema software, introducendo una coda persistente tra chi produce eventi e chi li elabora. La coda è detta *asincrona* perché il componente che produce l'evento non deve conoscere né contattare direttamente il destinatario; infatti il messaggio viene pubblicato nella coda e l'elaborazione avviene in un secondo momento, quando il "componente consumatore" (nel nostro caso il worker) legge i messaggi disponibili.
Nel sistema descritto, SQS viene impiegato come coda di transito per i messaggi ricevuti su AWS IoT Core: una _IoT Rule_ [@cap:aws-iot-core] instrada i messaggi, in formato *JSON*, pubblicati sul topic `<manufacturer>/<model>/events` verso la coda SQS, mantenendo quindi separati la trasmissione tramite MQTT e il consumo dei messaggi.

L'uso della coda introduce due vantaggi principali:
- *buffering*: se il worker non riesce a processare i messaggi alla stessa velocità con cui vengono prodotti, questi si accumulano nella coda senza andare persi. Questo permette di assorbire picchi temporanei nel traffico mantenendo stabile il resto del sistema.
- *persistenza*: i messaggi vengono memorizzati da SQS per un periodo configurabile (7 giorni in questa implementazione), rendendo possibile la consegna anche in presenza di indisponibilità temporanee del worker.

Dal punto di vista del modello di consegna, SQS permette una modalità di consumo *_pull_*: il worker, utilizzando l'SDK AWS per PHP @aws-sqs-sdk-php, interroga periodicamente la coda e recupera i messaggi disponibili.
Questo approccio è utile anche per gestire casi in cui un messaggio, una volta letto, non venga effettivamente considerato d'interesse (ad esempio in caso di eccezione per tipi di messaggi non gestiti lato backend); in questi casi il messaggio non viene confermato come consumato (cioè rimosso dalla coda), e può tornare nuovamente disponibile in coda.\
Nei casi in cui il messaggio sia malformato o contenga dati incompleti, invece, il worker lo consuma e lo scarta, evitando che possa essere processato più volte.

Come parzialmente anticipato nella descrizione della struttura dei topic [@cap:struttura-topic], per i messaggi di tipo `management` e `control` è sorta la necessità di poter leggere le risposte ai comandi inviati ai reader, e quindi di gestire le risposte in modo sincrono per poter dare un feedback immediato all'utente. \ Per questo motivo si è deciso di utilizzare la coda SQS solamente per i messaggi di dati dei tag e heartbeat e di gestire i messaggi di tipo `management` e `control` direttamente tramite MQTT.

Infine, l'accesso alla coda è regolato tramite *IAM*, infatti è stato creato un ruolo IAM con permessi per scrivere e leggere dalla coda SQS configurata. Questo stesso ruolo è stato associato alla _IoT Rule_ per permettergli l'inserimento dei messaggi in coda, e viene usato dal worker di KanbanBOX per permettergli di leggere i messaggi dalla coda; in questo modo si garantisce che solo questi due componenti possano interagire con la coda, e quindi si mantiene un livello di sicurezza adeguato.

=== KanbanBOX
KanbanBOX è il software gestionale, sviluppato dall'omonima azienda ospitante, che ha lo scopo di facilitare il monitoraggio e la gestione dei processi produttivi e logistici attraverso l'uso di *kanban* digitali che vengono associati a specifici tag RFID. \

La piattaforma web di KanbanBOX comunica in tre direzioni distinte nel flusso dei dati relativo al dominio dei reader RFID.

La prima riguarda il *_polling_ dei messaggi* dei tag RFID e degli heartbeat, che tramite l'SDK di AWS (usando il protocollo *HTTP* per le chiamate), vengono estratti dalla coda SQS e processati, da un worker dedicato. \
Il processamento consiste  nel distinguere la tipologia di messaggio ricevuto e nell'estrazione dei dati rilevanti da esso; nel caso dei messaggi dei tag RFID i dati di interesse sono principalmente l'identificativo del tag letto, il timestamp di lettura, il reader che ha generato il messaggio e i dati tecnici di lettura (#gloss("RSSI", <glossary-RSSI>), antenna, numero di letture, ecc.), questi vengono poi utilizzati per aggiornare lo stato del *kanban* associato a quel tag, se esistente, e per mostrare la lettura del cartellino nella dashboard dei tag letti. \
Mentre per i messaggi di heartbeat i dati di interesse sono l'identificativo del reader e il timestamp di ricezione del messaggio, utilizzati per *aggiornare lo stato di connessione* del reader in modo da informare l'utente sull'operatività del reader stesso.

Il secondo flusso di dati riguarda la *configurazione dei reader* tramite l'interfaccia web di KanbanBOX, che tramite il protocollo MQTT invia comandi ai reader per configurare i parametri di connessione e la modalità operativa e riceve l'esito dell'applicazione dei comandi dai reader. \
Tutti i dati riguardanti a questo flusso passano per il broker *MQTT* di AWS IoT Core, attraverso i topic descritti nella sezione dedicata alla struttura dei topic [@cap:struttura-topic].

L'ultimo flusso è relativo alla comunicazione verso AWS IoT Core tramite l'SDK di AWS per PHP, che viene utilizzato principalmente per la *gestione delle entità di AWS IoT* Core, in particolare per la ricezione del certificato e delle chiavi necessari per la generazione del file PFX.


= Codifica
<cap:codifica>

== Design pattern utilizzati
=== Repository
Il *Repository pattern* è un pattern architetturale che astrae l'accesso ai dati (principalmente contenuti in un DB) e fornisce un'interfaccia che semplifica le operazioni di lettura/scrittura, nascondendo dettagli come query SQL, ORM o filesystem. L'obiettivo principale è *separare* la logica di business dalla logica di persistenza, mantenendo il codice più testabile e manutenibile.

Nel codice mostrato viene usato in più punti:
- *`RfidReaderRepository`* viene utilizzato per recuperare i dati del reader a partire dal suo id (ad es. in `RfidDownloadCertificate::handle(...)` e in `DeleteRfidReaderRow::execute(...)`). In entrambi i casi la logica non contiene query o accesso diretto al DB ma si limita ad interrogare il repository e ad applicare la logica di business;
- *`RfidScanRepository`* viene usato in `RfidEventsMessageHandler` per salvare l'evento `RfidScan` dopo la validazione (`store($event)`), mantenendo l'handler focalizzato sul ricezione e validazione dei dati letti.

=== Dependency Injection
La *Dependency Injection* (DI) è un design pattern in cui un oggetto non crea autonomamente le proprie dipendenze, ma le riceve da un _container_, ovvero una classe dedicata a questo scopo. In questo modo si riduce l'accoppiamento tra componenti e si ottiene un codice più modulare e testabile.

Nel progetto la DI è gestita principalmente tramite il *Container di Symfony*: il suo scopo è definire *come istanziare* tutti gli oggetti dell'applicazione e *quali dipendenze* debbano ricevere. In pratica, il container descrive il grafo delle dipendenze e si occupa di costruire i servizi nel momento in cui servono, rispettando l'ordine corretto e riusando le istanze quando previsto.

In realtà, come già detto, viene utilizzato nella creazione di sostanzialmente tutte le classi che verranno descritte in questo documento ma nel codice mostrato risulta evidente quando si parla della classe *`Container`* dove viene configurato tutto ciò che serve per eseguire il consumo dei messaggi da SQS. In particolare:
- viene costruito il receiver SQS tramite `AwsSqsFactory->buildReceiver(...)`, a cui viene passato il serializer `RfidEventsMessageSerializer` (anch'esso costruito con le sue dipendenze, come `Clock` e `LoggerInterface`);
- viene istanziato `ConsumeMessagesCommand`, iniettandogli oggetti già pronti come `RoutableMessageBus`, il receiver locator, l'`EventDispatcher` e il `Logger`.


=== Factory
Il *Factory pattern* raccoglie la logica di creazione di oggetti in metodi dedicati, così da:
- evitare costruttori troppo complessi "sparsi" nel codice chiamante;
- centralizzare regole di costruzione e default;
- rendere più semplice cambiare implementazioni o parametri in futuro.

Nel codice si vede in:
- *`AwsSqsFactory`* è una _factory class_ che implementa diversi metodi per creare istanze di oggetti atte ad interagire in diverse modalità (ad es. code standard o FIFO) con le code SQS; in questo progetto è stato usato il metodo `buildReceiver(...)` capace di eseguire del _polling_ da una coda SQS standard;
- *`UpdateReaderCommand::forConfiguration(...)`* e *`UpdateReaderCommand::consumeCertificate(...)`* sono _factory method_, infatti invece di avere un unico costruttore con molti parametri opzionali, si espone un metodo che indica lo scopo specifico;
- *`ReaderReportContainsHeartbeat::raise(...)`* e *`ReaderReportContainsHeartbeat::from(...)`* sono _factory method_ per creare l'evento assegnando `raisedAt` tramite `Clock` o ricostruendolo da dati serializzati.

=== Command
<cap:command-pattern>
Il *Command pattern* rappresenta un'azione sotto forma oggetto: un comando contiene i dati necessari per eseguire un'operazione, e viene processato da un componente dedicato (*`CommandBus`*). Questo favorisce separazione tra chi *richiede* l'azione e chi la *esegue*, oltre a rendere più modulare l'utilizzo delle operazioni implementate.

Nel codice è usato:
- nella *gestione reader*, operazioni come aggiunta/aggiornamento/rimozione vengono delegate a comandi (`AddReaderCommand`, `UpdateReaderCommand`, `RemoveReaderCommand`);
- nel *flusso dei messaggi*, l'handler degli eventi heartbeat traduce l'evento in un comando `UpdateLastHeartbeatOfTheReaderCommand`, che poi viene eseguito via `CommandBus` per aggiornare il DB.
- lato *worker*, `ConsumeMessagesCommand` incapsula il consumo dei messaggi dalla coda e la loro elaborazione, delegando l'instradamento al bus.

=== Handler
Il termine *Handler* viene usato per indicare un componente che gestisce un input e compie delle operazioni di conseguenza; può trattarsi di una richiesta HTTP (*`RequestHandler`*), di un messaggio asincrono (*`MessageHandler`*), o dell'esecuzione di un comando (non mostrato esplicitamente ma presente in alcune implementazioni nel *`CommandBus`*).

Nel progetto abbiamo:
- *`RfidDownloadCertificate implements RequestHandlerInterface`* gestisce una richiesta HTTP, recupera dati dal repository, interagisce con filesystem e comandi, e infine costruisce una `Response` con gli header corretti per il download;
- *`RfidEventsMessageHandler implements MessageHandler`* che gestisce i messaggi decodificati dalla coda SQS; in base al tipo ricevuto (`ReportEventsMessage` o `RfidScan`) decide come gestirlo e che cosa restituire.

== Gestione dei reader RFID
=== AwsIotClientImplementation
*`AwsIotClientImplementation`* è un componente che implementa l'interfaccia `AwsIotClient` e fa da *_wrapper/adapter_* verso l'SDK di AWS IoT Core per PHP. \
L'obiettivo è fornire al resto dell'applicazione un'API adatta all'uso nel contesto di KanbanBOX.

I metodi esposti corrispondono alle operazioni necessarie per gestire le entità AWS IoT legate a un reader RFID:
- `__construct(AwsIotConfig $iotConfig)`: inizializza il client AWS con region e credenziali lette dai metodi statici di configurazione (forniti da delle classi dedicate e separate per ambiente di esecuzione);
- `createThing(...)`: crea una _Thing_ (una per reader) valorizzando gli attributi utili (es. manufacturer/model/version);
- `updateThing(...)`: aggiorna gli attributi di una _Thing_ esistente;
- `deleteThing(...)`: elimina la _Thing_ associata al reader;
- `createCertificate()`: genera un certificato X.509 e la relativa key pair, restituendo il `Result` dell'SDK (contenente arn e file pem di certificato e chiavi);
- `deleteCertificate(...)`: disattiva un certificato (operazione richiesta da AWS prima della cancellazione) e lo elimina definitivamente da AWS IoT;
- `attachPrincipalPolicy(...)`: associa una policy IoT a un certificato (principal);
- `detachPrincipalPolicy(...)`: rimuove l'associazione tra policy e certificato;
- `listThingPrincipals(...)`: recupera la lista dei certificati attualmente associati alla _Thing_ del reader;
- `attachThingPrincipal(...)`: associa un certificato alla _Thing_ del reader (con possibilità di definire se il certificato è exclusive o non-exclusive);
- `detachThingPrincipal(...)`: rimuove l'associazione tra certificato e _Thing_.

```php
<?php
final class AwsIotClientImplementation implements AwsIotClient
{
    public function __construct(
        AwsIotConfig $iotConfig,
    ) {}

    public function createThing(
        RfidReaderId $clientId,
        RfidReaderManufacturer $manufacturer,
        RfidReaderModel $model,
    ): void {}

    public function updateThing(
        RfidReaderId $clientId,
        RfidReaderManufacturer $manufacturer,
        RfidReaderModel $model,
    ): void {}

    public function deleteThing(RfidReaderId $clientId): void {}

    public function createCertificate(): Result {}

    public function deleteCertificate(string $certificateId): void {}

    public function attachPrincipalPolicy(string $certificateArn, AwsIotPolicy $policyName): void {}

    public function detachPrincipalPolicy(string $certificateArn, AwsIotPolicy $policyName): void {}

    public function listThingPrincipals(RfidReaderId $clientId): array {}

    public function attachThingPrincipal(
        RfidReaderId $clientId,
        string $certificateArn,
        bool $isExclusive,
    ): void {}

    public function detachThingPrincipal(RfidReaderId $clientId, string $certificateArn): void {}
}
```

=== MqttClientAws
*MqttClientAws* è un'implementazione dell'interfaccia `MqttClient` che funge da _wrapper/adapter_ verso la libreria *php-mqtt* (@php-mqtt) per fornire un'implementazione più completa e semplice da usare all'interno di KanbanBOX.

Il *costruttore* riceve come parametri due DTO contenenti tutti i parametri di configurazione e connessione necessari per un client MQTT.

I metodi *`connect()`* e *disconnect()* non sono altro che dei _wrapper_ che semplificano la chiamata degli omonimi metodi della libreria `php-mqtt` passando di default i parametri di connessione.

Il metodo *`publish(...)`* si occupa di pubblicare un messaggio su un topic specificato e di rimanere in ascolto su un topic di risposta per un tempo definito, così da poter restituire l'esito dell'operazione al chiamante; durante questo periodo di ascolto viene eseguita una _callable_, passata come parametro la metodo `publish(...)` della libreria, che itera su ogni messaggio ricevuto ed esegue un _early interrupt_ se la risposta è quella attesa. Questo metodo è particolarmente utile per inviare comandi ai reader e ricevere una risposta sincrona. \
Per la ricezione delle risposte si sfrutta il metodo `publish(...)` che non fa altro che configurare un _loop_ durante il quale eseguire la _callable_ fornita e semplificare la chiamata al metodo `subscribe()` della libreria adattandolo al caso d'uso di KanbanBOX. \
Nonostante l'implementazione dei due metodi precedenti possa risultare ambigua, in #link("https://github.com/php-mqtt/client/issues/214
", "questa issue") aperta nella repository della libreria `php-mqtt` si è cercato di verificare che non ci fossero metodi migliori per raggiungere il nostro scopo e il proprietario della repository stesso ha suggerito di procedere definendo un _loop_.

Abbiamo poi il metodo *`publishCommandInTopic(...)`* che è un _helper_ che gestisce il publish e il subscribe dei comandi usati per configurare i reader assolvendo l'onere di costruire i topic corretti in base alla struttura definita [@cap:struttura-topic] e al formato del messaggio. \
Compie un ruolo simile il metodo *`setTagReading(...)`* che si occupa di inviare comandi di avvio o interruzione della lettura dei tag ai reader. \
In entrambi i metodi viene restituito l'esito e, nel caso fosse presente, il messaggio di errore ritornato dai reader.

```php
<?php
class MqttClientAws implements MqttClient
{
    private PhpMqttClient $mqttClient;

    public function __construct(
        private readonly ConnectionSettings $connectionSettings,
        MqttConfig $mqttConfig,
    ) {
        $this->mqttClient = new PhpMqttClient(
            $mqttConfig->brokerDomain,
            $mqttConfig->port,
            $mqttConfig->kanbanBoxThingUuid,
            PhpMqttClient::MQTT_3_1_1,
        );
    }

    public function connect(): void
    {
        $this->mqttClient->connect($this->connectionSettings);
    }

    public function publish(string $topic, string $responseTopic, ZebraCommand $command): bool|string
    {
        $this->mqttClient->publish($topic, $command->toString(), PhpMqttClient::QOS_AT_LEAST_ONCE);

        $sentCommandId = $command->commandId;

        $response = null;
        $this->subscribe(
            $responseTopic,
            function (string $topic, string $message) use (&$response, $sentCommandId): void {
                $response = json_decode($message, true, flags: JSON_THROW_ON_ERROR);

                if (($response['command_id'] ?? null) !== $sentCommandId) {
                    $response = null;

                    return;
                }

                $this->mqttClient->interrupt();
            },
            15,
        );

        if ($response === null) {
            return 'No response received within the timeout period.';
        }
        $decodedResponse = $response;
        return ($decodedResponse['response'] ?? null) === 'success' ? true : ($decodedResponse['payload']['message'] ?? 'Unknown error');
    }

    public function subscribe(string $topic, callable $callback, float|null $timeOutSeconds = null): void
    {
        if ($timeOutSeconds !== null) {
            $this->mqttClient->registerLoopEventHandler(static function (PhpMqttClient $client, float $elapsedTimeSeconds) use ($timeOutSeconds): void {
                if ($elapsedTimeSeconds < $timeOutSeconds) {
                    return;
                }

                $client->interrupt();
            });
        }

        $this->mqttClient->subscribe(
            $topic,
            $callback,
            PhpMqttClient::QOS_AT_LEAST_ONCE,
        );

        $this->mqttClient->loop(false);
    }

    public function publishCommandInTopic(
        TopicLeaf $publishTopicLeaf,
        TopicLeaf $responseTopicLeaf,
        ZebraCommand $command,
        RfidReaderManufacturer $readerManufacturer,
        RfidReaderModel $readerModel,
        RfidReaderId $readerId,
        RfidImplementationVersion $rfidImplementationVersion = RfidImplementationVersion::V1,
    ): bool|string {
        $publishTopic = sprintf(
            '%s/%s/%s/%s/%s',
            $rfidImplementationVersion->value,
            $readerManufacturer->getValue(),
            $readerModel->getValue(),
            $readerId,
            $publishTopicLeaf->value,
        );

        $subscribeTopic = sprintf(
            '%s/%s/%s/%s/%s',
            $rfidImplementationVersion->value,
            $readerManufacturer->getValue(),
            $readerModel->getValue(),
            $readerId,
            $responseTopicLeaf->value,
        );

        return $this->publish($publishTopic, $subscribeTopic, $command);
    }

    public function disconnect(): void
    {
        $this->mqttClient->disconnect();
    }

    public function setTagReading(
        RfidReader $reader,
        ZebraCommands $command,
        DateTimeImmutable $now,
        RfidImplementationVersion $rfidImplementationVersion = RfidImplementationVersion::V1,
    ): bool|string {
        return $this->publishCommandInTopic(
            TopicLeaf::Controls,
            TopicLeaf::ControlsResponses,
            new ZebraCommand(
                $command,
                $now,
                '{}',
            ),
            RfidReaderManufacturer::from($reader->getManufacturer()->value),
            RfidReaderModel::from($reader->getModel()->value),
            $reader->getId(),
            $rfidImplementationVersion,
        );
    }
}
```

=== SetupNewReaderOnAwsIot
<cap:setup-new-reader-on-aws-iot>
Il servizio *`SetupNewReaderOnAwsIot`* si occupa di eseguire tutte le operazioni necessarie per creare e configurare una nuova _Thing_ su AWS IoT Core associata al reader RFID che si sta aggiungendo su KanbanBOX.
Inoltre si occupa di gestire il _rollback_ nel caso in cui una qualsiasi delle operazioni fallisca, così da mantenere la coerenza tra AWS IoT Core e il database di KanbanBOX evitando di lasciare entità orfane o non completamente configurate su AWS; in questi casi viene ritornato un oggetto che implementa  `ErrorCreatingEntity` che permette di gestire in modo più granulare i feedback di errore da dare all'utente.
Se la creazione va a buon fine ritorna un DTO che contiene tutti i dati necessari per la generazione del certificato PFX.

Per assolvere al suo scopo, `SetupNewReaderOnAwsIot` utilizza i metodi di *`AwsIotClientImplementation`*.

```php
<?php
final readonly class SetupNewReaderOnAwsIot implements SetupNewReaderOnExternalPlatform
{
    public function __construct(
        private AwsIotClient $awsIotClient,
        private GetConfig $getConfig,
        private LoggerInterface $logger,
    ) {
    }

    public function __invoke(
        RfidReaderId $readerId,
        RfidReaderManufacturer $manufacturer,
        RfidReaderModel $model,
    ): ErrorCreatingEntity|IotCertificate {
        try {
            $this->awsIotClient->createThing(
                $readerId,
                $manufacturer,
                $model,
            );
        } catch (Throwable $e) {
            $this->logError($e, $readerId);

            return new ErrorCreatingThing();
        }

        try {
            $awsCertificate          = $this->awsIotClient->createCertificate();
            $rootCaCertificateContent = file_get_contents($this->getConfig->getAmazonRootCaCertificateFilePath());
            $certificate = new IotCertificate(
                $awsCertificate['certificateId'],
                $awsCertificate['certificateArn'],
                $awsCertificate['certificatePem'],
                $awsCertificate['keyPair']['PrivateKey'],
                $this->getConfig->getPfxCertificateEncryptionKey(),
                $rootCaCertificateContent,
            );
        } catch (Throwable $e) {
            $this->logError($e, $readerId);

            $this->rollbackCreatedThing($readerId);

            return new ErrorCreatingCertificate();
        }

        try {
            $this->awsIotClient->attachPrincipalPolicy($certificate->arn, AwsIotPolicy::CLIENT);
        } catch (Throwable $e) {
            $this->logError($e, $readerId);

            $this->rollbackCreatedThing($readerId);
            $this->rollBackCreatedCertificate($certificate->id);

            return new ErrorAttachingPrincipalPolicy();
        }

        try {
            $this->awsIotClient->attachThingPrincipal($readerId, $certificate->arn, true);
        } catch (Throwable $e) {
            $this->logError($e, $readerId);

            $this->rollbackCreatedThing($readerId);
            $this->rollBackCreatedCertificate($certificate->id);
            $this->rollbackAttachedPolicy($certificate->arn, AwsIotPolicy::CLIENT);

            return new ErrorAttachingThingPrincipal();
        }

        return $certificate;
    }

    private function rollbackCreatedThing(RfidReaderId $readerId): void
    {
        $this->awsIotClient->deleteThing($readerId);
    }

    private function rollBackCreatedCertificate(string $certificateId): void
    {
        $this->awsIotClient->deleteCertificate($certificateId);
    }

    private function rollbackAttachedPolicy(string $certificateArn, AwsIotPolicy $policyName): void
    {
        $this->awsIotClient->detachPrincipalPolicy($certificateArn, $policyName);
    }

    private function logError(Throwable $error, RfidReaderId $readerId): void
    {
        $this->logger->error(
            sprintf(
                'Error setting up new reader %s on AWS IoT -> %s',
                $readerId->id->toString(),
                $error->getMessage(),
            ),
        );
    }
}
```

=== UpdateReaderOnAwsIot
<cap:update-reader-on-aws-iot>
*`UpdateReaderOnAwsIot`* è un servizio che si occupa di aggiornare le informazioni di una _Thing_ esistente su AWS IoT Core in caso di modifica dei dati del reader (ad esempio modello o produttore) su KanbanBOX.\
Anche in questo caso per compiere l'aggiornamento vengono usati i metodi della classe *`AwsIotClientImplementation`*.

```php
<?php
readonly class UpdateReaderOnAwsIot implements UpdateReaderOnExternalPlatform
{
    public function __construct(
        private AwsIotClient $awsIotClient,
        private LoggerInterface $logger,
    ) {
    }

    public function __invoke(
        RfidReaderId $rfidReaderId,
        RfidReaderManufacturer $manufacturer,
        RfidReaderModel $model,
    ): true|ErrorUpdatingThing {
        try {
            $iotClient = $this->awsIotClient;

                $iotClient->updateThing(
                    $rfidReaderId,
                    $manufacturer,
                    $model,
                );
        } catch (Throwable $e) {
            $this->logger->error(
                sprintf(
                    'Error updating thing on AWS IoT for reader %s: %s',
                    $rfidReaderId->id->toString(),
                    $e->getMessage(),
                ),
            );

            return new ErrorUpdatingThing();
        }

        return true;
    }
}
```

=== PfxHelper
La classe *`PfxHelper`* ha il solo scopo di adattare, al contesto di KanbanBOX, la chiamata al metodo `openssl_pkcs12_export(...)` della libreria `openssl`, per generare un file PFX a partire dai file in formato PEM forniti da AWS IoT. \

```php
<?php
class PfxHelper
{
    public function getPfxAsString(IotCertificate $certificate): string
    {
        $pfxFile = null;

        openssl_pkcs12_export($certificate->certificatePem, $pfxFile, $certificate->privateKey, $certificate->passphrase, (array) $certificate->extraCertificates);

        return $pfxFile;
    }
}
```

=== Reader
In questo contesto la classe `Reader` può essere vista come un *_controller_*, infatti permette all'interfaccia utente, ovvero la *tabella* per la gestione dei *reader RFID*, di interagire con la *logica di business* che si occupa di riflettere le modifiche a DB e sui servizi esterni (ad esempio quelli di AWS). Per generare e rendere funzionale questa tabella vengono usate diverse classi che possono essere _middleware_ o veri e propri servizi di supporto; in questa sezione verrà descritta solo la classe `Reader` e alcune delle classi ausiliare usate da quest'ultima, dato che sono quelle più rilevanti e su cui ho lavorato durante questo progetto.

Di seguito vengono mostrate alcune immagini raffiguranti la tabella e le relative funzionalità, assieme alle rispettive implementazioni e descrizioni degli aspetti più tecnici. Data la dimensione della classe `Reader` e la quantità di funzionalità che questa implementa, è stato deciso di riportare solo le porzioni di codice più rilevanti.

#figure(
    image("../images/readers_table.png", width: 140%),
    caption: "Tabella di gestione dei reader RFID",
)

Nello specifico, in questo contesto, ho lavorato sull'aggiunta del reader che viene definita all'interno di KanbanBOX come *_table operation_*, in quanto è un'operazione che interagisce con l'entità tabella a differenza delle *_row operation_* che, invece, operano su una riga della tabella, ovvero i singoli reader. \
Riguardo le _row operation_, che si possono vedere nella colonna "Operations", ho lavorato sulle funzionalità di modifica (seconda icona della prima riga), configurazione (terza icona della prima riga) e cancellazione (quarta icona della prima riga) dei reader, e, infine, alla gestione del download dei certificati dei reader (quinta icona della prima riga). Come si può notare, in alcune righe non sono presenti tutte le _row operation_, questo perché:
- per i reader configurati per usare il protocollo HTTP viene inibita la configurazione, in quanto non è previsto l'invio di comandi tramite l'interfaccia di KanbanBOX;
- per i reader HTTP e per quelli di cui è stato scaricato il certificato viene rimossa l'icona di download del certificato (icona della chiave), in quanto non è previsto poter scaricare più volte il certificato di un reader; oltre a questo viene rimosso anche il nome del file contenente il certificato dal DB e viene cancellato il certificato il file stesso dal _filesystem_;
- il reader "kbb" rappresenta il backend di KanbanBOX perché, come spiegato anche nella sezione @cap:aws-iot-core, è necessario che il backend abbia una _Thing_ associata su AWS IoT Core per poter connettersi al broker MQTT e gestire i reader; questo "reader", quindi, non è configurabile in alcun modo, e non è necessario scaricare il suo certificato dato che sarà già presente di default nei secrets di KanbanBOX.

#figure(
    image("../images/add_reader.png", width: 70%),
    caption: "Bottone di aggiunta del reader RFID",
) <fig:add-reader-button>

#figure(
    image("../images/reader_add_update.png", width: 140%),
    caption: "Form di aggiunta e modifica dei reader RFID",
) <fig:reader-add-update>

La funzione di *aggiunta del reader*, raggiungibile tramite la _table operation_ mostrata nella @fig:add-reader-button, visualizza a schermo il form visibile nella @fig:reader-add-update; se vengono inseriti i campi obbligatori (con il bordo rosso) e si preme il pulsante "Save", dopo aver superato la validazione del form, si procede con le seguenti _task_:
- se il reader utilizza il protocollo MQTT, viene eseguita la creazione e configurazione delle entità di AWS IoT Core associate al reader tramite il metodo `create_entity_on_aws(...)`; quest'ultimo si occupa di invocare il servizio *`SetupNewReaderOnAwsIot`* [@cap:setup-new-reader-on-aws-iot] e, se il "setup" va a buon fine, genera il certificato in formato PFX e lo restituisce;
- se il certificato è stato generato (la funzione precedente ha ritornato un `IotCertificate`), o se il reader utilizza il protocollo HTTP, si procede con la memorizzazione del reader a DB tramite il metodo `store_reader(...)`, che si occupa di invocare il comando *`AddReaderCommand`* [@cap:command-pattern] per salvare il reader a DB, e di dare un feedback positivo all'utente nel caso fosse andato tutto a buon fine;
-
    *a.* se c'è stato qualche errore durante la creazione delle entità su AWS IoT Core, tramite il *`RfidReaderCreationErrorPresenter`* viene mostrato un messaggio di errore all'utente con le informazioni relative al problema riscontrato;\
    *b.* altrimenti si ritorna alla pagina di gestione dei reader.
```php
<?php
public function add_reader(string|null $readerId = null): void
{
    /* ... codice di supporto per visualizzazione del form e validazione dei dati ... */
    if ($isMqtt) {
        $awsThingCreationResult = $this->create_entity_on_aws(
            $readerId,
            $rfidReaderManufacturer,
            $rfidReaderModel,
            $licenseId,
        );

        if ($awsThingCreationResult instanceof IotCertificate) {
            $pfxCertificate = $this->pfxHelper->getPfxAsString($awsThingCreationResult);
            $pfxStream = Utils::streamFor($pfxCertificate);

            $pfxFileName = $awsThingCreationResult->id . '.pfx';
            $this->defaultUpload->fileStream(
                $pfxFileName,
                $pfxStream,
                $licenseId,
                FileUploadContext::AWS_IOT_CERTIFICATE
            );

            $this->store_reader(
                $readerId,
                $pfxFileName,
                $isMqtt
            );

            new ResponseEmitter()->emit(
                $this->dic->get(Redirect::class)->toUri(
                    'rfid/reader/readers',
                    RedirectMethod::LOCATION,
                    303
                )
            );

            return;
        }

        $this->rfidReaderCreationErrorPresenter->__invoke($awsThingCreationResult);
    } else {
        $this->store_reader(
            $readerId,
            null,
            $isMqtt
        );

        new ResponseEmitter()->emit(
            $this->dic->get(Redirect::class)->toUri(
                'rfid/reader/readers',
                RedirectMethod::LOCATION,
                303
            )
        );

        return;
    }
}
```

La funzione di *aggiornamento del reader* usa un form pressoché identico a quello dell'aggiunta del reader, se non per il campo "Protocol" che nell'aggiornamento non è modificabile e per i campi che sono tutti facoltativi; inoltre segue lo stesso paradigma dell'aggiunta, con qualche differenza nei servizi chiamati, infatti:
- se il reader utilizza il protocollo MQTT, vengono modificati gli attributi della _Thing_ su AWS IoT Core tramite il servizio *`UpdateReaderOnAwsIot`* [@cap:update-reader-on-aws-iot]; ovviamente nessuna operazione viene svolta sul certificato che rimane tale e quale e non viene rigenerato;
- viene invocato il comando *`UpdateReaderCommand`* [@cap:command-pattern] per aggiornare il reader a DB;
- se il reader usa il protocollo MQTT, viene inviato un comando MQTT al reader che avvia la lettura dei tag nel caso in cui il campo "Active Reader" venga impostato a "Yes" oppure ferma la lettura se viene impostato a "No";
- *a.* se c'è stato qualche errore durante l'aggiornamento delle entità su AWS IoT Core o durante l'invio del comando viene visualizzato un messaggio di errore;\
    *b.* altrimenti si ritorna alla pagina di gestione dei reader.

#figure(
    image("../images/reader_configure_operating.png", width: 130%),
    caption: "Form di modifica dei reader RFID",
)

#figure(
    image("../images/json_schema.png", width: 130%),
    caption: "JSON schema per la configurazione dei reader RFID",
) <fig:json-schema>

Come anticipato la funzionalità di *configurazione di un reader* è raggiungibile solamente se il reader in questione utilizza il protocollo MQTT, questo perché è necessario poter inviare dei comandi MQTT al reader per configurarlo, e questa funzionalità non è prevista per i reader HTTP. \
Le configurazioni sono inseribili manualmente incollandole in formato JSON oppure generando il JSON tramite l'interfaccia basata su JSON schema mostrata in @fig:json-schema; in entrambi i casi, una volta premuto il pulsante "Save", le configurazioni vengono validate tramite lo schema e successivamente si procede con le seguenti _task_:
- si esegue la connessione la broker MQTT;
- si controlla che almeno una delle due configurazioni sia definita\
    *a.* se si, si procede con l'invio dei comandi per cui la configurazione è definita usando il metodo `MqttClient::publishCommandInTopic(...)`; \
    *b.* altrimenti si ignorano tutti i passaggi successivi e viene eseguito il _redirect_ alla tabella dei reader.
- si esegue la disconnessione dal broker MQTT;
- se almeno una delle due configurazioni è andata a buon fine viene eseguito il salvataggio a DB delle configurazioni inviate per cui si è ricevuto esito positivo;
- viene dato un feedback relativo all'esito dell'applicazione delle configurazioni e viene eseguito il _redirect_ alla tabella dei reader;


```php
<?php
public function configure_reader(string $readerId): void
{
    /* ... codice di supporto per visualizzazione del form e validazione dei dati ... */
    $this->mqttClient->connect();

    if (isset($formData['configuration']) && $formData['configuration'] !== '') {
        $configuration = $formData['configuration'];
        $configResult = $this->mqttClient->publishCommandInTopic(
            TopicLeaf::Management,
            TopicLeaf::ManagementResponses,
            new ZebraCommand(
                ZebraCommands::SET_CONFIG,
                $this->clock->now(),
                $configuration,
            ),
            $readerId,
            $currentLicense,
            $this->rfidSignature,
        );
    }

    if (isset($formData['operatingModeConf']) && $formData['operatingModeConf'] !== '') {
        $operatingModeConf = $formData['operatingModeConf'];
        $operatingModeResult = $this->mqttClient->publishCommandInTopic(
            TopicLeaf::Controls,
            TopicLeaf::ControlsResponses,
            new ZebraCommand(
                ZebraCommands::SET_OPERATING_MODE,
                $this->clock->now(),
                $operatingModeConf,
            ),
            $readerId,
            $currentLicense,
            $this->rfidSignature,
        );
    }
    $this->mqttClient->disconnect();

    if ($configResult === true || $operatingModeResult === true) {
        $command = UpdateReaderCommand::forConfiguration(
            $readerId,
            $currentUser,
            $currentLicense,
            $configResult === true && $configuration !== '' ? $configuration : null,
            $operatingModeResult === true && $operatingModeConf !== '' ? $operatingModeConf : null
        );

        $this->commandBus->execute($command);

        if ($configResult === true) {$this->globalMessage->insert(/* ... configurazione del messaggio di successo ... */);}
        if ($operatingModeResult === true) {$this->globalMessage->insert(/* ... configurazione del messaggio di successo ... */);}
    }
    if ($configResult === false) {$this->globalMessage->insert(/* ... configurazione del messaggio di errore ... */);}
    if ($operatingModeResult === false) {$this->globalMessage->insert(/* ... configurazione del messaggio di errore ... */));}
    new ResponseEmitter()->emit(
        $this->dic->get(Redirect::class)->toUri('rfid/reader/readers', RedirectMethod::LOCATION, 303)
    );
    return;
}
```

=== DownloadReaderCertificateRow e RfidDownloadCertificate
<cap:download-reader-certificate>
#figure(
    image("../images/download_certificate.png", width: 130%),
    caption: "Row operation di download del certificato",
)
Il *download dei certificati* è implementato in modo diverso dalle altre _row operation_ poiché, invece di visualizzare un form di cui esegue il _submit_, c'è bisogno di mostrare un pop-up di conferma, e, in questo caso specifico, dopo la conferma è necessario aprire una _blank page_ per avviare il download del file. Per questo nella classe di costruzione della tabella dei reader, il bottone della _row operation_ di download dei certificati viene associato ad un oggetto di tipo `DownloadReaderCertificateRow`, classe che estende `ExecuteOnRowWithConfirmation` e che, appunto, permette di eseguire un'operazione su una riga della tabella dopo aver chiesto una conferma all'utente. \

Tra i *parametri* del costruttore (e del metodo create che è analogo al costruttore ma, per definizione delle classi padre astratte, è statico ed è quello che viene effettivamente usato per costruire l'oggetto) ci sono alcune caratteristiche della _row operation_ (`id`, `title`, `icon`) e le sue dipendenze, le più rilevanti sono `TwigEnvironment` che è necessaria per poter creare l'elemento grafico usando i template di Twig (viene usato dai costruttori delle classi padre) e `InternalUrlBuilder` che è necessario per costruire il link a cui fare _redirect_ dopo la conferma, ovvero il link che permette di scaricare il certificato del reader. \
Infatti nel metodo `execute(...)`, che viene invocato quando l'utente conferma l'operazione, viene costruito un oggetto `RedirectToLink` che, una volta restituito, permette di eseguire un _redirect_ verso il link di download del certificato del reader; quest'ultimo viene costruito usando l'`InternalUrlBuilder` e punta ad un endpoint del backend di KanbanBOX associato alla classe `RfidDownloadCertificate`, descritta più sotto, che si occupa di restituire il file del certificato da scaricare. \

```php
<?php
final class DownloadReaderCertificateRow extends ExecuteOnRowWithConfirmation
{
    protected function __construct(
        string $id,
        string $title,
        string $icon,
        private readonly Language $language,
        private readonly GetTranslation $getTranslation,
        TwigEnvironment $twigEnvironment,
        private InternalUrlBuilder $urlBuilder,
    ) {
        parent::__construct($id, $title, $icon, $language, $twigEnvironment, $getTranslation);
    }

    public static function create(/* analogo al costruttore */): self
    {
        return new self(/* ... */);
    }

    protected function execute(RowId $rowId, Table $table): OperationResponse
    {
        return new RedirectToLink(
            $this->urlBuilder->build('rfid/download_certificate/' . $rowId->id),
            Target::NewTab,
            reloadRow: true,
        );
    }

    protected function getAskConfirmationConfiguration(RowId $rowId): AskConfirmationConfiguration
    {
        return new AskConfirmationConfiguration(($this->getTranslation)('rfid_download_certificate_confirmation', $this->language),);
    }
}
```

Come anticipato, l'endpoint a cui viene fatto _redirect_ dopo la conferma dell'operazione di download del certificato punta alla classe `RfidDownloadCertificate`, che è un *_request handler_* e si occupa di gestire il certificato al momento del download, sia dal punto di vista del filesystem che a DB. \
Infatti il *costruttore* si occupa solo di ricevere le dipendenze utilizzate dal metodo *`handle(...)`* che opera come segue:
- recupera le informazioni del reader da DB usando l'identificativo fornito dalla richiesta ricevuta dall'endpoint, controllando che il reader sia effettivamente controllato dalla licenza (identificativo del client) attualmente in uso;
- estrae il nome del file del certificato associato al reader, se è presente, e lo legge dal filesystem; se il nome del certificato non è presente, significa che il certificato è già stato scaricato in precedenza, quindi viene lanciata un'eccezione;
- cancella il file del certificato dal filesystem e rimuove il nome del certificato a DB, in modo da non permettere ulteriori download dello stesso certificato;
- invia un comando per aggiornare il reader a DB, in modo da riflettere il download del certificarlo e inibire ulteriori download;
- restituisce una risposta con il file del certificato da scaricare, con gli header HTTP corretti per permettere il download del file.

```php
<?php
final readonly class RfidDownloadCertificate implements RequestHandlerInterface
{
    public function __construct(
        private GetFromSession $getFromSession,
        private RfidReaderRepository $rfidReaderRepository,
        private UserFilesFilesystem $userFilesFilesystem,
        private Upload $upload,
        private CommandBus $commandBus,
    ) {}

    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        $arguments = $request->getAttribute(UriArguments::class);

        $readerIdArgument = $arguments->get('readerId');
        $readerId = RfidReaderId::fromString($readerIdArgument);
        $reader   = $this->rfidReaderRepository->getById($readerId);

        if (! $reader->getLicense()->getId()->equals($this->getFromSession->licenseId())) {
            throw new Exception(sprintf('RFID Reader %s does not belong to the license %s.', $readerId->id->toString(), $this->getFromSession->licenseId()->id));
        }

        $certificateName = $reader->getCertificateName();
        if ($certificateName === null) {
            throw new Exception(sprintf('RFID Reader %s certificate was already downloaded.', $readerId->id->toString()));
        }
        $readStream = $this->userFilesFilesystem->readStream(
            $this->upload->getDefaultFilePath($this->getFromSession->licenseId(), FileUploadContext::AWS_IOT_CERTIFICATE, $certificateName),
        );
        $this->userFilesFilesystem->delete(
            $this->upload->getDefaultFilePath($this->getFromSession->licenseId(), FileUploadContext::AWS_IOT_CERTIFICATE, $certificateName),
        );

        $this->commandBus->execute(
            UpdateReaderCommand::consumeCertificate($reader->getId(), $this->getFromSession->userId(), $this->getFromSession->licenseId()),
        );

        return new Response(
            200,
            [
                'Content-Type' => 'application/x-pkcs12',
                'Content-Disposition' => sprintf('attachment; filename="%s"', $certificateName),
                'Content-Transfer-Encoding' => 'binary',
            ],
            $readStream,
        );
    }
}
```

=== DeleteRfidReaderRow
La *cancellazione di un reader* è implementata in modo simile al download dei certificati, infatti anche in questo caso viene mostrato un pop-up di conferma prima di eseguire l'operazione, e viene eseguito un _redirect_ alla tabella dei reader dopo la cancellazione. \

Analogamente al download dei certificati il costruttore i dati della _row operation_ e le dipendenze necessarie per eseguire l'operazione, tra cui *`AwsIotClient`* che è necessario per eseguire la cancellazione delle entità su AWS IoT Core associate al reader, *`RfidReaderRepository`* per recuperare le informazioni del reader da DB, e *`UserFilesFilesystem`* e *`Upload`* per cancellare il file del certificato associato al reader dal filesystem nel caso in cui fosse presente. \
Il metodo `execute(...)` si occupa di eseguire la cancellazione effettiva del reader, che consiste nei seguenti passaggi:
- recuperare le informazioni del reader da DB usando l'identificativo fornito dalla riga su cui è stata eseguita l'operazione, controllando che il reader sia effettivamente controllato dalla licenza (identificativo del client) attualmente in uso;
- se il reader utilizza il protocollo MQTT, esegue la cancellazione delle entità su AWS IoT Core associate al reader tramite il `AwsIotClient`, che si occupa di:
    - recuperare gli arn (identificativi delle risorse su AWS) dei certificati associati al reader tramite la funzione `listThingPrincipals(...)`;
    - per ogni certificato estratto, disassociare il certificato dalla policy associata e dal reader, cancellare il certificato da AWS IoT Core e cancellare il file del certificato dal filesystem;
    - cancellare la _Thing_ associata al reader;
- cancellare il file del certificato dal filesystem;
- cancellare il reader a DB tramite il comando *`RemoveReaderCommand`* [@cap:command-pattern];
- se c'è stato qualche errore durante la cancellazione delle entità su AWS IoT Core, viene mostrato un messaggio di errore all'utente e viene registrato nei log l'errore riscontrato; altrimenti viene mostrato un messaggio di successo all'utente;
- viene eseguito il _redirect_ alla tabella dei reader.

```php
<?php
class DeleteRfidReaderRow extends ExecuteOnRowWithConfirmation
{
    private function __construct(
        string $id,
        string $title,
        string $icon,
        private readonly LicenseAndUser $licenseAndUser,
        private readonly Language $language,
        private readonly GetTranslation $getTranslation,
        TwigEnvironment $twigEnvironment,
        private readonly CommandBus $commandBus,
        private readonly GlobalMessage $globalMessage,
        private readonly AwsIotClient $awsIotClient,
        private readonly LoggerInterface $logger,
        private readonly RfidReaderRepository $rfidReaderRepository,
        private readonly UserFilesFilesystem $userFilesFilesystem,
        private readonly Upload $upload,
    ) {
        parent::__construct($id, $title, $icon, $language, $twigEnvironment, $getTranslation);
    }

    public static function create(/* analogo al costruttore */): self
    {
        return new self(/* ... */);
    }

    protected function execute(RowId $rowId, Table $table): OperationResponse
    {
        $clientId   = RfidReaderId::fromString($rowId->id);
        $rfidReader = $this->rfidReaderRepository->getById($clientId);

        if ($rfidReader->isMqtt()) {
            try {
                $thingPrincipals = $this->awsIotClient->listThingPrincipals($clientId);

                if (count($thingPrincipals) === 0) {
                    throw new Exception('No principals attached to the thing');
                }

                foreach ($thingPrincipals as $certificateArn) {
                    $this->awsIotClient->detachPrincipalPolicy($certificateArn, AwsIotPolicy::CLIENT);
                    $this->awsIotClient->detachThingPrincipal($clientId, $certificateArn);

                    $certificateId = $this->getIdFromArn($certificateArn);
                    $this->awsIotClient->deleteCertificate($certificateId);
                }

                $certificateName = $rfidReader->getCertificateName();

                if ($certificateName !== null) {
                    $this->userFilesFilesystem->delete(
                        $this->upload->getDefaultFilePath(
                            $this->licenseAndUser->actingUnderLicense(),
                            FileUploadContext::AWS_IOT_CERTIFICATE,
                            $certificateName,
                        ),
                    );
                }

                $this->awsIotClient->deleteThing($clientId);
            } catch (Throwable $e) {
                $this->globalMessage->insert(
                    ($this->getTranslation)('rfid_failed_reader_delete', $this->language),
                    GlobalMessageType::ERROR,
                );
                $this->logger->error(
                    sprintf(
                        'Error deleting reader %s: %s',
                        $clientId->id->toString(),
                        $e->getMessage(),
                    ),
                );

                return new NotExecuted(null);
            }
        }

        $this->commandBus->execute(
            new RemoveReaderCommand(
                $clientId,
                $this->licenseAndUser->actingAsUser(),
                $this->licenseAndUser->actingUnderLicense(),
            ),
        );

        $this->globalMessage->insert(
            ($this->getTranslation)('rfid_reader_deleted', $this->language),
            GlobalMessageType::OK,
        );

        return new Executed(
            Action::DELETE_ROW,
        );
    }

    protected function getAskConfirmationConfiguration(RowId $rowId): AskConfirmationConfiguration
    {
        return new AskConfirmationConfiguration(
            ($this->getTranslation)('rfid_delete_reader', $this->language, ['ReaderId' => $rowId->id]),
        );
    }

    private function getIdFromArn(string $id): string
    {
        $arn    = explode('/', $id);
        $result = end($arn);
        Assert::stringNotEmpty($result);

        return $result;
    }
}
```

== Ricezione dei tag RFID letti

=== Worker
Come anticipato nella Sezione @cap:flusso-del-sistema i dati dei tag RFID letti dai reader vengono estratti in _pull_ da AWS SQS tramite un *_worker_*. Una volta estratto un messaggio il _worker_ lo distribuisce, in base al tipo di messaggio, ad un opportuno *_handler_*, che nel caso dei messaggi ricevuti dalla coda 'rfid-reader-tag-events' è il `RfidEventsMessageSerializer`.

Di seguito viene mostrato come nella classe `Container` @psr-container, ovvero il contenitore di dipendenze del backend di KanbanBOX che serve per gestire la _dependency injection_, viene preparato tutto il necessario per costruire il _worker_ dedicato alla lettura degli eventi RFID.

Vediamo che viene costruito un oggetto `ConsumeMessagesCommand` che è il comando, eseguito dal worker, che consente di estrarre i messaggi dalla coda SQS e di processarli; questo comando viene costruito passando un `RoutableMessageBus` che è un bus dei messaggi che consente di instradare i messaggi a degli handler specifici in base al loro tipo, e un _locator_ (`rfidEventsReceiverLocator`) che rappresenta il ricevitore SQS associato alla coda da cui vogliamo estrarre i messaggi. \
Abbiamo poi anche un `EventDispatcher` per gestire gli eventi generati durante l'esecuzione del comando, e un `Logger` per dare in _output_ eventuali errori o messaggi di log. \
Infine viene fornito anche il nome coda sotto forma di array, che in altri contesti potrebbe essere utile per gestire più code con lo stesso comando, ma nel nostro caso è un parametro superfluo dato che abbiamo un solo comando dedicato ad una sola coda, già associata al `rfidEventsReceiverLocator`.

Sarà il `ConsumeMessagesCommand` ad occuparsi della gestione dalla configurazione e del ciclo di vita del `Worker` @symfony-worker, utilizzando i componenti forniti durante la configurazione del `ConsumeMessagesCommand` nel `Container`.
```php
<?php
$rfidEventsQueueConfiguration = $getConfig->getRfidEventsQueueConfiguration();
$rfidEventsReceiverLocator = new EmptyContainer();
$rfidEventsReceiverLocator->set(
    $rfidEventsQueueConfiguration->queueName,
    $awsSqsFactory->buildReceiver(
        $rfidEventsQueueConfiguration,
        new RfidEventsMessageSerializer($clock, $logger),
    ),
);

$rfidEventsCommandExecutor = new ConsumeMessagesCommand(
    new RoutableMessageBus(
        new EmptyContainer(),
        $messageBus,
    ),
    $rfidEventsReceiverLocator,
    $eventDispatcher,
    $logger,
    [$rfidEventsQueueConfiguration->queueName],
);
```
=== RfidEventsMessageSerializer
<cap:rfid-events-message-serializer>

`RfidEventsMessageSerializer` è il componente che si occupa di *manipolare* i messaggi provenienti dalla coda SQS e di trasformarli in *DTO* che possono essere gestiti dal sistema di messaggistica interno.
Nel flusso del _worker_ mostrato nella sezione precedente, il serializer viene passato alla factory che costruisce il receiver SQS (`buildReceiver(...)`): in questo modo, ogni payload JSON letto dalla coda viene convertito, tramite il serializer, in un `Envelope` contenente un oggetto di dominio, che verrà poi instradato dal `RoutableMessageBus` verso l'handler corretto.

I *parametri* passati al costruttore del serializer sono un `Clock` e un `LoggerInterface`: il primo viene usato per assegnare il timestamp agli eventi generati, mentre il secondo è utile per _loggare_ eventuali errori o messaggi di diagnostica durante la decodifica dei messaggi.

Il metodo *`decode(...)`* è il componente principale del serializer, invocato per lo più dall'oggetto `AmazonSqsReceiver` @symfony-amazonSqsReceiver del framework Symfony quando viene letto un messaggio dalla coda SQS; il suo funzionamento è il seguente:
- se il `type` del messaggio è `heartbeat` e il `clientId` è presente, viene creato un `ReportEventsMessage` contenente un report di tipo `ReaderReportContainsHeartbeat`; il `Clock` viene usato per assegnare l'istante di ricezione e viene generato un identificativo univoco del report (`Uuid::uuid4()`).
- se il payload contiene l'id del tag letto (`idHex`) e il `clientId`, viene costruito un `ReadTagEventsMessage` con i dati della lettura (timestamp, RSSI, antenna, numero di letture, ecc.) e l'identificativo del reader che ha generato il messaggio, ricavato dal `clientId`;
- se la struttura non è valida o mancano campi obbligatori, viene emesso un warning e il serializer restituisce un `MessageToBeDiscarded`, così da evitare che il worker propaghi messaggi malformati nel resto del sistema. \
L'oggetto *`Envelope` restituito* non è altro che un wrapper utile per eseguire la distribuzione del messaggio nel sistema di messaggistica interno (`MessageBus`).

È importante notare come venga definito uno *`psalm-type`* (`RfidMessageBody`) per il corpo del messaggio, di cui non è stata riportata la definizione completa per questioni di spazio e chiarezza; questa annotazione è utile per indicare a Psalm di imporre la tipizzazione statica specificata, sulle variabili a cui è assegnata, in questo caso `$decodedEnvelope`, evitando di dover gestire tipi di dati `mixed` o non conformi a quelli attesi.
```php
<?php
/** @psalm-type RfidMessageBody = array{...} */
final readonly class RfidEventsMessageSerializer implements SerializerInterface
{
    public function __construct(
        private Clock $clock,
        private LoggerInterface $logger,
    ) {
    }

    /** @inheritdoc */
    public function decode(array $encodedEnvelope): Envelope
    {
        /** @var RfidMessageBody $decodedEnvelope */
        $decodedEnvelope = json_decode($encodedEnvelope['body'], true, 512, JSON_THROW_ON_ERROR);
        if (($decodedEnvelope['type'] ?? null) === 'heartbeat' && isset($decodedEnvelope['clientId'])) {
            return Envelope::wrap(
                new ReportEventsMessage(
                    ReaderReportContainsHeartbeat::from(
                        $this->clock->now(),
                        [
                            'rfidReport' => Uuid::uuid4()->toString(),
                            'reader' => $decodedEnvelope['clientId'],
                        ],
                    ),
                ),
            );
        }

        if (isset($decodedEnvelope['data']['idHex'], $decodedEnvelope['clientId'])) {
            if($type->matches($decodedEnvelope)) {
                return Envelope::wrap(new ReadTagEventsMessage(
                    MessageId::generate(),
                    $decodedEnvelope['data']['idHex'],
                    $decodedEnvelope['type'],
                    new DateTimeImmutable($decodedEnvelope['timestamp']),
                    $decodedEnvelope['data']['reads'],
                    $decodedEnvelope['data']['phase'],
                    $decodedEnvelope['data']['peakRssi'],
                    $decodedEnvelope['data']['format'],
                    $decodedEnvelope['data']['eventNum'],
                    $decodedEnvelope['data']['antenna'],
                    RfidReaderId::fromString($decodedEnvelope['clientId']),
                ));
            }

            $this->logger->warning('Received a message with an unexpected format or missing required data', [
                'category' => 'rfid',
                'message' => $decodedEnvelope,
            ]);
        }

        return Envelope::wrap(
            new MessageToBeDiscarded(),
        );
    }
}
```

=== ReadTagEventsMessage
`ReadTagEventsMessage` è il DTO che rappresenta un singolo *tag RFID* letto, che è stato recuperato dalla coda SQS. \
Come anticipato anche in @cap:rfid-events-message-serializer, questo oggetto viene creato dal `RfidEventsMessageSerializer` quando il payload contiene i campi minimi necessari, ovvero l'identificativo del tag `idHex` e l'identificativo del reader `clientId`.

Di seguito vengono descritti i *campi* dell'oggetto:
- *`id`* è l'identificativo univoco del messaggio nel sistema di messaggistica interno (utile per tracciamento e diagnostica);
- *`idHex`* è l'identificativo del tag letto (tipicamente l'EPC in formato esadecimale) ed è l'informazione che permette di associare la lettura a un *kanban*;
- *`now`* rappresenta il timestamp della lettura (o, più in generale, l'istante associato all'evento di lettura che viene propagato nel dominio);
- *`reads`*, *`phase`*, *`peakRssi`*, *`antenna`*, *`eventNum`*, *`format`* rappresentano le statistiche relative alla lettura;
- *`clientId`* è l'identificativo del reader che ha prodotto l'evento.

La classe implementa i *metodi* dell' l'*interfaccia `Message`*:
- *`getAttributes()`* ritorna `null` perché la classe non aggiunge ulteriori metadati;
- *`getBody()`* serializza tutti i campi (per questioni di spazio e chiarezza non sono stati elencati tutti) in JSON per consentire log/diagnostica o trasporto interno coerente con gli altri `Message`.
```php
<?php
final readonly class ReadTagEventsMessage implements Message
{
    public function __construct(
        public MessageId $id,
        public string $idHex,
        public string $type,
        public DateTimeImmutable $now,
        public int $reads,
        public float $phase,
        public int $peakRssi,
        public string $format,
        public int $eventNum,
        public int $antenna,
        public RfidReaderId $clientId,
    ) {
    }

    public function getAttributes(): MessageAttributes|null
    {
        return null;
    }

    public function getBody(): string
    {
        return json_encode([
            'id' => $this->id->__toString(),
            'idHex' => $this->idHex,
            // ... associazione chiave-valore di tutti i campi ...
        ], JSON_THROW_ON_ERROR);
    }
}
```
=== ReportEventsMessage e ReaderReportContainsHeartbeat
Nel caso dei messaggi di tipo *heartbeat*, l'obiettivo non è associare un tag a un kanban, ma aggiornare lo *stato di connessione* del reader nel backend. Per questo motivo il serializer, quando riceve un payload con `type = heartbeat` e con `clientId` presente, costruisce un messaggio di tipo `ReportEventsMessage`.

`ReportEventsMessage` è un DTO molto semplice pensato per essere compatibile con il *`MessageBus`* (per questo implementa `Message`) e _wrappare_ l'evento `ReaderReportContainsHeartbeat`. \
In questo modo è possibile trasmettere l'evento `ReaderReportContainsHeartbeat` (già esistente e adatto a questo caso d'uso) attraverso il sistema di messaggistica interno.

```php
<?php
final readonly class ReportEventsMessage implements Message
{
    /**
     * DTO representing a heartbeat
     */
    public function __construct(
        public ReaderReportContainsHeartbeat $readerReportContainsHeartbeat,
    ) {
    }

    public function getAttributes(): MessageAttributes|null
    {
        return null;
    }

    public function getBody(): string
    {
        return '';
    }
}
```

`ReaderReportContainsHeartbeat` è invece un *domain event* (`AggregateDomainEvent`) che rappresenta un evento relativo ad uno specifico DTO, in questo caso un `RfidReport`, ovvero un messaggio diagnostico ricevuto da un reader RFID.

I parametri passati al *costruttore* sono:
- `report`: l'identificativo dell'`RfidReport` associato a questo evento;
- `reader`: l'identificativo del reader che ha generato l'heartbeat;
- `raisedAt`: l'istante in cui l'evento è stato generato.

Il metodo *`raise(...)`* è un _factory method_ che consente di creare un'istanza di `ReaderReportContainsHeartbeat` a partire dai dati ricevuti dal serializer, e assegnando l'istante di generazione tramite il `Clock`.

I metodi *`toArray()`* e *`from(...)`* sono invece utili per serializzare e deserializzare l'evento, quindi per adattarlo ai formati necessari nei contesti in cui può essere utilizzato.

```php
<?php
final class ReaderReportContainsHeartbeat implements AggregateDomainEvent
{
    private function __construct(
        private RfidReportId $report,
        public RfidReaderId $reader,
        private DateTimeImmutable $raisedAt,
    ) {
    }

    public static function raise(
        RfidReportId $report,
        RfidReaderId $reader,
        Clock $clock,
    ): self
    {
        return new self(
            $report,
            $reader,
            $clock->now(),
        );
    }

    /* ... getters ... */

    /** @return array<string, string> */
    public function toArray(): array
    {
        return [
            'rfidReport' => $this->aggregate()->toString(),
            'reader' => $this->reader->id->toString(),
        ];
    }

    public static function from(
        DateTimeImmutable $raisedAt,
        array $data,
    ): self
    {
        return new self(
            RfidReportId::fromString($data['rfidReport']),
            RfidReaderId::fromString($data['reader']),
            $raisedAt,
        );
    }
}
```

=== RfidEventsMessageHandler, UpdateLastHeartbeatOfTheReaderCommand e RfidScan

`RfidEventsMessageHandler` è l'*_handler_* che riceve i messaggi incapsulati dal `RfidEventsMessageSerializer` e li usa per *riflettere i cambiamenti* indicati dai messaggi stessi nel dominio, ad esempio aggiornando lo stato di un reader o registrando una lettura di un tag RFID.

Nel flusso del _worker_ descritto in precedenza, dopo la decodifica e il wrapping in un `Envelope`, il `RoutableMessageBus` instrada i messaggi, di tipo esplicitamente ammesso (nel `Container` le classi di messaggi vengono associate agli _handler_ corrispondenti), verso questo handler.

Il *costruttore* riceve una serie di *dipendenze* che permettono di applicare la logica di business e la persistenza dei dati:
- *`RfidScanRepository`*: oggetto per gestire la persistenza dei dati a DB, associato specificatamente alla tabella `rfid_scan` che in questo caso ci servirà per gli eventi di lettura dei tag RFID;
- *`IgnoreScanDueToDebouncing`*: oggetto che implementa il *debouncing* per evitare di registrare letture duplicate troppo ravvicinate;
- *`RfidAreaByReaderIdAndAntennaName`*: oggetto che quando invocato permette di ottenere dal DB l'area associata ad una specifica combinazione di reader e antenna, così da poter associare la lettura del tag a un'area specifica;
- *`StringIdFromEpc`*: oggetti per la conversione dell'EPC (identificativo del tag fisico) da esadecimale a stringa usata per identificare i cartellini internamente a KanbanBOX;
- *`FindCardFromStringId`*: oggetto che permette di cercare un cartellino a DB usando il suo identificativo;
- *`Clock`*: oggetto per la gestione di timestamp o data e ora, utile per assegnare il timestamp alle letture o agli eventi generati;
- *`CommandBus`*: oggetto che permette di eseguire i comandi costruiti nel metodo `handle(...)`.

Il metodo *`handle(...)`* gestisce due macro-casi, coerenti con i due DTO introdotti nelle sezioni precedenti:
- *heartbeat* (`ReportEventsMessage`): evento diagnostico che segnala che un reader è connesso e attivo;
- *tag scan* (ad es. `ReadTagEventsMessage`): evento di lettura di un tag RFID.

```php
<?php
final readonly class RfidEventsMessageHandler implements MessageHandler
{
    public function __construct(
        private RfidScanRepository $rfidScanRepository,
        private IgnoreScanDueToDebouncing $ignoreScanDueToDebouncing,
        private RfidAreaByReaderIdAndAntennaName $rfidAreaIdByReaderIdAndAntennaName,
        private StringIdFromEpc $stringIdFromEpc,
        private FindCardFromStringId $findCardFromStringId,
        private Clock $clock,
        private CommandBus $commandBus,
    ) {
    }

    public function handle(Message $message): void
    {
        if ($message instanceof ReportEventsMessage) {
            $this->commandBus->execute(
                    UpdateLastHeartbeatOfTheReaderCommand
                    ::fromReaderReportContainsHeartbeat(
                    $message->readerReportContainsHeartbeat,
                ),
            );

            return;
        }

        $event = RfidScan::validateScan(
            $message->clientId,
            $message->idHex,
            $message->peakRssi,
            (string) $message->antenna,
            $message->now,
            $this->ignoreScanDueToDebouncing,
            $this->rfidAreaIdByReaderIdAndAntennaName,
            $this->stringIdFromEpc,
            $this->findCardFromStringId,
            $this->clock,
        );
        $this->rfidScanRepository->store($event);
    }
}
```

Nel caso dell'*heartbeat*, l'handler traduce l'evento in un comando *`UpdateLastHeartbeatOfTheReaderCommand`* usando i dati contenuti nel `ReaderReportContainsHeartbeat` _wrappato_ nel messaggio. Il `CommandBus` eseguirà il comando, aggiornando, con la data e ora dell'heartbeat appena ricevuto, la colonna `last_heartbeat` nella tabella `rfid_reader`.

```php
<?php
final class UpdateLastHeartbeatOfTheReaderCommand implements RfidScanCommand
{
    private function __construct(public RfidReaderId $reader, public DateTimeImmutable $raisedAt)
    {
    }

    public static function fromReaderReportContainsHeartbeat(ReaderReportContainsHeartbeat $event): self
    {
        return new self($event->reader, $event->raisedAt());
    }

    public function credentials(): System
    {
        return new System();
    }
}
```

Invece, per la *lettura dei tag*, l'handler delega la validazione e la costruzione dell'evento a *`RfidScan::validateScan(...)`*, passando:
- i dati contenuti nel tag (`clientId`, `idHex`, `RSSI`, `antenna`, `timestamp`);
- le dipendenze necessarie a validare correttamente la lettura del tag.
Il risultato della validazione è un evento di lettura di un tag (`RfidScan`) di cui si garantisce la correttezza dei dati contenuti e a cui è stata associata l'area in cui è stato letto. \
Come spiegato alla fine di @cap:rfid-reader, associando i tag letti all'area corretta possiamo poi identificare il cambio stato previsto dall'area e *aggiornare* di conseguenza il *cartellino kanban* con identificativo corrispondente a quello del tag RFID letto.

```php
<?php
final class RfidScan implements AggregateRoot
{
    private RfidScanId $id;

    /** @var list<AggregateDomainEvent<self>> */
    public array $newEvents = [];

    /** @var positive-int|0  */
    private int $version = 0;

    private function __construct(RfidScanId $id)
    {
        $this->id = $id;
    }

    public static function validateScan(
        RfidReaderId $readerId,
        string $epc,
        int $peakRssi,
        string $antennaName,
        DateTimeImmutable $scanTime,
        IgnoreScanDueToDebouncing $ignoreScanDueToDebouncing,
        RfidAreaByReaderIdAndAntennaName $areaByReaderIdAndAntennaName,
        StringIdFromEpc $stringIdFromEpc,
        FindCardFromStringId $findCardFromStringId,
        Clock $clock,
    ): self
    {
        $instance = new self(RfidScanId::generate());

        // Validate the RFID EPC
        try {
            $cardStringId = $stringIdFromEpc($epc);
        } catch (InvalidRfidEpc) {
            $instance->newEvents[] = ScanDiscardedForInvalidRfidEpc::raise($instance->id, $readerId, $epc, $clock);

            return $instance;
        }

        // Identify the area
        $area = $areaByReaderIdAndAntennaName($readerId, $antennaName);

        // Validate area existence
        if ($area === null) {
            $instance->newEvents[] = ScanDiscardedForNonExistingAntennaByName::raise($instance->id, $readerId, $antennaName, $clock);

            return $instance;
        }

        // Validate the area is active
        if (! $area->isActive()) {
            $instance->newEvents[] = ScanDiscardedForAntennasAreaNotActive::raise($instance->id, $area->getId(), $epc, $antennaName, $cardStringId, $clock);

            return $instance;
        }

        // Ignore the scan if it's due to debounce
        if ($ignoreScanDueToDebouncing($area->getId(), $epc, $area->getDebouncingSeconds())) {
            $instance->newEvents[] = ScanIgnoredDueToDebouncing::raise($instance->id, $area->getId(), $epc, $peakRssi, $scanTime, $clock);

            return $instance;
        }

        // Associate the scan to the area
        $instance->newEvents[] = ScanAssociatedToArea::raise($instance->id, $area->getId(), $epc, $peakRssi, $scanTime, $cardStringId, $clock);

        // Associate the scan to the card
        try {
            $cardData = $findCardFromStringId($area->getLicense()->getId(), $cardStringId);

            $instance->newEvents[] = ScanAssociatedToCard::raise(
                $instance->id,
                $area->getId(),
                $epc,
                $cardStringId,
                $cardData['cardId'],
                $clock,
            );
        } catch (CardNotFound) {
        }

        return $instance;
    }

    /* ... metodi ausiliari ... */
}
```


= Verifica e validazione
<cap:verifica-validazione>
In questo capitolo si parlerà anche dell'implementazione dei test di unità e integrazione per le funzionalità implementate, ma è importante premettere che, in accordo con il tutor interno, si è deciso di *dare priorità dell'implementazione delle funzionalità* in modo da poterle completare nei tempi previsti; per questo motivo i test implementati coprono solamente le classi strettamente legate al dominio di KanbanBOX, come ad esempio `RfidEventsMessageSerializer` o `RfidEventsMessageHandler`, mentre non sono stati implementati i test di classi strettamente legate a servizi esterni su cui si ha meno controllo, come `AwsIotClientImplementation` che, interagendo con le API di AWS, risulta molto più oneroso da testare.

Nonostante questo, si può affermare che le classi nel dominio di KanbanBOX sono state esaustivamente testate, dato che la CI [@cap:verifica-validazione-ci] verifica che le classi in questione siano state correttamente testate.

== Analisi statica del codice
<cap:analisi-statica>
Per aumentare l'affidabilità del codice e ridurre i difetti intercettabili prima dell'esecuzione, nel progetto sono stati introdotti strumenti di *analisi statica* che possono essere eseguiti arbitrariamente, in locale, tramite target dedicati del `Makefile`. \
Questi controlli sono integrati anche nella pipeline di CI [@cap:verifica-validazione-ci] e vengono eseguiti automaticamente.

Gli strumenti principali utilizzati sono:
- *PHPCS* (PHP Coding Standards): effettua il controllo di *conformità allo standard di codifica* e individua violazioni di stile basandosi su regole di qualità configurate nel progetto, come naming, spaziature, indentazione, ecc. . \ Nel progetto `phpcs` *non modifica* i file ma si limita a produrre un report e a far fallire l'esecuzione (e la CI) se il numero o la severità delle violazioni supera quanto consentito dalla configurazione.
- *PHPCBF* (PHP Code Beautifier and Fixer): è il *"complemento correttivo"* di PHPCS e applica le correzioni che possono essere automatizzate. In pratica, quando eseguito tramite `make phpcbf`, può *modificare direttamente i file sorgenti* normalizzando aspetti come indentazione, rimozione di trailing whitespace, aggiunta del newline finale e altre correzioni a non distruttive.
- *Psalm*: esegue analisi statica sul codice PHP con l'obiettivo di individuare *potenziali bug* e *incoerenze di tipizzazione*. Basandosi su tipi nativi e annotazioni PHPDoc (ad es. `@psalm-type` mostrato in @cap:rfid-events-message-serializer), Psalm segnala problemi come: tipi incompatibili tra argomenti e parametri, valori `null` non gestiti, return type errati o mancanti e altri problemi che in PHP emergerebbero solo a esecuzione. \ Psalm *non applica modifiche* al codice, ma fallisce la validazione se trova errori oltre le soglie configurate.

== Implementazione dei test di unità
<cap:verifica-validazione-test-unitari>
I test di unità del progetto sono stati implementati principalmente tramite *PHPUnit*, con classi di test che estendono `TestCase`.
Lo scopo del test di unità è verificare il comportamento di una singola unità (classe o metodo) *in isolamento* dal resto del sistema, rendendo i test veloci, deterministici e semplici da eseguire in locale e in CI.

Il blocco di codice seguente mostra un esempio reale di test di unità per `DownloadReaderCertificateRow`, ovvero una *row operation* della tabella di gestione dei reader RFID (descritta nella sezione @cap:download-reader-certificate) e verrà sfruttato per descrivere, in modo generico, il processo di implementazione dei test di unità adottato in KanbanBOX.

Nel dettaglio, questi sono i *passaggi* seguiti per implementare i test di unità:
- *inizializzazione comune tramite `setUp()`*: i test creano le dipendenze condivise (mock e helper) una sola volta; nell'esempio vengono creati i mock di `TwigEnvironment`, `InternalUrlBuilder` e `GetTranslationMock`, poi viene inizializzato `TestingHelper`, una classe di supporto per semplificare la costruzione di oggetti usati frequentemente;
- *preparazione*: si costruisce l'oggetto da testare e si prepara l'input del caso d'uso (ad es. `RowId` e `Table`), configurando i mock in base allo scenario;
- *esecuzione*: si invoca il metodo sotto test; nel caso di una *row operation* questo avviene tramite `handle(...)`, che incapsula la logica di conferma e delega al metodo `execute(...)` solo quando i parametri indicano che l'utente ha confermato;
- *assert*: si verifica l'output tramite asserzioni, cioè metodi che controllano che il risultato dell'esecuzione sia conforme a quanto atteso.

Un aspetto centrale nell'approccio ai test unitari è l'uso dei *mock* per sostituire dipendenze esterne o non rilevanti per quel test.
Nel frammento in esempio, `TwigEnvironment` e `InternalUrlBuilder` vengono sostituiti tramite `$this->createMock(...)`: questo consente di iniettare dipendenze valide senza dover predisporre un sistema di template reale o una configurazione completa di routing.

PHPUnit espone due modalità principali quando si lavora con un mock:
- *stub*: si imposta un valore di ritorno per simulare un comportamento (es. `method(...)->willReturn(...)`);
- *expectation*: si verifica che un metodo venga chiamato un certo numero di volte e/o con certi argomenti (es. `expects($this->once())->method(...)->with(...)`).
Nell'esempio la combinazione tra *expectation* e *stub* viene usata per controllare l'interazione con `InternalUrlBuilder`: nel test `testExecute()` ci si aspetta che `build(...)` venga chiamato *una sola volta* con un path costruito a partire dal `RowId`, e si imposta il valore di ritorno per rendere l'esito deterministico:
```php
$this->urlBuilder
    ->expects(self::once())
    ->method('build')
    ->with('rfid/download_certificate/' . $rowId->id)
    ->willReturn($expectedUrl);
```
Nel test `testExecuteWithoutConfirmation()` invece si imposta `expects(self::never())` per verificare che, in assenza di conferma, l'URL non venga nemmeno costruito (quindi non vengano eseguite operazioni non necessarie).

Per verificare l'esito, vengono usate *asserzioni* fornite da `TestCase`.
Nel codice si vede l'uso di:
- `self::assertEquals(...)`, usato per confrontare oggetti risposta complessi (ad es. `RedirectToLink`) con un valore atteso costruito dal test;
- `self::assertInstanceOf(...)`, utile quando è sufficiente verificare *il tipo* del risultato (ad es. `AskConfirmation` quando manca la conferma) senza legarsi ai dettagli interni dell'oggetto.
In altri casi (non mostrati) è comune usare anche `assertSame` (identità), `assertTrue/assertFalse` (condizioni) o `expectException` (verifica di eccezioni).

Attenzione, nel frammento compare anche l'uso di `assert(...)` del linguaggio (non di PHPUnit): in questo contesto viene usato soprattutto come supporto alla *tipizzazione* e all'analisi statica, e non come meccanismo di verifica del test.
```php
<?php
#[CoversClass(DownloadReaderCertificateRow::class)]
class DownloadReaderCertificateRowTest extends TestCase
{
    /** @var TwigEnvironment&MockObject */
    private TwigEnvironment $twigEnvironment;

    /** @var InternalUrlBuilder&MockObject */
    private InternalUrlBuilder $urlBuilder;

    private GetTranslationMock $getTranslation;
    private TestingHelper $testingHelper;

    protected function setUp(): void
    {
        $this->twigEnvironment = $this->createMock(TwigEnvironment::class);
        $this->urlBuilder      = $this->createMock(InternalUrlBuilder::class);

        $this->getTranslation = new GetTranslationMock();
        $this->testingHelper  = new TestingHelper();
    }

    public function testExecute(): void
    {
        $downloadReaderCertificateRow = DownloadReaderCertificateRow::create(
            'download_certificate',
            'Download Certificate',
            'download',
            Language::EN,
            $this->getTranslation,
            $this->twigEnvironment,
            $this->urlBuilder,
        );

        $rowId = new RowId('123');
        $table = $this->testingHelper->buildTable('readerId');

        $expectedUrl = new Uri('http://example.com/rfid/download_certificate/123');
        $this->urlBuilder
            ->expects(self::once())
            ->method('build')
            ->with('rfid/download_certificate/' . $rowId->id)
            ->willReturn($expectedUrl);

        $response = $downloadReaderCertificateRow->handle($rowId, ['confirm' => 'yes'], $table);

        $expectedResponse = new RedirectToLink($expectedUrl, Target::NewTab, reloadRow: true);
        self::assertEquals($expectedResponse, $response);
    }

    public function testExecuteWithoutConfirmation(): void
    {
        $downloadReaderCertificateRow = DownloadReaderCertificateRow::create(
            'download_certificate',
            'Download Certificate',
            'download',
            Language::EN,
            $this->getTranslation,
            TwigEnvironmentMock::createFakeEnvironment(
                ['CustomTable/Body/Row/Operation/askConfirmation.twig'],
                [
                    [
                        'messages' => ['rfid_download_certificate_confirmation_[]_en_'],
                        'buttons' => [
                            ['name' => 'general_confirm_[]_en_', 'icon' => 'tick', 'value' => 'yes'],
                            ['name' => 'gen_cancel_[]_en_', 'icon' => 'cross', 'value' => 'cancel'],
                        ],
                    ],
                ],
            ),
            $this->urlBuilder,
        );

        $rowId = new RowId('123');

        $this->urlBuilder->expects(self::never())->method('build');

        $response = $downloadReaderCertificateRow->handle($rowId, [], $this->testingHelper->buildTable('readerId'));

        self::assertInstanceOf(AskConfirmation::class, $response);
    }
}
```
== Implementazione dei test di integrazione
I test di integrazione hanno l'obiettivo di verificare che *più componenti collaborino correttamente* tra loro, includendo tipicamente la persistenza su database o l'uso di servizi esterni reali.

Il frammento di codice seguente mostra un esempio di test di integrazione per `RfidEventsMessageHandler`, che gestisce i messaggi RFID decodificati dal worker. Il test estende `IsolatedDatabaseTransactionTestCase`: questa classe base prepara un ambiente di test con un *container* disponibile (`$this->container`) e un database eseguito in maniera *isolata*, tipicamente tramite una transazione che viene ripristinata a fine test. In questo modo ogni test può leggere/scrivere su DB senza "sporcare" lo stato per i test successivi.

Nel metodo `setUp()` si nota un pattern ricorrente:
- si invocano le operazioni di setup della classe base (`parent::setUp()`);
- si recuperano dal container implementazioni reali (in questo caso `RfidScanRepository`, `RfidAreaByReaderIdAndAntennaName`, `FindCardFromStringId`, `Clock`);
- si decide in modo esplicito cosa inizializzare tramite *mock*; in questo caso `CommandBus` viene sostituito con un mock perché l'interesse del test è verificare che l'handler *invochi* il comando corretto.

Anche nei test di integrazione rimangono validi i passaggi mostrati per i test di unità:
- *preparazione*: si costruisce l'input del caso d'uso, che in questo caso è un messaggio di tipo `ReadTagEventsMessage` o `ReportEventsMessage` (a seconda del caso), e si configurano i mock se necessario;
- *esecuzione*: si invoca il metodo `handle(...)` dell'handler, che rappresenta il punto di ingresso per i messaggi decodificati dal worker;
- *assert*: si verifica che il risultato dell'esecuzione sia quello atteso.

Anche in questa tipologia di test possono essere sfruttate le modalità `stub` ed `expectation` dei mock, spiegati nel capitolo @cap:verifica-validazione-test-unitari, ad esempio per verificare che il `CommandBus` venga invocato con il comando corretto quando si gestisce un messaggio di tipo *heartbeat*.
```php
<?php
#[CoversClass(ReadTagEventsMessage::class)]
#[CoversClass(RfidEventsMessageHandler::class)]
class RfidEventsMessageHandlerTest extends IsolatedDatabaseTransactionTestCase
{
    private RfidScanRepository $rfidScanRepository;
    private RfidAreaByReaderIdAndAntennaName $rfidAreaIdByReaderIdAndAntennaName;
    private IgnoreScanDueToDebouncing $ignoreScanDueToDebouncing;
    private FindCardFromStringId $findCardFromStringId;
    private StringIdFromEpc $stringIdFromEpc;
    private Clock $clock;
    private RfidEventsMessageHandler $rfidEventsMessageHandler;

    /** @var CommandBus&MockObject */
    private CommandBus $commandBus;

    public function setUp(): void
    {
        parent::setUp();

        $this->rfidScanRepository                 = $this->container->get(RfidScanRepository::class);
        $this->rfidAreaIdByReaderIdAndAntennaName = $this->container->get(RfidAreaByReaderIdAndAntennaName::class);
        $this->ignoreScanDueToDebouncing          = $this->container->get(IgnoreScanDueToDebouncing::class);
        $this->stringIdFromEpc                    = new DefaultStringIdFromEpc();
        $this->findCardFromStringId               = $this->container->get(FindCardFromStringId::class);
        $this->clock                              = $this->container->get(Clock::class);
        $this->commandBus                         = $this->createMock(CommandBus::class);

        $this->rfidEventsMessageHandler = new RfidEventsMessageHandler(
            $this->rfidScanRepository,
            $this->ignoreScanDueToDebouncing,
            $this->rfidAreaIdByReaderIdAndAntennaName,
            $this->stringIdFromEpc,
            $this->findCardFromStringId,
            $this->clock,
            $this->commandBus,
        );
    }

    public function testHandlerWithRfidScan(): void
    {
        $readTagEventsMessage = new ReadTagEventsMessage(
            MessageId::fromString('1f11d640-b2c8-6772-b39d-4202f28cd586'),
            '3034257BF461AABDD0000001',
            'type',
            new DateTimeImmutable('2026-02-25T12:00:00Z'),
            99,
            1.0,
            27,
            'format',
            1,
            1,
            RfidReaderId::fromString('1f11d640-b2c8-6772-b39d-4202f28cd586'),
        );

        $this->rfidEventsMessageHandler->handle($readTagEventsMessage);

        $storedScan = $this->rfidScanRepository->get(RfidScanId::fromString('1f11d640-b2c8-6772-b39d-4202f28cd586'));
        self::assertEquals($readTagEventsMessage->clientId->id, $storedScan->aggregateRootId()->toString());
    }

    public function testHandlerWithReportEventsMessage(): void
    {
        $reportEventsMessage                   = new ReportEventsMessage(
            ReaderReportContainsHeartbeat::from(
                new DateTimeImmutable('2026-02-25T12:00:00Z'),
                [
                    'rfidReport' => '1f11d640-b2c8-6772-b39d-4202f28cd586',
                    'reader' => '123a4567-b2c8-6772-b39d-4202f28cd586',
                ],
            ),
        );
        $updateLastHeartbeatOfTheReaderCommand = UpdateLastHeartbeatOfTheReaderCommand::fromReaderReportContainsHeartbeat(
            $reportEventsMessage->readerReportContainsHeartbeat,
        );

        $this->commandBus->expects(self::once())
            ->method('execute')
            ->with($updateLastHeartbeatOfTheReaderCommand);

        $this->rfidEventsMessageHandler->handle($reportEventsMessage);
    }
}
```

== Continuous Integration
<cap:verifica-validazione-ci>
Viene citata la *Continuous Integration* (CI) in questo capitolo perché è proprio tramite le Github Actions [@cap:versionamento-integrazione] che vengono eseguite le operazioni di verifica e validazione prima che il codice venga inserito in produzione.

Nella CI implementata da KanbanBOX vengono eseguiti i workflow relativi a tutti gli strumenti di analisi statica mostrati in @cap:analisi-statica, e successivamente anche i test di unità e integrazione descritti nei capitoli precedenti. \
Oltre a questi controlli, la CI esegue anche altri workflow relativi a strumenti che non sono stati affrontati in modo rilevanti durante questo progetto; tra questi risulta interessante menzionare:
- *infection*, strumento per l'analisi della *mutazione* del codice, che verifica l'efficacia dei test esistenti introducendo modifiche graduali al codice e controllando se i test rispondono alle variazioni;
- *visual test* tramite *Playwright*, che consente di verificare il funzionamento dei componenti dell'interfaccia utente.
