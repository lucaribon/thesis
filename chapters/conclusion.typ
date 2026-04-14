#pagebreak(to:"odd")

<cap:conclusioni>

= Conclusioni

== Consuntivo finale
<cap:consuntivo-finale>
Lo stage si è svolto in un periodo di circa 2 mesi, per un totale di \~316 ore di lavoro. Il progetto è stato portato a termine con successo; come mostrato in @cap:requisiti, tutti gli obbiettivi prefissati sono stati raggiunti, ad eccezione dei requisti:
- *R-01-Q-O*: test e validazione funzionale del driver sviluppato, raggiunto *parzialmente* data la mancanza di tempo per esplorare, partendo quasi da zero, lo stack necessario all'implementazione di test di integrazione più complessi, che avrebbero dovuto interagire con sistemi esterni su cui si ha un controllo ridotto come AWS IoT e i reader RFID.
- *R-02-Q-D*: implementazione di meccanismi atti a garantire la sicurezza della comunicazione, raggiunto *parzialmente* in quanto per questioni di tempo non è stato possibile implementare dei meccanismi di _logging_ completamente esaustivi.

Il programma settimanale definito nel "Piano di Lavoro" è stato seguito in maniera abbastanza fedele, con alcune variazioni relative principalmente ai tempi necessari per lo svolgimento delle attività, che nel complesso si sono compensate, portando il numero di ore totali ad essere in linea con quanto previsto.

== Conoscenze acquisite
Un punto forte di questo progetto di stage è stata l'*ampiezza* dei concetti approfonditi e delle tecnologie utilizzate, che mi ha permesso di sperimentare con nuovi strumenti o di consolidare conoscenze già acquisite precedentemente. Infatti ho avuto modo di operare nei seguenti ambiti:
- *infrastruttura cloud*, in particolare AWS, con servizi come AWS IoT Core, AWS SQS e AWS IAM;
- *dispositivi e ambienti IoT*, in particolare i reader RFID, con cui è spesso difficile avere un contatto diretto e pratico quando si lavora in ambiti accademici o personali;
- *protocolli di comunicazione*, in particolare MQTT, con cui non avevo avuto modo di lavorare prima;
- *strumenti di sviluppo*, come PHPStorm, Docker, Github e i vari framework di testing e supporto allo sviluppo, strumenti con cui avevo già avuto modo di lavorare, ma su cui ora ho maggiore padronanza;
- *sviluppo in PHP*, linguaggio che avevo già utilizzato in diverse occasioni ma che, assieme all'utilizzo di librerie e metodologie di sviluppo più avanzate, mi ha permesso di conoscere meglio le dinamiche di progetti a livello _enterprise_.

== Sviluppi futuri
=== Rotazione certificati
Un aspetto importante da considerare per avere una piattaforma manutenibile e allo stesso tempo sicura è la *rotazione dei certificati*, ovvero la possibilità di sostituire arbitrariamente i certificati utilizzati per l'autenticazione e la cifratura della comunicazione. \
Attualmente, i certificati utilizzati dai reader RFID vengono generati e configurati automaticamente da KanbanBOX, richiedendo poi l'intervento manuale dell'utente per l'upload del certificato sul reader stesso tramite l'interfaccia web fornita dal produttore. Inoltre i certificati generati sono scaricabili solamente una volta tramite interfaccia di KanbanBOX, e non è possibile rigenerarli o recuperarli in caso di smarrimento.

L'implementazione ideale prevederebbe la possibilità di *rigenerare i certificati su AWS tramite KanbanBOX*, con la conseguente *gestione* dello storico dei certificati *eseguita* direttamente *dal sistema*, senza che l'utente debba preoccuparsi di gestirli manualmente, se non per caricarli sui reader RFID.
In questo modo, in caso di smarrimento o compromissione dei certificati, sarebbe possibile rigenerarli in maniera semplice e veloce, senza dover ricreare i reader su KanbanBOX o dover operare manualmente nella console di AWS IoT.


=== Configurazione di un dominio custom per il broker MQTT
Attualmente il dominio dell'endpoint utilizzato per connettersi al broker MQTT di AWS IoT Core è quello di default fornito da AWS, che è un dominio generico che non riconduce in alcun modo a KanbanBOX. \

Per questioni di *eleganza e di fiducia da parte dei clienti* sarebbe utile poter utilizzare un *sotto-dominio custom* del dominio di KanbanBOX già esistente, come ad esempio `iot.kanbanbox.com`, che riconduca direttamente al broker MQTT di AWS IoT Core. \

=== Approfondimento della configurazione della coda SQS
Attualmente la coda SQS utilizzata per il trasferimento dei tag letti e degli heartbeat è configurata in modo abbastanza semplice e standard. Approfondire i concetti riguardanti i parametri di configurazione della coda potrebbe essere utile per *migliorare prestazioni e affidabilità* di tutto il sistema.

=== Test di integrazione
Come accennato in @cap:requisiti e in @cap:consuntivo-finale, non è stato possibile implementare dei *test di integrazione* più complessi che avrebbero dovuto interagire con *sistemi esterni* come AWS IoT e i reader RFID. \
In accordo con il tutor interno si è deciso di considerare comunque il progetto come completo considerando il livello di complessità che avrebbero aggiunto queste implementazioni. Inoltre ci si può comunque affidare a dei test di unità abbastanza esaustivi e al fatto che i servizi esterni utilizzati sono strumenti professionali testati e con un buon livello di affidabilità. 

Nonostante sui servizi esterni si abbia anche un controllo ridotto, sarebbe comunque una buona pratica implementare dei test di integrazione che interagiscano con essi, in modo da poter *verificare* che la *gestione di errori o comportamenti anomali*, seppur rari, funzioni correttamente. \

== Considerazioni finali
Dal punto di vista personale credo che questo progetto mi abbia permesso di crescere molto come professionista del settore. \
Ho avuto modo di affrontare concetti e sfide reali in un ambiente che mi ha fornito tutti gli strumenti e il supporto per operare al meglio, e mi ha permesso di avere un riscontro diretto sia vedendo il prodotto crescere anche grazie al mio contributo, sia interfacciandomi con i colleghi e con il tutor interno.

Penso che avere modo di lavorare su un progetto reale, con tecnologie che rappresentano uno standard del settore, compreso l'hardware a cui è difficile avere accesso se non in specifici contesti aziendali, sia un'opportunità preziosa e da non dare per scontata per chiunque voglia intraprendere una carriera in questo ambito. \  