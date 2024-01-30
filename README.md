# Parser URI

**READ HERE PLEASE** 👇

This is a project I worked on during my university studies and it's not maintained anymore. As you can see the code seems to be written by a script kiddie (I was young and with no experience) so just give it a quick read and don't take it as a serious working software. 😁

P.S. Don't contact me in private asking me for suggestions: this is a code I wrote more than 10 years ago and I really don't have any idea on how it works! 😅

---

Il programma, tramite la funzione principale **parse-uri**, prede in ingresso una stringa e la converte in una lista di caratteri su cui poi lavoreranno le diverse funzioni scritte.

Ogni uri, è rappresentato nell'interprete tramite una defstruct chiamata url onde evitare incompatibilità con la variabile locale uri.
Il progetto fa uso di tre parametri globali:

- **next**: la lista contenente i caratteri ancora da trattare;
- **scheme** a cui è associato lo scheme (necessaria per la scheme-syntax);
- **flag** che determina il tipo di uri e modifica il flusso di esecuzione di alcune funzioni. Se lo uri presenta lo user authority, il flag sarà settato ad uno, se invece dopo lo scheme c'è un solo slash (/) verrà settato a due, altrimenti se non vi è alcuno slash dopo lo scheme è settato a 3.

Le funzioni principale del programma sono denominate come segue:

- **create-uri-PART** dove part rappresenta la parte di uri da trattare. Ad esempio create-uri-scheme estrae lo scheme, crea-uri-host estrae l'host etc. Tutte queste funzioni hanno in ingresso tre parametri:
  - _uri_: variabile contenente la lista da trattare;
  - _lista_: lista della parte di uri già trattata;
  - _counter_: serve a determinare se la funzione è già stata eseguita una volta o no. Molto utile nel caso di funzioni ricorsive in quanto modificano il flusso di esecuzione ad ogni chiamata.

Quando una delle funzioni di cui sopra ha finito di lavorare su un determinato campo, setta _next_ con (cdr uri) che rappresenta la parte di lista ancora da trattare.

Tutti i campi della DEFSTRUCT, sono settati con i valori di ritorno delle funzioni descritte sopra.
Ad esempio **:host** (create-uri-host next (list) 0) setta il campo host con il valore di ritorno della funzione; se la funzione ritorna NIL il campo sarà NIL, altrimenti assumerà il valore di lista.
Ogni qualvolta un campo viene settato, viene eseguita sul campo successivo la relativa funzione fino a che la lista rappresentate la uri non è NIL.
