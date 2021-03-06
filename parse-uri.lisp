;;;   parse-uri.lisp   ;;;
;;;   Valutazione: 25/30   ;;;

(defparameter next (list))
(defparameter scheme ())
(defparameter flag ())

(defstruct url scheme userinfo host port path query fragment) 

; Questa funzione effettua i vari controlli sulle funzioni. 
; Principalmente controlla la validità dei caratteri nei vari campi
; Alcuni caratteri sono controllati direttamente nelle funzioni
(defun not-valid-uri (lista campo)
  (if (not (null lista))
      (cond
       ((string= campo "scheme")
        (if (or (and (string= (first lista) ":") (string= (second lista) "/")
                     (string= (third lista) "/") (string= (fourth lista) "/"))
                (and (string= (first lista) ":") (string= (second lista) ":")))
            (error "Scheme non valido!")
          (not-valid-uri (cdr lista) campo)))
       ((string= campo "userinfo")
        (if (or (string= (first lista) "@") (string= (first lista) ":")
                (string= (first lista) "?") (string= (first lista) "#")
                (string= (first lista) "/"))
            (error "Userinfo non valido!")
          (not-valid-uri (cdr lista) campo)))
       ((string= campo "host")
        (if (or (and (string= (first lista) ".") (string= (second lista) "."))
                (string= (first lista) "?") (string= (first lista) "#") 
                (string= (first lista) "@")(string= (first lista) ":"))
            (error "Host invalido!")
          (not-valid-uri (cdr lista) campo)))
       ((string= campo "port")
        (if (string= (first lista) " ")
            (error "Porta non valida!")
          (not-valid-uri (cdr lista) campo)))
       ((string= campo "path")
        (if (or (string= (first lista) "?") (string= (first lista) "#")
                (string= (first lista) "@") (string= (first lista) ":"))
            (error "Path invalido!")
          (not-valid-uri (cdr lista) campo)))
       )
    )
  )

