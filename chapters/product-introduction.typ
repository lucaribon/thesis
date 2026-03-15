#import "../config/thesis-config.typ": gloss

#pagebreak(to: "odd")

= Introduzione teorica // max 20 pagine indicativamente
<cap:introduzione-teorica>

// TODO: chiedere se ha senso mettere anche tecnologie che non he scelto perché già presenti nel progetto, tipo docker per l'hosting, altre librerie per PHP

// == Tecnologie analizzate

== Aspetti teorici rilevanti

=== Protocolli di comunicazione
I *protocolli di comunicazione* sono parte integrante del progetto in quanto, come anticipato, uno degli obiettivi principali è quello di sostituire l'attuale protocollo HTTP con un protocollo più efficiente e adatto alla comunicazione tra dispositivi IoT, ovvero MQTT.

*HTTP* è il protocollo più diffuso per la comunicazione sul Web e costituisce la base delle #gloss("API", <glossary-api>) RESTful, sui cui si basava il metodo di comunicazione utilizzato nella precedentemente implementazione dei reader in KanbanBOX.
Infatti i reader Zebra, una volta configurati, mettono a disposizione un'interfaccia che permette di inviare comandi e ricevere dati dei tag letti tramite richieste HTTP. Questa soluzione, sebbene semplice da implementare, presenta diverse limitazioni per il caso d'uso di KanbanBOX:
- *overhead elevato*: ogni richiesta HTTP include un _header_ di dimensioni considerevoli rispetto al _payload_ effettivo; in scenari come questo dove i lettori RFID devono inviare frequentemente piccoli pacchetti di dati, l'aumento di overhead su grandi quantità di messaggi inizia a diventare significativo;
- *assenza di comunicazione bidirezionale nativa*: HTTP non prevede un meccanismo nativo per cui il server possa inviare messaggi al client senza che quest'ultimo li richieda esplicitamente, rendendo complessa l'implementazione di operazioni come il _polling_ dei tag letti dal reader;
- *nessuna garanzia di consegna*: HTTP non offre meccanismi integrati di _Quality of Service_ per garantire la consegna dei messaggi in caso di disconnessioni temporanee, il che rappresenta un valore aggiunto in un contesto dove l'affidabilità dell'intero sistema è cruciale.

Queste limitazioni hanno motivato la migrazione a MQTT come protocollo per la comunicazione tra i lettori RFID e KanbanBOX.

=== MQTT
Come anticipato *MQTT* è stato scelto proprio per ovviare alla limitazioni che HTTP presenta in questo contesto.
Infatti MQTT è protocollo di comunicazione progettato specificamente per la comunicazione tra dispositivi IoT, con *ottime performance* anche con risorse limitate, *affidabile* e adatto a gestire *grandi quantità* di *dispositivi* e *messaggi*.

L'architettura di MQTT si basa su un modello di _*publish/subscribe*_, in cui i dispositivi (in questo caso i lettori RFID) pubblicano messaggi su specifici _*topic*_ e altri dispositivi (come ad esempio il backend di KanbanBOX) si sottoscrivono a questi topic per ricevere i messaggi. Il tutto viene orchestrato da un _*broker*_ MQTT, ovvero un server che gestisce la distribuzione dei messaggi tra i publisher e i subscriber tramite i topic definiti.

I topic in MQTT possono essere strutturati in modo *gerarchico*, dove ogni livello viene nominato con caratteri alfanumerici e separato da una barra ("/"). Si possono anche utilizzare delle #gloss("wildcard", <glossary-wildcard>) per sottoscriversi a più topic contemporaneamente.

