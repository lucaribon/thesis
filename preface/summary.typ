#import "../config/constants.typ": abstract
#import "../config/variables.typ": myName, myTitle, myCompany
#set page(numbering: "i")
#counter(page).update(1)

#v(10em)

#text(24pt, weight: "semibold", abstract)

#set par(first-line-indent: 0pt)
Il presente documento descrive il lavoro svolto durante il periodo di stage, della durata di circa 320 ore, dal laureando #text(myName) presso l'azienda #text(myCompany)

L'obbiettivo finale dello stage è stato quello di sostituire il protocollo HTTP, utilizzato dalla piattaforma KanbanBOX per comunicare con i reader RFID, con MQTT, un protocollo più adatto ad essere utilizzato con dispositivi IoT. \
In particolare è stata progetta un'architettura capace di integrare i seguenti componenti:
- *reader RFID*, dispositivi hardware che leggono i tag RFID applicati sui prodotti
- *AWS IoT Core*, un servizio cloud che integra un broker capace di gestire la comunicazione tra molteplici dispositivi tramite MQTT
- *AWS SQS*, un servizio cloud che fornisce delle code di messaggi per la comunicazione asincrona tra servizi, particolarmente adatto a gestire la lettura dei tag tramite meccanismo publish/subscribe di MQTT
- *KanbanBOX*, la piattaforma web che necessita di ricevere i dati letti dai reader RFID per monitorare e supportare l'intero processo produttivo e logistico di un'azienda

A tal fine, alla fase di progettazione è seguita la codifica delle funzionalità necessarie in KanbanBOX per l'integrazione con i servizi AWS IoT Core e SQS, insieme all'implementazione del protocollo MQTT per la comunicazione con i reader.


#v(1fr)