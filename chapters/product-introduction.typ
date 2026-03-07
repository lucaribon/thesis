#import "../config/thesis-config.typ": gloss

#pagebreak(to:"odd")

= Introduzione teorica // max 20 pagine indicativamente
<cap:introduzione-teorica>

// TODO: forse utile:  è in formato #gloss("PFX", <glossary-PFX>), generato dal backend di KanbanBox, che include le chiavi e i certificati in formato #gloss("PEM", <glossary-PEM>) forniti da AWS IoT; si è deciso di fornire il certificato PFX tramite KanbanBox per semplificare la procedura di configurazione del reader agli installatori, in quanto è l'unico formato ammesso dai reader Zebra e la generazione non è immediata per utenti con poca dimestichezza. ???

// == Tecnologie analizzate
// == Tecnologie analizzate

== Aspetti teorici rilevanti

=== Protocolli di comunicazione
I *protocolli di comunicazione* sono parte integrante del progetto in quanto, come anticipato, uno degli obiettivi principali è quello di sostituire l'attuale protocollo HTTP con un protocollo più efficiente e adatto alla comunicazione tra dispositivi IoT, ovvero MQTT.

*HTTP* è il protocollo più diffuso per la comunicazione sul Web e costituisce la base delle #gloss("API", <glossary-api>) RESTful, che costituivano il metodo di comunicazione utilizzato nella precedentemente implementazione dei reader su KanbanBOX. 
Infatti i reader Zebra, una volta configurati, mettono a disposizione un'interfaccia che permette di inviare comandi e ricevere dati dei tag letti tramite richieste HTTP. Questa soluzione, sebbene semplice da implementare, presenta diverse limitazioni per il caso d'uso di KanbanBox:
- *overhead elevato*: ogni richiesta HTTP include un _header_ di dimensioni considerevoli rispetto al _payload_ effettivo; in scenari come questo dove i lettori RFID devono inviare frequentemente piccoli pacchetti di dati, l'aumento di overhead su grandi quantità di messaggi inizia a diventare significativo;
- *assenza di comunicazione bidirezionale nativa*: HTTP non prevede un meccanismo nativo per cui il server possa inviare messaggi al client senza che quest'ultimo li richieda esplicitamente, rendendo complessa l'implementazione di operazioni come la configurazione remota dei lettori RFID;
- *nessuna garanzia di consegna*: HTTP non offre meccanismi integrati di _Quality of Service_ per garantire la consegna dei messaggi in caso di disconnessioni temporanee, il che è fondamentale in un contesto dove l'affidabilità dell'intero sistema è cruciale.

Queste limitazioni hanno motivato la migrazione a MQTT come protocollo per la comunicazione tra i lettori RFID e KanbanBOX.

=== MQTT
Come anticipato *MQTT* è stato scelto proprio per ovviare alla limitazioni che HTTP presenta in questo contesto.
Infatti MQTT è protocollo di comunicazione progettato specificamente per la comunicazione tra dispositivi IoT, con *ottime performance* anche con risorse limitate, *affidabile* e adatto a gestire *grandi quantità* di *dispositivi* e *messaggi*. 

L'architettura di MQTT si basa su un modello di _*publish/subscribe*_, in cui i dispositivi (in questo caso i lettori RFID) pubblicano messaggi su specifici _*topic*_ e altri dispositivi (come il backend di KanbanBOX) si sottoscrivono a questi topic per ricevere i messaggi. Il tutto viene orchestrato da un _*broker*_ MQTT, ovvero un server che gestisce la distribuzione dei messaggi tra i publisher e i subscriber tramite i topic definiti.

I topic in MQTT possono essere strutturati in modo gerarchico, dove ogni livello viene nominato con caratteri alfanumerici e separato da una barra ("/"). Si possono anche utilizzare delle #gloss("wildcard", <glossary-wildcard>) per sottoscriversi a più topic contemporaneamente, ad esempio utilizzando "\#" che sostituisce più livelli di topic, o "+" che sostituisce un singolo livello di topic.

Per ogni topic può essere definito un livello di _*Quality of Service*_ (QoS) che determina con quale garanzia i messaggi vengono consegnati ai dispositivi sottoscritti, con tre livelli disponibili: 0 (al massimo una consegna), 1 (almeno una consegna) e 2 (esattamente una consegna). Inoltre, sempre con granularità a livello di topic, è possibile impostare la _*retention*_ dei messaggi, ovvero un meccanismo dove il broker memorizza l'ultimo messaggio pubblicato su un topic e lo rende disponibili ai nuovi dispositivi iscritti al topic, così che tutti i dispositivi conoscano lo stato del topic anche dopo svariato tempo dall'ultima pubblicazione di un messaggio.\
Diversi broker implementano anche la _*persistence*_ dei messaggi, ovvero la memorizzazione dei messaggi su disco per garantire la loro conservazione anche in caso di malfunzionamenti software o hardware (che non intacchino il disco stesso) della macchina su cui il broker è in esecuzione.

