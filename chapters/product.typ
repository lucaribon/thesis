#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

#show: codly-init.with()
#codly(languages: 
    (php: (name: "PHP")),
)

// TODO: capitoli di sicuro da sistemare (aggiungere/togliere/cambiare capitoli) 
// contenuti e lunghezza molto variabili in base all'argomento scelto, indicativamente tra le 20 e le 40 pagine (comprensive di tabelle e immagini), distribuite tra 1-3 capitoli
#pagebreak(to:"odd")

#set par(justify: false)
// = Descrizione del lavoro svolto

// ?Oppure separare architettura e progettazione
// ?Forse archietettura e progettazione tenute a parte, poi nei capitoli dei varii domini si parla della codifica
= Architettura e progettazione
<cap:architettura>
#v(1em)
#text(style: "italic", [
    // Breve introduzione al capitolo
])

#v(1em)

== Flusso del sistema
<cap:flusso-del-sistema>
// TODO: figure flusso del sistema
// TODO: espandere
1. *Reader RFID*: dispositivo hardware che legge i tag RFID e invia i dati dei tag letti ad AWS IoT tramite il protocollo MQTT;
2. *AWS IoT*: piattaforma cloud che funge da broker MQTT, gestendo autenticazione, autorizzazione e instradamento dei messaggi tra i reader RFID e il backend di KanbanBox;
3. *AWS SQS*: servizio di code di messaggi che riceve i messaggi contenenti i dati dei tag letti da AWS IoT e li rende disponibili per il backend di KanbanBox;
4. *KanbanBOX*: backend che elabora i dati dei tag RFID ricevuti da AWS SQS per aggiornare lo stato delle schede Kanban. \ KanbanBox permette anche di gestire i reader e la loro configurazione di comunicazione con l'endpoint di AWS IoT e l'operating mode (Simple, Conveyor, Inventory, ecc.); questo avviene tramite un form raggiungibile tramite _row operation_ nella tabella dei reader.

== AWS
// IOT e SQS

=== Struttura del topic


== Design pattern utilizzati
// ?forse no

= Gestione dei reader RFID
// TODO: descrizione dello scopo
// TODO: figure grafico UML classe/classi
// ?FE separato o unito a BE
// TODO: descrizione dettagliata di classi, campi, metodi come in specifica tecnica, con esempi di codice

=== AwsIotClient

=== MqttClient

== Configurazione dei reader RFID

= Ricezione dei tag RFID letti
// == Architettura
// == Progettazione
Come anticipato nella Sezione @cap:flusso-del-sistema i dati dei tag RFID letti dai reader vengono estratti in _pull_ da AWS SQS tramite un _worker_. Una volta estratto un messaggio il _worker_ lo distribuisce, in base al tipo di messaggio, ad un opportuno _handler_, che nel caso dei messaggi ricevuti dalla coda 'rfid-reader-tag-events' è il `RfidEventsMessageSerializer`.

Di seguito viene mostrato come il _worker_ viene instaziato nella classe `Container`, ovvero il contenitore di dipendenze del backend di KanbanBox che serve per gestire la _dependency injection_.
```php
<?php
$rfidEventsQueueConfiguration = $getConfig->getRfidEventsQueueConfiguration();
                    $rfidEventsReceiverLocator    = new EmptyContainer();
                    $rfidEventsReceiverLocator->set(
                        $rfidEventsQueueConfiguration->queueName,
                        $awsSqsFactory->buildReceiver(
                            $rfidEventsQueueConfiguration,
                            new RfidEventsMessageSerializer($clock),
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

== Codifica
=== RfidEventsMessageSerializer

//      TODO: improve decodedEnvelope handling to be cleaner
```php
<?php
final readonly class RfidEventsMessageSerializer implements SerializerInterface
{
        public function __construct(
            private Clock $clock,
        ) {
        }

    /** @inheritdoc */
    public function decode(array $encodedEnvelope): Envelope
    {
        /** @var RfidMessageBody $decodedEnvelope */
        $decodedEnvelope = json_decode($encodedEnvelope['body'], true, 512, JSON_THROW_ON_ERROR);

        if (array_key_exists('type', $decodedEnvelope['$unknown'][0]) && $decodedEnvelope['$unknown'][0]['type'] === 'heartbeat') {
            $report = [
                'rfidReport' => Uuid::uuid4()->toString(),
                'reader' => $decodedEnvelope['clientId'] ?? null,
            ];

            return Envelope::wrap(
                new ReportEventsMessage(
                    ReaderReportContainsHeartbeat::from(
                        $this->clock->now(),
                        $report,
                    ),
                )
            );
        } else if (array_key_exists('idHex', $decodedEnvelope['$unknown'][0]['data'])) {
            $formattedMessage = [
                'idHex' => $decodedEnvelope['$unknown'][0]['data']['idHex'] ?? '',
                'type' => $decodedEnvelope['$unknown'][0]['type'] ?? '',
                'timestamp' => $decodedEnvelope['$unknown'][0]['timestamp'] ?? '',
                'reads' => $decodedEnvelope['$unknown'][0]['data']['reads'] ?? 0,
                'phase' => $decodedEnvelope['$unknown'][0]['data']['phase'] ?? 0.0,
                'peakRssi' => $decodedEnvelope['$unknown'][0]['data']['peakRssi'] ?? 0,
                'format' => $decodedEnvelope['$unknown'][0]['data']['format'] ?? '',
                'eventNum' => $decodedEnvelope['$unknown'][0]['data']['eventNum'] ?? 0,
                'antenna' => $decodedEnvelope['$unknown'][0]['data']['antenna'] ?? 0,
                'clientId' => $decodedEnvelope['clientId'] ?? '',
            ];

            $message = ReadTagEventsMessage::fromQueueMessageBody($formattedMessage);

            return Envelope::wrap($message);
        }

        return Envelope::wrap(
            new StringMessage('Received invalid format or content message from RFID reader: ' . json_encode($decodedEnvelope, JSON_THROW_ON_ERROR)),
        );
    }

    /** @inheritdoc */
    public function encode(Envelope $envelope): array
    {
        // We don't care for now
        throw new Exception('Not implemented for now since we never send message but we only receive them');
    }
}
```

=== ReadTagEventsMessage
=== ReadTagEventsMessageHandler

= Verifica e validazione