Per ogni topic può essere definito un livello di _*Quality of Service*_ (QoS) che determina con quale garanzia i messaggi vengono consegnati ai dispositivi sottoscritti, con tre livelli disponibili: 0 (al massimo una consegna), 1 (almeno una consegna) e 2 (esattamente una consegna). Inoltre, sempre con granularità a livello di topic, è possibile impostare la _*retention*_ dei messaggi, ovvero un meccanismo dove il broker memorizza l'ultimo messaggio pubblicato su un topic e lo rende disponibile ai nuovi dispositivi iscritti al topic, così che tutti i dispositivi (compresi quelli appena iscritti) conoscano lo stato del topic anche dopo svariato tempo dall'ultima pubblicazione di un messaggio.\
Diversi broker implementano anche la _*persistence*_ dei messaggi, ovvero la memorizzazione dei messaggi su disco per garantire la loro conservazione anche in caso di malfunzionamenti software o hardware (che non intacchino il disco stesso) della macchina su cui il broker è in esecuzione.

Come anticipato i *pacchetti* (messaggi) di MQTT hanno un overhead più essenziale rispetto a quelli di HTTP, infatti la loro struttura è la seguente:
- *fixed header*: obbligatorio e di 2 _byte_, contiene informazioni di controllo come il tipo di messaggio (CONNECT, PUBLISH, SUBSCRIBE, ecc.), altre _flag_ per il controllo di parametri come il livello di QoS o la retention del messaggio e il numero di byte rimanenti per quel messaggio;
- *variable header*: opzionale e di dimensione variabile, contiene informazioni aggiuntive come il protocollo e la versione utilizzati, o un identificatore univoco del pacchetto;
- *payload*: di dimensione variabile, contiene i dati effettivi del messaggio, che in questo caso saranno le letture dei tag RFID.
Quindi si parla di un overhead minimo di *\~2 byte* per ogni messaggio MQTT, contro gli almeno *\~85 byte* di overhead per ogni richiesta HTTP fatta dai reader.

