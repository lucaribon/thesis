#import "../config/constants.typ": abstract
#import "../config/variables.typ": myName, myTitle, myCompany
#import "../config/thesis-config.typ": gloss

#set page(numbering: none)
#pagebreak(to:"odd")
#set page(numbering: "i")
#counter(page).update(1)

#v(10em)

#text(24pt, weight: "semibold", abstract)

#set par(first-line-indent: 0pt)
Il presente documento descrive il lavoro svolto durante il periodo di stage, della durata di circa 320 ore, dal laureando #text(myName) presso l'azienda #text(myCompany)

L'obbiettivo finale dello stage è stato quello di sostituire il protocollo #gloss("HTTP", <glossary-HTTP>), utilizzato dalla piattaforma KanbanBOX per comunicare con i lettori #gloss("RFID", <glossary-RFID>), con #gloss("MQTT", <glossary-MQTT>), un protocollo più adatto ad essere utilizzato con dispositivi _IoT_. \
In particolare è stata progetta un'architettura capace di integrare i seguenti componenti:
- *lettore RFID*, dispositivi hardware che leggono i tag RFID applicati sui prodotti;
- *AWS IoT Core*, un servizio _cloud_ che integra un #gloss("broker", <glossary-broker>) capace di gestire la comunicazione tra molteplici dispositivi tramite MQTT;
- *AWS SQS*, un servizio _cloud_ che fornisce delle code di messaggi per la comunicazione asincrona tra servizi, particolarmente adatto a gestire la lettura dei tag tramite meccanismo _publish/subscribe_ di MQTT;
- *KanbanBOX*, la piattaforma _web_ che necessita di ricevere i dati letti dai lettori RFID per monitorare e supportare l'intero processo produttivo e logistico di un'azienda.

A tal fine, alla fase di progettazione è seguita la codifica delle funzionalità necessarie in KanbanBOX per l'integrazione con i servizi AWS IoT Core e SQS, che saranno di supporto per l'implementazione della comunicazione con i lettori tramite protocollo MQTT.

#v(1fr)