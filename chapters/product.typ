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

= Architettura e progettazione
<cap:architettura>

== Flusso del sistema
<cap:flusso-del-sistema>



= Codifica

== Design pattern utilizzati
// ?forse no?
=== Command

== Gestione dei reader RFID
// TODO: descrizione dello scopo
// TODO: figure grafico UML classe/classi
// ?FE separato o unito a BE
// TODO: descrizione dettagliata di classi, campi, metodi come in specifica tecnica, con esempi di codice
=== Reader
// TODO: parlare dei vari command e commandhandler e come vengono usati ma senza entrare troppo nei dettagli, c'è già un riferimento nei design pattern
=== AwsIotClient
// TODO: non mettere l'implementazione ma solo la firma dei metodi secondo me; non ha senso metterla dato che alla fine è un wrapper, quindi mettere le firme dei metodi e cosa fanno, specificando poi che alla fine è un wrapper per la SDK AWS IoT Core dove le chiamate vengono adattate al nostro caso d'uso
=== MqttClient


== Configurazione dei reader RFID

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

== Ricezione dei tag RFID letti
=== RfidEventsMessageSerializer
//      TODO: improve decodedEnvelope handling to be cleaner
```php
<?php
/** @psalm-type RfidMessageBody = array{} */
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
=== ReadTagEventsMessageHandler


= Verifica e validazione