// TODO: table della struttura dei pacchetti MQTT VS HTTP
#figure(
    table(
        columns: (1fr, 1fr, 1.5fr, 1.5fr, 1.5fr),
        align: center + horizon,
        stroke: 0.5pt,
        inset: 10pt,

        table.cell(colspan: 3, fill: luma(240))[*Fixed Header (2 byte)*],
        table.cell(rowspan: 3, fill: luma(240))[*Variable Header* \ #set text(size: 0.8em); (Dimensione variabile)],
        table.cell(rowspan: 3, fill: luma(240))[*Payload* \ #set text(size: 0.8em); (Dimensione variabile)],

        table.cell(rowspan: 2)[Packet Type \ (4 bit)],
        table.cell(rowspan: 2)[Flag \ (4 bit)],

        table.cell(rowspan: 2)[
            Remaining Length \
            #set text(size: 0.8em)
            (Dimensione variabile, lunghezza del _variable header_ e del _payload_)
        ],
    ),
    caption: "Struttura di un messaggio MQTT con dimensione dei campi",
)

#figure(
    table(
        columns: (1fr, 1.5fr, 1.5fr),
        align: center + horizon,
        stroke: 0.5pt,
        inset: 10pt,

        table.cell(colspan: 3, fill: luma(240))[*Request Line*],

        [Method \ #set text(size: 0.8em); (4 byte)],
        [URI \ #set text(size: 0.8em); (Dimensione variabile)],
        [HTTP Version \ #set text(size: 0.8em); (8 byte + 4 byte per il framing)],

        table.cell(colspan: 3, fill: luma(240))[*Headers*],

        [`Host` \ #set text(size: 0.8em); (6byte per il nome del campo + \~7 byte per l'IP/hostname)],
        [`Content-Type` \ #set text(size: 0.8em); (14 byte per il nome del campo + 16 byte per il valore del campo)],
        [`Content-Length` \ #set text(size: 0.8em); (16 byte per il nome del campo + 1-5 byte per il valore del campo e il framing)],

        table.cell(colspan: 3, fill: luma(240))[*Empty Line ending headers (CRLF)* \ #set text(size: 0.8em); (2 byte)],

        table.cell(colspan: 3, fill: luma(240))[*Payload* \ #set text(size: 0.8em); (Dimensione variabile)],
    ),
    caption: "Struttura di una richiesta HTTP con dimensione dei campi",
)

=== Certificati per l'autenticazione dei dispositivi
Per garantire la sicurezza della comunicazione tra i reader RFID e il broker MQTT, è stato utilizzato il meccanismo di autenticazione basato su certificati _X.509_, integrato in AWS IoT Core.\

Al momento della creazione di un'entità client su AWS IoT Core, la procedura di configurazione permette di scegliere se generare un *certificato* e le relative *chiavi crittografiche* associate a quello specifico client. Una volta generati i file, contenenti quelle che non sono altro che delle stringhe alfanumeriche, è possibile scaricarli in formato _*PEM*_; l'operazione di download è disponibile solamente durante la fase di creazione del client, per policy di AWS atte a garantire la sicurezza della connessione al servizio.

Per rendere più pratica l'installazione dei reader RFID nelle aziende clienti si è deciso di gestire questi file sensibili interamente nel backend di KanbanBOX, in modo da fornire agli installatori, tramite l'interfaccia web, un unico file in formato *_#gloss("PFX", <glossary-PFX>)_*, che incapsula i certificati e le chiavi fornite da AWS, ovvero l'unico formato accettato dai reader Zebra per il caricamento del certificato. In questo modo si evita agli installatori l'onere di dover compiere operazioni macchinose, per utenti che hanno meno dimestichezza con questi strumenti, e rischiose, in caso di fughe di dati.\
Anche lato KanbanBOX i certificati rimangono scaricabili solamente una volta e successivamente vengono rimossi da qualsiasi dispositivo o servizio di archiviazione su cui erano stati memorizzati.

== Strumenti scelti
In questa sezione vengono esposti i servizi e le tecnologie scelte per affrontare il progetto e i fattori che hanno portato a preferirli rispetto alle alternative disponibili.

=== Hosting del broker MQTT
Per l'hosting del broker MQTT e dei servizi a supporto della comunicazione tra i reader RFID e KanbanBOX si è optato fin da subito per una soluzione *cloud*. Questa scelta è stata dettata da diversi fattori: innanzitutto, l'azienda non disponeva di infrastruttura hardware adeguata a questo scopo; inoltre, uno degli obiettivi del progetto era quello di permettere la configurazione da *remoto* dei reader RFID tramite KanbanBOX. Questo richiede di accedere alle reti interne dei clienti (alle quali i reader si connettono per raggiungere la rete esterna) che sono tipicamente soggette a *regole di accesso molto restrittive*. Risulta quindi più agevole e sicuro richiedere ai clienti di abilitare il traffico verso i server di un servizio cloud riconosciuto e affidabile, piuttosto che verso i server locali di KanbanBOX.

Di conseguenza sono state valutate le opzioni di hosting in cloud disponibili sul mercato, prima di tutto confrontando i _provider_ che offrono soluzioni adatte, tra cui Google Cloud, Microsoft Azure e *Amazon Web Services*. La scelta è ricaduta su AWS, principalmente per la già consolidata presenza di servizi AWS nell'infrastruttura di KanbanBOX, così da poter integrare la nuova infrastruttura con in servizi già in uso.

In concomitanza con la scelta del provider sono stati confrontati i servizi offerti dai provider sopra citati, in particolare, una volta indirizzatisi verso AWS, sono stati presi in considerazione AWS EC2 e AWS IoT Core.\
*AWS EC2* è un servizio di tipo _#gloss("Infrastructure as a Service", <glossary-iass>)_ che permette di istanziare macchine virtuali su cui è possibile installare e configurare qualsiasi software, generalmente con l'obiettivo di utilizzarlo come server; nel nostro caso, si sarebbe trattato di installare un broker MQTT (come Mosquitto) e configurarlo per gestire la comunicazione tra i reader RFID e KanbanBOX.\
Anche *AWS IoT Core* è un servizio _Infrastructure as a Service_, ma è specificamente fornito per la gestione di dispositivi IoT, infatti include un broker MQTT e tutte le funzionalità a supporto come la gestione dei dispositivi o la configurazione di meccanismi di sicurezza specifici.\
Il sottostante dei due servizi è molto simile, infatti entrambi si basano su un'infrastruttura EC2, ma AWS IoT Core presenta i seguenti *vantaggi* che hanno portato a preferirlo per questo progetto:
- *configurazione e gestione*: AWS IoT Core è progettato specificamente per la gestione di dispositivi IoT e questo porta a dei tempi e sforzi necessari per configurare e gestire il broker MQTT molto inferiori rispetto a quelli necessari con AWS EC2; inoltre, AWS IoT Core include delle *integrazioni* con servizi come AWS SQS che hanno facilitato molto l'implementazione di alcune funzionalità come la coda asincrona per la gestione dei messaggi in ingresso dai reader RFID;
- *costi*: AWS IoT Core prevede un modello di _pricing on demand_, ovvero pagato in base all'effettivo utilizzo del servizio, che viene misurato in messaggi trasmessi, dispositivi connessi, durata della connessione e altre metriche; basandosi su una stima di utilizzo per l'integrazione in KanbanBOX, sono stati confrontati i costi di AWS EC2 @aws-ec2-pricing e AWS IoT Core @aws-iot-pricing e si è notato come la differenza non giustifichi le complicazioni date dall'utilizzo di AWS EC2; inoltre, in questo caso, il modello di pagamento _on demand_ di EC2 risulta più difficile da gestire e quindi in periodi di utilizzo meno intenso c'è il rischio di pagare più del necessario, rispetto ad AWS IoT Core dove l'adeguamento al carico di lavoro è più flessibile e completamente automatizzato di _default_.

=== Coda per la gestione dei messaggi in ingresso dai reader RFID
Per la gestione dei messaggi in ingresso dai reader RFID, si è deciso di implementare una coda che permettesse di gestire i messaggi in modo più efficiente. In questo modo, i messaggi vengono inseriti in una coda e processati da un _worker_ dedicato, implementato in KanbanBOX, che distribuisce i messaggi ai servizi di KanbanBOX adibiti al consumo dei messaggi.\

In questo caso il confronto iniziale è stato svolto tra l'utilizzo della *coda integrata nel broker MQTT* di AWS IoT Core e l'integrazione di una coda dedicata.\
La prima opzione, però, è stata scartata fin da subito poiché presentava delle limitazioni, infatti la coda integrata da AWS IoT può essere considerata una coda asincrona ma nella pratica non è altro che una _persistent session_, ovvero un meccanismo che permette di mantenere lo stato e i messaggi di un dispositivo anche in caso di disconnessione, ma che presenta le seguenti limitazioni:
- *durata massima della persistenza* dei messaggi in coda limitata ad un'ora;
- *numero massimo di messaggi* in coda limitato a 10 per ogni sottoscrizione ad un topic, con un limite complessivo di 100 messaggi in coda di cui non è stata confermata la ricezione per ogni dispositivo.
Inoltre, in KanbanBOX le code asincrone fornite da AWS erano già state utilizzate in altri domini della piattaforma, quindi il middleware per l'integrazione della coda era quasi interamente disponibile e testato, rendendo l'implementazione di una coda dedicata molto più semplice.

Per questo si è passati al confronto delle code asincrone proposte da AWS, ovvero *AWS SQS*, *AWS SNS* e *AWS MQ*.\
- *AWS SQS* è un servizio di coda asincrona basata sul modello _*pull*_, in cui i messaggi vengono inseriti in una coda e i _consumer_ devono interrogare la coda per ricevere i messaggi; ha dei costi più bassi relativamente alle altre opzioni ed è quella con le capacità di scalabilità più elevate;
- *AWS SNS* è un servizio di messaggistica basato sul modello _*push*_, in cui i messaggi vengono pubblicati su un topic e i _subscriber_ ricevono i messaggi in tempo reale; è più costoso di AWS SQS;
- *AWS MQ* è un servizio di messaggistica basato su Apache ActiveMQ o RabbitMQ; è più costoso e meno scalabile di AWS SQS e AWS SNS, inoltre viene suggerito per scenari in cui è necessario migrare da un'infrastruttura _on-premises_ a una in cloud mantenendo la compatibilità con protocolli di messaggistica standard (come AMQP o MQTT).
Alla luce di queste considerazioni, *AWS SQS* è risultato essere la scelta più adatta per questo progetto, principalmente per il suo modello di funzionamento *_pull_* che si adatta meglio al caso d'uso di KanbanBOX, dove vogliamo che sia il worker da noi implementato a gestire il _polling_ dei messaggi in coda.

=== Stack di sviluppo
Per l'implementazione in PHP del driver di comunicazione MQTT e l'integrazione con i servizi di AWS ci si è affidati a delle librerie _open source_ di PHP e ad alcuni SDK ufficiali di AWS.

In particolare abbiamo *php-mqtt (@php-mqtt)*, una libreria _open source_ che permette di implementare un client MQTT in PHP; include classi, tra cui alcuni _#gloss("DTO", <glossary-dto>)_, e metodi che facilitano l'implementazione delle seguenti funzionalità:
- connessione ad un broker MQTT;
- gestione delle impostazioni di connessione al broker MQTT;
- pubblicazione di un messaggio su un topic MQTT;
- sottoscrizione a un topic MQTT e ricezione dei messaggi pubblicati su quel topic;
- utilizzo di TLS per crittografare la comunicazione tra il client e il broker MQTT;
- meccanismi di QoS e retention dei messaggi MQTT.
Le alternative disponibili sono poche, tra le più rilevanti abbiamo *phpMQTT (@php-MQTT)* e *simps-mqtt (@simps-mqtt)*, che però risultano nettamente inferiori rispetto a php-mqtt; infatti la prima è una libreria non più mantenuta da diversi anni, con un numero di funzionalità molto limitato e una documentazione quasi inesistente, mentre la seconda è una libreria più recente ma ancora acerba, con un numero di funzionalità limitato e una documentazione superficiale.\
Dall'altra parte, invece, php-mqtt è una libreria *mantenuta* con costanza, più *curata* delle altre due, con un numero di funzionalità più ampio e una documentazione più completa, che include anche esempi di utilizzo per le funzionalità più rilevanti.

L'*SDK ufficiale di AWS IoT (@aws-iot-sdk-php)*, nella sua versione per PHP, è stato utilizzato per manipolare tutte le entità di AWS IoT Core, utili per rappresentare i client lato AWS, per gestire i certificati e per l'instradamento dei messaggi.

Mentre l'*SDK ufficiale di AWS SQS (@aws-sqs-sdk-php)*, sempre nella sua versione per PHP, è stato utilizzato per interagire con il servizio di coda asincrona di AWS, in particolare per leggere i messaggi dalla coda.

Nel caso degli SDK di AWS l'unica alternativa plausibile sarebbe stata quella di utilizzare la _#gloss("CLI", <glossary-cli>)_ di AWS, lanciando i comandi tramite PHP, ma è stata scartata fin da subito in quanto non presenta alcun vantaggio rispetto all'utilizzo degli SDK ufficiali e, anzi, avrebbe reso l'implementazione molto più ostica.

== Stack tecnologico preesistente
In questa sezione vengono elencati e descritti gli strumenti e le tecnologie già utilizzati in azienda e che sono stati sfruttati durante l'implementazione esposta in questo documento.

=== Librerie e framework PHP
*Framework e Core:*
- *CodeIgniter*: framework MVC utilizzato come architettura di base nel codice legacy di KanbanBOX, che è ancora in fase di migrazione verso un'architettura più moderna basata su Symfony;
- *Symfony*: framework PHP moderno verso cui si sta migrando in KanbanBOX; fornisce un'architettura modulare e _component-based_, con un ecosistema ricco di librerie che facilitano lo sviluppo di applicazioni web complesse e scalabili;
- *Doctrine*: è un Object-Relational Mapper (ORM), ovvero una libreria che permette di mappare le entità del dominio di KanbanBOX a tabelle di un database relazionale, facilitando la gestione della persistenza dei dati e l'astrazione del database;
- *Twig*: _template engine_ performante e flessibile utilizzato per la generazione di interfacce web dinamiche; permette di definire dei template HTML con una sintassi specifica e più intuitiva, i template vengono poi utilizzati nella logica di generazione delle pagine web di KanbanBOX. 

*Standard e Utility:*
- *Composer*: gestore di dipendenze standard de facto per PHP, utilizzato per l'installazione, aggiornamento e integrazione di librerie esterne e per la gestione dell'_autoloading_ delle classi;
- *Guzzle*: client HTTP utilizzato per l'interazione con servizi web esterni e API RESTful; in KanbanBOX viene utilizzato anche per gestire richieste tra endpoint interni diversi, ad esempio per il download dei certificati dei reader;
- *Psr (PHP Standard Recommendations)*: libreria che definisce una serie di standard e mette a disposizione interfacce per garantire l'interoperabilità tra le librerie e i framework PHP, facilitando l'integrazione di componenti di terze parti e promuovendo un'architettura modulare e scalabile;
- *Psl (PHP Standard Library)*: libreria standard che aiuta ad imporre un approccio fortemente tipizzato e orientato agli oggetti nello sviluppo di applicazioni PHP;
- *ramsey/UUID*: libreria per la generazione di UUID (Universally Unique Identifier), utilizzata per creare identificatori univoci per le entità del dominio di KanbanBOX, come ad esempio i reader RFID o i tag RFID letti;
- *i18next*: libreria per la gestione dell'internazionalizzazione (i18n), utilizzata per supportare più lingue nell'interfaccia di KanbanBOX.

*Testing e Qualità:*
- *PHPUnit*: framework principale per l'esecuzione di _unit test_, ovvero che permette di testare l'unità di codice minima nel progetto, fondamentale per validare la _business logic_;
- *Playwright*: tool di automazione per il testing _end-to-end_, utilizzato per simulare le interazioni dell'utente nel browser e verificare che il risultato sia quello previsto in fase di progettazione;
- *Infection*: strumento di _mutation testing_ che verifica la robustezza dei test implementati, introducendo modifiche al codice sorgente originale.

=== Altre tecnologie
- *MySQL*: database relazionale utilizzato per la persistenza dei dati in KanbanBOX;
- *Make*: utility di automazione utile per gestire l'intero ciclo di vita del software, dalla fase di sviluppo a quella di testing e deployment, semplificando l'esecuzione di comandi complessi e ripetitivi che vengono raggruppati e mappati in comandi più semplici tramite un file di configurazione detto Makefile;
- *AWS IAM*: servizio di gestione degli accessi di Amazon Web Services, utilizzato per configurare i ruoli e i relativi permessi di accesso alle varie funzionalità di AWS da parte dei servizi e degli sviluppatori di KanbanBOX; 
- *Reader Zebra*: dispositivi hardware prodotti dal Zebra Technologies; nel caso di questo progetto si ha interagito principalmente con i reader RFID della serie FX7500 e FX9600 ma in KanbanBOX sono ampiamente utilizzati anche dispositivi come barcode scanner e stampanti di etichette.\ Nello specifico i reader hanno il compito di leggere i tag RFID in prossimita, tramite delle antenne esterne, e di trasmettere i dati dei tag letti agli endpoint configurati.