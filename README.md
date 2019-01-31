# Parser URI

Il programma, tramite la funzione principale **parse-uri**, prede in ingresso una stringa e la converte in una lista di caratteri su cui poi lavoreranno le diverse funzioni scritte.

Ogni uri, è rappresentato nell'interprete tramite una defstruct chiamata url onde evitare incompatibilità con la variabile locale uri.
Il progetto fa uso di tre parametri globali:
- **next**: la lista contenente i caratteri ancora da trattare;
- **scheme** a cui è associato lo scheme (necessaria per la scheme-syntax);
- **flag** che determina il tipo di uri e modifica il flusso di esecuzione di alcune funzioni. Se lo uri presenta lo user authority, il flag sarà settato ad uno, se invece dopo lo scheme c'è un solo slash (/) verrà settato a due, altrimenti se non vi è alcuno slash dopo lo scheme è settato a 3.

Le funzioni principale del programma sono denominate come segue:
- **create-uri-PART** dove part rappresenta la parte di uri da trattare. Ad esempio create-uri-scheme estrae lo scheme, crea-uri-host estrae l'host etc. Tutte queste funzioni hanno in ingresso tre parametri:
  - *uri*: variabile contenente la lista da trattare;
  - *lista*: lista della parte di uri già trattata;
  - *counter*: serve a determinare se la funzione è già stata eseguita una volta o no. Molto utile nel caso di funzioni ricorsive in quanto modificano il flusso di esecuzione ad ogni chiamata.

Quando una delle funzioni di cui sopra ha finito di lavorare su un determinato campo, setta *next* con (cdr uri) che rappresenta la parte di lista ancora da trattare.

Tutti i campi della DEFSTRUCT, sono settati con i valori di ritorno delle funzioni descritte sopra.
Ad esempio **:host** (create-uri-host next (list) 0) setta il campo host con il valore di ritorno della funzione; se la funzione ritorna NIL il campo sarà NIL, altrimenti assumerà il valore di lista.
Ogni qualvolta un campo viene settato, viene eseguita sul campo successivo la relativa funzione fino a che la lista rappresentate la uri non è NIL.