Come anticipato i *pacchetti* (messaggi) di MQTT hanno un overhead più essenziale rispetto a quelli di HTTP, infatti la loro struttura è la seguente:
- *fixed header*: di dimensione tra i 2 e i 5 _byte_, contiene informazioni di controllo come il tipo di messaggio (CONNECT, PUBLISH, SUBSCRIBE, ecc.), e altre _flag_ per il controllo di parametri come il livello di QoS o la retention del messaggio;
- *variable header*: opzionale e di dimensione variabile, contiene informazioni aggiuntive come il protocollo e la versione utilizzati, o un identificatore univoco del pacchetto;
- *payload*: di dimensione variabile, contiene i dati effettivi del messaggio, che in questo caso saranno le letture dei tag RFID. 

// TODO: figure della struttura dei pacchetti MQTT VS HTTP

== Strumenti scelti
In questa sezione vengono esposti i servizi e le tecnologie scelte per affrontare il progetto e i fattori che hanno portato a preferirli rispetto alle alternative disponibili.

=== Hosting del broker MQTT
Per l'hosting del broker MQTT e dei servizi a supporto della comunicazione tra i reader RFID e KanbanBOX si è optato fin da subito per una soluzione *cloud*. Questa scelta è stata dettata da diversi fattori: innanzi tutto, l'azienda non disponeva di infrastruttura hardware adeguata a questo scopo; inoltre, uno degli obiettivi del progetto era quello di permettere la configurazione da *remoto* dei reader RFID tramite KanbanBOX. Questo richiede di accedere alle reti interne dei clienti (alle quali i reader si connettono per raggiungere la rete esterna) che sono tipicamente soggette a *regole di accesso molto restrittive*. Risulta quindi più agevole richiedere ai clienti di abilitare il traffico verso i server di un servizio cloud riconosciuto e affidabile, piuttosto che verso i server locali di KanbanBOX.

Di conseguenza sono state valutate le opzioni di hosting in cloud disponibili sul mercato, prima di tutto confrontando i _provider_ che offrono soluzioni adatte tra cui Google Cloud, Microsoft Azure e *Amazon Web Services*. La scelta è ricaduta su AWS, principalmente per la già consolidata presenza di servizi AWS nell'infrastruttura di KanbanBOX, così da poter integrare la nuova infrastruttura con in servizi già in uso in KanbanBOX.

In concomitanza con la scelta del provider sono stati confrontati i servizi offerti dai provider sopra citati, in particolare, una volta indirizzatisi verso AWS, sono stati presi in considerazione AWS EC2 e AWS IoT Core.\
*AWS EC2* è un servizio di _#gloss("Infrastructure as a Service", <glossary-iass>)_ che permette di istanziare macchine virtuali su cui è possibile installare e configurare qualsiasi software, generalmente con l'obiettivo di utilizzarlo come server; nel nostro caso, si sarebbe trattato di installare un broker MQTT (come Mosquitto) e configurarlo per gestire la comunicazione tra i reader RFID e KanbanBOX.\
Anche *AWS IoT Core* è un servizio di _Infrastructure as a Service_, ma è specificamente fornito per la gestione di dispositivi IoT, infatti include un broker MQTT e tutte le funzionalità a supporto come la gestione dei dispositivi, la configurazione di meccanismi di sicurezza e l'integrazione con altri servizi AWS.\
Il sottostante dei due servizi è molto simile, infatti entrambi si basano sull'infrastruttura EC2, ma AWS IoT Core presenta i seguenti *vantaggi* che hanno portato a preferirlo per questo progetto:
- *configurazione e gestione semplificata*: AWS IoT Core è progettato specificamente per la gestione di dispositivi IoT e questo porta a dei tempi e sforzi necessari per configurare e gestire il broker MQTT molto inferiori rispetto a quelli necessari con AWS EC2; inoltre, AWS IoT Core include delle *integrazioni* con servizi come AWS SQS che hanno facilitato molto l'implementazione di alcune funzionalità come la coda asincrona per la gestione dei messaggi in ingresso dai reader RFID;
- *costi irrisori*: AWS IoT Core prevede un modello di _pricing on demand_, ovvero che si paga in base all'effettivo utilizzo del servizio misurandolo in messaggi trasmessi, dispositivi connessi, durata della connessione e altre metriche; confrontando le stime di utilizzo di AWS EC2 @aws-ec2-pricing e AWS IoT Core @aws-iot-pricing si nota come la differenza di costi non giustifichi le complicazioni date dall'utilizzo di AWS EC2; inoltre, in questo caso, il modello di pagamento _on demand_ di EC2 risulta più difficile da gestire e quindi in periodi di utilizzo meno intenso c'è il rischio di pagare più del necessario, rispetto ad AWS IoT Core dove l'adeguamento al carico di lavoro è completamente automatizzato.

=== Coda asincrona

=== Stack di sviluppo
- API di AWS IoT
- php-mqtt