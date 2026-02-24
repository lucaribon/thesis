#pagebreak(to: "odd")

#set page(numbering: "1")
#set align(left)
#set heading(numbering: none)
#show heading: it => block(above: 1.4em, below: 1em, text(it.body))

= Glossario
<glossary>

//GLOSSARIO


== A
=== API
<glossary-api>
Application Programming Interface, è un insieme di regole e protocolli che consentono a diverse applicazioni software di comunicare tra loro.\
Le API definiscono i metodi e i formati per trasmettere richieste e risposte tra componenti software o hardware, facilitando la comunicazione tra sistemi diversi.\

== B
=== Backend
<glossary-backend>
Il backend è la parte di un sistema software che gestisce la logica di funzionamento del sistema, l'elaborazione dei dati e l'interazione con il database o altri servizi. Non include, invece, l'interfaccia con cui l'utente finale interagisce o la parte visibile del sistema, che è chiamata frontend. 

Nel caso di KanbanBox il backend viene eseguito su una macchina server, ovvero un dispositivo diverso e fisicamente distante dalla macchina usata dall'utente finale per interagire con il sistema.\

=== Backup
<glossary-backup>
Il backup è una copia esatta di dati, in un formato qualsiasi (compatibile con il formato dei dati originari), che viene creata per proteggere le informazioni in caso di perdita, danneggiamento o malfunzionamento del sistema originale.\

=== Broker
<glossary-broker>
Un broker è un componente software che funge da intermediario nella comunicazione tra dispositivi in un'architettura publish/subscribe, come quella utilizzata dal protocollo MQTT.\

== C

== D

== E

== F

== G

== H
=== HTTP
<glossary-HTTP>
Hypertext Transport Protocol, è un protocollo di comunicazione basato su architettura client-server, utilizzato principalmente per la trasmissione di dati sul web.\
È il protocollo che è stato utilizzato fin dall'inizio in KanbanBOX per la comunicazione tra i lettori RFID e la piattaforma stessa.

== I
=== IDE
<glossary-ide>

== J
=== JSON
<glossary-json>
JavaScript Object Notation, è un formato di file testuali utilizzato per l'archiviazione e lo scambio di dati, tramite sistemi informatici, che rimane comunque leggibile anche da esseri umani.\

== K
=== Kanban
<glossary-kanban>
Kanban è un sistema di gestione della produzione e del flusso di lavoro che utilizza schede visive (chiamate "kanban") per rappresentare le attività, i materiali o i prodotti in un processo produttivo.\

== L
=== Lean
<glossary-lean>
Lean è una metodologia di gestione della produzione e dei processi aziendali che mira a massimizzare il valore per il cliente riducendo gli sprechi e migliorando l'efficienza.\
Originariamente sviluppata nel settore manifatturiero, la filosofia Lean si basa su principi come il miglioramento continuo, il rispetto per le persone e l'ottimizzazione del flusso di lavoro.\

== M
=== MQTT
<glossary-MQTT>
Message Queuing Telemetry Transport, è un protocollo di messaggistica basata su un architettura publish/subscribe, progettato per essere leggero ed efficiente, particolarmente adatto per dispositivi con risorse limitate e reti con larghezza di banda ridotta.\

== N

== O

== P

== Q
=== Quality of Service
<glossary-qos>
Per il protocollo MQTT il Quality of Service definisce con che garanzia verranno consegnati i messaggi ai dispositivi "destinatari" per un certo topic. Esistono tre livelli di Quality of Service: 0 (al massimo una consegna), 1 (almeno una consegna) e 2 (esattamente una consegna).\

== R
=== RFID
<glossary-RFID>
Radio-Frequency Identification, è una tecnologia di identificazione che utilizza onde radio per trasmettere dati tra un lettore e un dispositivo chiamato "tag" o "etichetta" RFID.\

== S

== T
=== Topic
<glossary-topic>
In MQTT, un topic è un canale di comunicazione dove i dispositivi MQTT possono pubblicare messaggi su un specifico topic; tutti i dispositivi iscritti ad un topic riceveranno i messaggi pubblicati in esso.\
Ogni topic consiste in una stringa che può essere suddivisa in livelli utilizzando il carattere "/" come separatore, consentendo di organizzare i messaggi in una struttura gerarchica.\

== U
=== UML
<glossary-uml>
Unified Modeling Language, è un linguaggio di modellazione standardizzato utilizzato per visualizzare e documentare i componenti di un sistema software.\

== V

== W

== X

== Y

== Z
