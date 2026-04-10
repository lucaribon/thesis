#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "../config/thesis-config.typ": gloss

#show: codly-init.with()
#codly(languages: 
    (php: (name: "PHP")),
)

// contenuti e lunghezza molto variabili in base all'argomento scelto, indicativamente tra le 20 e le 40 pagine (comprensive di tabelle e immagini), distribuite tra 1-3 capitoli
#pagebreak(to:"odd")

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
Il processamento consiste  nel distinguere la tipologia di messaggio ricevuto e nell'estrazione dei dati rilevanti da esso; nel caso dei messaggi dei tag RFID i dati di interesse sono principalmente l'identificativo del tag letto, il timestamp di lettura, il reader che ha generato il messaggio e i dati tecnici di lettura (#gloss("RSSI", <glossary-RSSI>), antenna, numero di letture, etc.), questi vengono poi utilizzati per aggiornare lo stato del *kanban* associato a quel tag, se esistente, e per mostrare la lettura del cartellino nella dashboard dei tag letti. \
Mentre per i messaggi di heartbeat i dati di interesse sono l'identificativo del reader e il timestamp di ricezione del messaggio, utilizzati per *aggiornare lo stato di connessione* del reader in modo da informare l'utente sull'operatività del reader stesso.

Il secondo flusso di dati riguarda la *configurazione dei reader* tramite l'interfaccia web di KanbanBOX, che tramite il protocollo MQTT invia comandi ai reader per configurare i parametri di connessione e la modalità operativa e riceve l'esito dell'applicazione dei comandi dai reader. \
Tutti i dati riguardanti a questo flusso passano per il broker *MQTT* di AWS IoT Core, attraverso i topic descritti nella sezione dedicata alla struttura dei topic [@cap:struttura-topic].

L'ultimo flusso è relativo alla comunicazione verso AWS IoT Core tramite l'SDK di AWS per PHP, che viene utilizzato principalmente per la *gestione delle entità di AWS IoT* Core, in particolare per la ricezione del certificato e delle chiavi necessari per la generazione del file PFX. 


= Codifica

== Design pattern utilizzati
=== Dependency Injection
=== Factory
// ?forse no?
=== Builder
// ?forse no?
=== Command
// ?forse no?
=== Handler
// ?forse no?

== Gestione dei reader RFID
// TODO: descrizione dello scopo
// TODO: figure grafico UML classe/classi
// ?FE separato o unito a BE
// TODO: descrizione dettagliata di classi, campi, metodi come in specifica tecnica, con esempi di codice
=== AwsIotClient
// TODO: non mettere l'implementazione ma solo la firma dei metodi secondo me; non ha senso metterla dato che alla fine è un wrapper, quindi mettere le firme dei metodi e cosa fanno, specificando poi che alla fine è un wrapper per la SDK AWS IoT Core dove le chiamate vengono adattate al nostro caso d'uso
=== MqttClient
=== Reader
// TODO: parlare dei vari command, commandhandler, onAwsIot e come vengono usati ma senza entrare troppo nei dettagli, c'è già un riferimento nei design pattern


== Configurazione dei reader RFID


== Ricezione dei tag RFID letti

=== Worker
Come anticipato nella Sezione @cap:flusso-del-sistema i dati dei tag RFID letti dai reader vengono estratti in _pull_ da AWS SQS tramite un *_worker_*. Una volta estratto un messaggio il _worker_ lo distribuisce, in base al tipo di messaggio, ad un opportuno *_handler_*, che nel caso dei messaggi ricevuti dalla coda 'rfid-reader-tag-events' è il `RfidEventsMessageSerializer`.

Di seguito viene mostrato come nella classe `Container` @psr-container, ovvero il contenitore di dipendenze del backend di KanbanBox che serve per gestire la _dependency injection_, viene preparato tutto il necessario per costruire il _worker_ dedicato alla lettura degli eventi RFID.

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

// TODO: valutare se tenere i DTO oppure se descriverli velocemente
=== ReadTagEventsMessage
`ReadTagEventsMessage` è il DTO che rappresenta un singolo *tag RFID* letto, che è stato recuperato dalla coda SQS. \
Come  anche in @cap:rfid-events-message-serializer, questo oggetto viene creato dal `RfidEventsMessageSerializer` quando il payload contiene i campi minimi necessari, ovvero l'identificativo del tag `idHex` e l'identificativo del reader `clientId`.

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

I metodi *`toArray()`* e *`from(...)`* sono invece utili per serializzare e deserializzare l'evento, quindi per adattarlo ai formati necessari nel contesto in cui può essere utilizzato.

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
    ): self {
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
    ): self {
        Assert::keyExists($data, 'rfidReport');
        Assert::stringNotEmpty($data['rfidReport']);
        Assert::keyExists($data, 'reader');
        Assert::stringNotEmpty($data['reader']);

        return new self(
            RfidReportId::fromString($data['rfidReport']),
            RfidReaderId::fromString($data['reader']),
            $raisedAt,
        );
    }
}
```

=== RfidEventsMessageHandler


= Verifica e validazione