; Questa è la funzione che si preoccupa di creare lo scheme.
; Se la variabile uri è NIL, ritorna errore.
(defun create-uri-scheme (uri lista)
  (if (not (null uri))
      (cond
	((or (string= (first uri) "?") (string= (first uri) "#")
	     (string= (first uri) "/") (string= (first uri) "@"))
	 (error "Scheme non valido!"))
	((and (string= (first uri) ":") (null (cdr uri)))
	 (error "Lo scheme non è opzionale!"))
	((and (string= (first uri) ":")
	      (string= (second uri) "/") (string= (third uri) "/"))
	 (not-valid-uri uri "scheme")
	 (setq next (append (cdr uri) nil))
	 (setq flag 1)
	 (coerce lista 'string))
	((and (string= (first uri) ":") 
	      (string= (second uri) "/") (not (string= (third uri) "/")))
	 (not-valid-uri uri "scheme")
	 (setq next (append (cdr uri) nil))
	 (setq flag 2)
	 (coerce lista 'string))
	((and (string= (first uri) ":") 
	      (not (string= (second uri) "/")) (not (string= (third uri) "/")))
	 (not-valid-uri uri "scheme")
	 (setq next (append (cdr uri) nil))
	 (setq flag 3)
	 (coerce lista 'string))
	((not(string= (first uri) ":"))
	 (setq lista (append lista (cons (first uri) nil)))
	 (create-uri-scheme (cdr uri) lista))
	)
      (error "Inserire uno URI valido!")
      )
  )

; Questa funzione determina l'esistenza del carattere @ nella lista.
; Se esiste ritorna T altrimenti NIL
(defun find-at (uri)
  (if (not (null uri))
      (cond
	((string= (first uri) "@")
	 T)
	((not (string= (first uri) "@"))
	 (find-at (cdr uri)))
	)
      NIL
      )
  )

; Questa funzione determina l'userinfo nel caso particolare
; in cui lo scheme sia tel oppure fax
(defun userinfo-tel-fax (uri lista counter)
  (if (and (null uri) (= counter 0))
      (error "Inserire uno userinfo valido!"))
  (if (or (string= scheme "tel") (string= scheme "fax"))
      (cond
	((not (null uri))
	 (setq lista (append lista (cons (first uri) nil)))
	 (userinfo-tel-fax (cdr uri) lista 1))
	((and (null uri) (= counter 1))
	 (not-valid-uri lista "userinfo")
	 (setq next NIL)
	 (coerce lista 'string))
	)
      )
  )

; Questa funzione determina l'userinfo nel caso particolare
; in cui lo scheme sia mailto
(defun userinfo-mailto (uri lista counter)
  (if (and (null uri) (= counter 0))
      (error "Userinfo in questo caso non e' opzionale!"))
  (if (find-at uri)
      (cond
	((not (string= (first uri) "@"))
	 (setq lista (append lista (cons (first uri) nil)))
	 (userinfo-mailto (cdr uri) lista 1))
	((and (string= (first uri) "@") (not (null (cdr uri))))
	 (not-valid-uri lista "userinfo")
	 (setq next (append (cdr uri) NIL))
	 (coerce lista 'string))
	((and (string= (first uri) "@") (null (cdr uri)))
	 (error "UserInfo non valido!"))
	)
      (cond
	((null uri)
	 (not-valid-uri lista "userinfo")
	 (setq next NIL)
	 (coerce lista 'string))
	((not (null uri))
	 (setq lista (append lista (cons (first uri) nil)))
	 (userinfo-mailto (cdr uri) lista 1))
	)
      )
  )

; Questa funzione determina l'userinfo.
; Il suo comportamento e' fortemente condizionato
; dal tipo di scheme dell'URI
(defun create-uri-userinfo (uri lista counter)
  (if (or (string= scheme "news") (string= scheme "mailto") 
	  (string= scheme "tel") (string= scheme "fax"))
      (cond
	((string= scheme "news")
	 (setq next (append uri NIL))
	 NIL)
	((string= scheme "mailto")
	 (userinfo-mailto uri lista 0))
	((or (string= scheme "tel") (string= scheme "fax"))
	 (userinfo-tel-fax uri lista 0))
	)
      (cond
	((and (find-at uri) (= counter 0) 
	      (string= (first uri) "/") (string= (second uri) "/")
	      (string= (third uri) "@"))
	 (error "Userinfo non valido!"))
	((and (find-at uri) (= counter 0) 
	      (string= (first uri) "/") (string= (second uri) "/"))
	 (create-uri-userinfo (cdr (cdr uri)) lista 1))
	((and (find-at uri) (= counter 1)(not (string= (first uri) "@")))
	 (setq lista (append lista (cons (car uri) nil)))
	 (create-uri-userinfo (cdr uri) lista 1))
	((and (not (find-at uri)) (= counter 0))
	 NIL)
	((and (= counter 1)(string= (first uri) "@"))
	 (setq next (append (cdr uri) NIL))
	 (not-valid-uri lista "userinfo")
	 (coerce lista 'string))
	)
      )
  )

; Viene chiamata SOLO quando lo scheme è news
(defun create-uri-host-news (uri lista counter)
  (if (and (null uri) (= counter 0))
      (error "Host obbligatorio!")
      (cond
	((null (cdr uri))
	 (if (string= (first uri) "/")
	     (error "Host invalido!"))
	 (setq lista (append lista (cons (first uri) nil)))
	 (not-valid-uri lista "host")
	 (setq next nil)
	 (coerce lista 'string))
	((not (null uri))
	 (if (string= (first uri) "/")
	     (error "Host invalido!"))
	 (setq lista (append lista (cons (first uri) nil)))
	 (create-uri-host-news (cdr uri) lista 1))
	)
      )
  )

; Viene chiamata SOLO quando lo scheme non è news
(defun create-uri-host-normal (uri lista counter)
  (if (and (not (null uri)) (not (string= scheme "news")))
      (cond
	((and (string= (first uri) "/") (string= (second uri) "/")
	      (or (string= (third uri) "?") (string= (third uri) "#")
		  (string= (third uri) ".")) (= counter 0))
	 (error "Host non valido!"))
	((and (string= (first uri) "/") (string= (second uri) "/")
	      (null (cdr (cdr uri))) (= counter 0) 
	      (not (string= scheme "news")))
	 (error "L' Host non e' opzionale!"))
	((and (string= (first uri) "/") (string= (second uri) "/")
	      (= counter 0) (not (string= scheme "news")))
	 (if (null (cdr (cdr uri)))
	     (setq next NIL))
	 (create-uri-host-normal (cdr (cdr uri)) lista 1))
	((and (string= (first uri) "/") (string= (second uri) "/") 
	      (= counter 1))
	 (error "URI non valido"))
	((and (string= (first uri) ".") (= counter 0))
	 (error "URI non valido"))
	((and (string= (first uri) ".")
	      (or (null (cdr uri)) (string= (second uri) "/") 
		  (string= (second uri) "?") (string= (second uri) "#") 
		  (string= (second uri) "@") (string= (second uri) ":")))
	 (error  "Host invalido!"))
	((and (string= (first uri) "/") (string= (second uri) "/") 
	      (= counter 1))
	 (error "URI non valido"))
	((and (string= (first uri) ".") (= counter 0))
	 (error "URI non valido"))
	((and (string= (first uri) ".")
	      (or (null (cdr uri)) (string= (second uri) "/") 
		  (string= (second uri) "?") (string= (second uri) "#") 
		  (string= (second uri) "@") (string= (second uri) ":")))
	 (error  "Host invalido!"))   
	((and (string= (first uri) "/") (not (string= (second uri) "/"))
	      (= counter 0) (= flag 2))	     
	 (setq next (append uri nil))
	 NIL)
	((and (not (string= (first uri) "/")) (= counter 0) 
	      (or (string= scheme "mailto") (= flag 1)))
	 (create-uri-host-normal uri lista 1))
	((and (not (string= (first uri) "/")) (= counter 0) (= flag 3))
	 (setq next (append uri nil))
	 NIL)
	((and (= flag 3) (= counter 0))
	 (create-uri-host-normal uri lista 1))
	((and (not (string= (first uri) "/")) 
	      (not (string= (second uri) "/")) (= counter 0))
	 (setq next (append uri NIL))
	 NIL)
	((and (not (string= (first uri) "/")) (null (cdr uri)))
	 (setq lista (append lista (cons (first uri) nil)))
	 (not-valid-uri lista "host")
	 (setq next nil)
	 (coerce lista 'string))
	((string= (first uri) "?")
	 (not-valid-uri lista "host")
	 (setq next (append uri nil))
	 (coerce lista 'string))
	((string= (first uri) "#")
	 (not-valid-uri lista "host")
	 (setq next (append uri nil))
	 (coerce lista 'string))
	((string= (first uri) ":")
	 (not-valid-uri lista "host")
	 (setq next (append uri nil))
	 (coerce lista 'string))
	((not (string= (first uri) "/"))
	 (setq lista (append lista (cons (first uri) nil)))
	 (create-uri-host-normal (cdr uri) lista 1))
	((and (string= (first uri) "/") (not (= flag 3)))
	 (not-valid-uri lista "host")
	 (setq next (append uri nil))
	 (coerce lista 'string))
	)
      NIL
      )
  )

; Questa funzione estrae l'host dalla stringa
(defun create-uri-host (uri)
  (if (string= scheme "news")
      (create-uri-host-news uri nil 0)
; else
      (create-uri-host-normal uri nil 0)
      )
  )

; Questa funzione determina la porta. E' stata utilizzata 
; la funzione (> (parse-integer (coerce lista 'string)) -1)
; per determinare in primo luogo se i caratteri sono
; convertibili in un numero intero e in secondo luogo
; controlla che il valore della porta sia > 0
(defun create-uri-port (uri lista counter)
  (if (not (null uri))
      (cond
	((and (or (string= scheme "mailto") (string= scheme "news"))
	      (not (null uri)))
	 (error "URI non valido!"))
	((and (string= (first uri) ":") (string= (second uri) "/"))
	 (error "Porta non valida!"))
	((string= (first uri) ":") 
	 (create-uri-port (cdr uri) lista 1))
	((and (or (string= (first uri) "?") (string= (first uri) "#")) 
	      (= counter 0))
	 (setq next (append uri nil))
	 NIL)
	((and (not (string= (first uri) ":")) (= counter 0))
	 (setq next (append uri nil))
	 NIL)
	((and (string= (first uri) "/") (null (cdr uri)) (= counter 1))
	 (setq next NIL)
	 NIL)
	((and (null (cdr uri)) (= counter 1))
	 (setq lista (append lista (cons (first uri) nil)))
	 (not-valid-uri lista "port")
	 (setq next NIL)
	 (if (> (parse-integer (coerce lista 'string)) 0)
	     (coerce lista 'string)
	     (error "Porta non valida!")))	
	((and (or (string= (first uri) "/")
		  (string= (first uri) "?") (string= (first uri) "#")) 
	      (= counter 1))
	 (not-valid-uri lista "port")
	 (setq next (append uri nil))
	 (if (> (parse-integer (coerce lista 'string)) 0)
	     (coerce lista 'string)
	     (error "Porta non valida!")))
	((not (string= (first uri) "/"))
	 (setq lista (append lista (cons (first uri) nil)))
	 (create-uri-port (cdr uri) lista 1))
	)
      NIL
      )
  )

; Questa funzione estrae il path. 
; Il primo / funge da delimitatore.
(defun create-uri-path (uri lista counter)
  (if (not (null uri))
      (if (not (string= scheme "news"))
	  (cond 
	    ((and (string= (first uri) "/") (string= (second uri) "/") 
		  (= counter 1))
	     (error "URI non valido!"))
	    ((and (string= (first uri) "/") 
		  (or (string= (second uri) "?") (string= (second uri) "#"))
		  (= counter 0))
	     (setq next (append (cdr uri) NIL))
	     NIL)
	    ((and (string= (first uri) "/") (not (string= (second uri) "/"))
		  (not (null (cdr uri))) (= counter 0))
	     (create-uri-path (cdr uri) lista 1))
	    ((and (= flag 3) (= counter 0) (string= scheme "mailto"))
	     (error "URI non valido!"))
	    ((and (or (string= (first uri) "?") (string= (first uri) "#"))
		  (= counter 0))
	     (setq next (append uri NIL))
	     NIL)
	    ((and (= flag 3) (= counter 0))
	     (setq lista (append lista (cons (first uri) nil)))
	     (create-uri-path (cdr uri) lista 1))
	    ((and (or (string= (first uri) "?") (string= (first uri) "#")) 
		  (= counter 1))
	     (not-valid-uri lista "path")
	     (setq next (append uri nil))
	     (coerce lista 'string))
	    ((and (string= (first uri) "/") (null (cdr uri)) (= counter 0))
	     (setq next NIL)
	     NIL)
	    ((and (string= (first uri) "/") (null (cdr uri)) (= counter 1))
	     (setq lista (append lista (cons (first uri) nil)))
	     (not-valid-uri lista "path")
	     (setq next NIL)
	     (coerce lista 'string))
	    ((null (cdr uri))
	     (setq next NIL)
	     (setq lista (append lista (cons (first uri) nil)))
	     (not-valid-uri lista "path")
	     (coerce lista 'string))
	    ((and (or (not (string= (first uri) "?")) 
		      (not (string= (first uri) "#"))) (= counter 1))
	     (setq lista (append lista (cons (first uri) nil)))
	     (create-uri-path (cdr uri) lista 1))
	    )
	  NIL
	  )
      )
  )

; Questa funzione estrae la query. 
; Il primo ? funge da delimitatore.
(defun create-uri-query (uri lista counter)
  (if (not (null uri))
      (cond 
	((and (string= (first uri) "?") (null (cdr uri))
	      (= counter 0))
	 (error "Query non valida!"))
	((and (string= (first uri) "?") (string= (second uri) "#")
	      (= counter 0))
	 (error "Query non valida!"))
	((and (string= (first uri) "?") (= counter 0))
	 (create-uri-query (cdr uri) lista 1))
	((and (string= (first uri) "#") (= counter 0))
	 (setq next (append uri NIL))
	 NIL)
	((and (string= (first uri) "#") (= counter 1)(null lista))
	 (setq next (append uri NIL))
	 NIL)
	((and (string= (first uri) "#") (= counter 1))
	 (setq next (append uri NIL))
	 (coerce lista 'string))
	((null (cdr uri))
	 (setq lista (append lista (cons (first uri) nil)))
	 (setq next NIL)
	 (coerce lista 'string))
	((not (null (cdr uri)))
	 (setq lista (append lista (cons (first uri) nil)))
	 (create-uri-query (cdr uri) lista 1))
	)
      NIL
      )
  )

; Questa funzione estrae il fragment. 
; Il primo # funge da delimitatore.
(defun create-uri-fragment (uri lista counter)
  (if (not (null uri))
      (cond 
	((and (string= (first uri) "#") (null (cdr uri)) 
	      (= counter 0))
	 (error "Fragment non valido!"))
	((and (string= (first uri) "#") (= counter 0))
	 (create-uri-fragment (cdr uri) lista 1))
	((null (cdr uri))
	 (setq lista (append lista (cons (first uri) nil)))
	 (coerce lista 'string))
	((not (null (cdr uri)))
	 (setq lista (append lista (cons (first uri) nil)))
	 (create-uri-fragment (cdr uri) lista 1))
	)
      NIL
      )
  )

; Questa e' la funzione principale. 
; Il suo unico compito e' quello di creare i vari campi
; della struct, spezzando la URI in varie parti.
(defun parse-uri (uri)
  (setq scheme (create-uri-scheme (coerce uri 'list) (list)))
  (make-url
   :scheme scheme ; <-- estratto sopra
   :userinfo (create-uri-userinfo next (list) 0)
   :host (create-uri-host next)
   :port (create-uri-port next (list) 0)
   :path (create-uri-path next (list) 0)
   :query (create-uri-query next (list) 0)
   :fragment (create-uri-fragment next (list) 0)
   )
  )

; Queste funzioni restituiscono i vari campi dela struct.
(defun uri-scheme (uri) (url-scheme uri))
(defun uri-userinfo (uri) (url-userinfo uri))
(defun uri-host (uri) (url-host uri))
(defun uri-path (uri) (url-path uri))
(defun uri-port (uri) (url-port uri))
(defun uri-query (uri) (url-query uri))
(defun uri-fragment (uri) (url-fragment uri))

;;;  EOF   ;;;

;;;   This is free software   ;;;
