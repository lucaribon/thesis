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
// TODO: tabella per rappresentare header di pacchetti HTTP vs payload di letture RFID, per evidenziare l'overhead???
- *overhead elevato*: ogni richiesta HTTP include un _header_ di dimensioni considerevoli rispetto al _payload_ effettivo; in scenari come questo dove i lettori RFID devono inviare frequentemente piccoli pacchetti di dati, l'aumento di overhead su grandi quantità di messaggi inizia a diventare significativo;
- *assenza di comunicazione bidirezionale nativa*: HTTP non prevede un meccanismo nativo per cui il server possa inviare messaggi al client senza che quest'ultimo li richieda esplicitamente, rendendo complessa l'implementazione di operazioni come la configurazione remota dei lettori RFID;
- *nessuna garanzia di consegna*: HTTP non offre meccanismi integrati di _Quality of Service_ per garantire la consegna dei messaggi in caso di disconnessioni temporanee, il che è fondamentale in un contesto dove l'affidabilità dell'intero sistema è cruciale.

Queste limitazioni hanno motivato la migrazione a MQTT come protocollo per la comunicazione tra i lettori RFID e KanbanBOX.

// TODO: forse mqtt capitolo a parte?
=== MQTT

=== Coda di messaggi


== Strumenti scelti
// sulla base di quali criteri, eccetera...
=== Hosting del broker MQTT

=== Coda as