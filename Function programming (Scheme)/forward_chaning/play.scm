;;; play.scm ~ Framework pentru rularea agenților (Tema 2)
;;; v0.95
;;; autor: Tudor Berariu
;;; Inteligență Artificială 2012-2013

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------
;;; Secțiuni:
;;;  1. Încărcarea fișierului "agents.scm"
;;;  2. Configurarea afișării pe ecran
;;;  3. Definiții constante
;;;  4. Informații extrase din starea mediului și starea agentului
;;;  5. Funcții utile
;;;  6. Rezultate și statistici
;;;  7. Afișare
;;;  8. Verificarea acțiunilor
;;;  9. Aplicarea acțiunilor
;;; 10. Verificarea testelor
;;; 11. Configurare canvas
;;; 12. Redesenare GUI
;;; 13. Rularea scenariilor
;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 1. Încărcarea fișierului "agents.scm"

;;; Se încarcă fișierul cu agenții
;;; Se așteaptă 2 definiții: memoryless-agent și advanced-agent
(load "agents.scm")

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 2. Configurarea afișării pe ecran

;; Se afișează markere pentru delimitarea rundelor
(define _print-round-separator? #t)
;; Se așteaptă apăsarea unei taste după fiecare rundă
(define _pause-before-next-round? #f)
;; Se afișează scorul curent
(define _print-score? #t)
;; Se afișează starea lumii la finalul fiecărui tur
(define _print-world-state? #t) 
;; Se afișează starea agenților la finalul fiecărui tur 
(define _print-agent-state? #t)
;; Se afișează planul complet reîntors de planificator
(define _print-new-plan? #t)
;; Se afișează acțiunile care nu s-au putut aplica
(define _print-action-error? #t)
;; Se afișează acțiunile aplicate
(define _print-action? #t)
;; Se afișează condițiile
(define _print-condition? #t)
;; Se afișează GUI
(define _display-gui? #t)
;; Sleep x secunde înainte de runda următoare
(define _SLEEP-TIME-BEFORE-NEXT-ROUND 0)

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 3. Definiții constante

;;; Lista de culori ale sferelor
(define _SPHERE-COLORS '(Red Blue Gray))

;;; Cealaltă culoare față de @color dintre Red și Blue
(define (_next-agent color) (car (remove color '(Red Blue))))

;;; Pixeli pentru latura unei camere
(define _ROOM-RADIUS 80)


;;; culori pentru GUI
(define _RED-AGENT-COLOR (send the-color-database find-color "Red"))
(define _BLUE-AGENT-COLOR (send the-color-database find-color "Blue"))
(define _RED-ROOM-COLOR (send the-color-database find-color "Orange Red"))
(define _BLUE-ROOM-COLOR (send the-color-database find-color "RoyalBlue"))
(define _WHITE-ROOM-COLOR (send the-color-database find-color "White"))
(define _RED-SPHERE-COLOR (send the-color-database find-color "Red"))
(define _BLUE-SPHERE-COLOR (send the-color-database find-color "Blue"))
(define _GRAY-SPHERE-COLOR (send the-color-database find-color "Gray"))
(define _AGENT-CONTOUR-COLOR (send the-color-database find-color "Black"))
(define _ROOM-CONTOUR-COLOR (send the-color-database find-color "Black"))
(define _SPHERE-CONTOUR-COLOR (send the-color-database find-color "Olive"))

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 4. Informații extrase din starea agentului și starea lumii

;;; lista camerelor din scenariu
(define (_all-rooms world-state)
  (map second 
       (filter (λ (arg) (and (equal? (first arg) 'Color)
                             (equal? (length arg) 3)))
               world-state)))

;;; depozitul de culoare @color conform @world-state
(define (_warehouse color world-state) 
  (second (findf (λ (arg) (and (equal? (first arg) 'Color) 
                               (equal? (third arg) color)))
                 world-state)))

;;; culoarea camerei @room
(define (_color-of-room room world-state) 
  (third (findf (λ (arg) (and (equal? (first arg) 'Color) 
                              (equal? (second arg) room)))
                world-state)))

;;; numărul de sfere de culoarea @color încărcate de robot
(define (_loaded-spheres-color agent-state color)
  (third (findf (λ (arg) (and (equal? (first arg) 'Carries)
                              (equal? (second arg) color)))
                agent-state)))

;;; numărul total de sfere încărcate de robot
(define (_loaded-spheres-total agent-state)
  (apply + (map (λ (c) (_loaded-spheres-color agent-state c))
                _SPHERE-COLORS)))

;;; numărul total de sfere încărcate de robot
(define (_loaded-spheres agent-state)
  (apply append (map (λ (c) 
                       (let ((no (_loaded-spheres-color agent-state c)))
                         (cond ((= no 1) (list c))
                               ((= no 2) (list c c))
                               (#t '()))))
                _SPHERE-COLORS)))

;;; numărul de sfere de culoarea @color din camera @room
(define (_in-room-spheres-color color room world-state)
  (fourth (findf (λ (arg) (and (equal? (first arg) 'Spheres)
                               (equal? (second arg) color)
                               (equal? (third arg) room)))
                 world-state)
          )
  )
  
;;; *_delivered* întoarce '(Spheres @color warehouse n)
;;; pentru culoarea @color, unde warehouse este depozitul de culoare @color
;;; iar n numărul de sfere livrate până acum
(define (_delivered color world-state)
  (findf (λ (arg) (and (equal? (first arg) 'Spheres)
                       (equal? (second arg) color)
                       (equal? (third arg) (_warehouse color world-state))))
           world-state))

;;; *_one-sphere-goal* întoarce '(Spheres @color warehouse (+ n 1))
;;; pentru culoarea @color, unde warehouse este depozitul de culoare @color
;;; iar n numărul de sfere livrate până acum
(define _one-sphere-goal
  (λ (color world-state)
    (let* ((done (_delivered color world-state)))
      `(,(first done) ,(second done) ,(third done)
                      ,(+ 1 (fourth done)))
      )
    )
  )

;;; *_all-spheres-goal* întoarce '(Spheres @color warehouse M)
;;; pentru culoarea @color, unde warehouse este depozitul de culoare @color
(define _all-spheres-goal
  (lambda (color world-state)
    (let* ((done (_delivered color world-state)))
      `(,(first done) ,(second done) ,(third done)
                      ,M)
      )
    )
  )

;;; *_initial-agent-state* întoarce starea inițială a agentului de culoare
;;; @color conform stării inițiale a lumii *world-state*
(define _initial-agent-state
  (λ (color world-state)
    (append (map (λ (c) (list 'Carries c 0)) _SPHERE-COLORS)
            `((Location ,(_warehouse color world-state))
              (Color ,color)))
    )
  )

;;; *_winner?* întoarce #t dacă în starea @world-state unul dintre agenți
;;; a reușit să ducă toate sferele la depozit și #f altfel
(define _winner?
  (λ (world-state)
    (or (= (fourth (_delivered 'Red world-state)) M)
        (= (fourth (_delivered 'Blue world-state)) M)
        )
    )
  )

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 5. Funcții Utile

;;; *is-variable?* verifică dacă o formulă @f reprezintă o variabilă.
;;; Se consideră că variabilele sunt simboluri în Scheme scrise cu literă mică.
(define is-variable?
  (λ (f)
    (and (symbol? f)
         (let ((start (substring (symbol->string f) 0 1))) 
           (and (string>=? start "a") (string<=? start "z")
                (not (member f '(and or forall exist neg equiv)))
                )))
    )
  )

;;; ---------------------------------------------------------------------------

;;; *eval-func* evaluează o formulă @f ce reprezintă aplicarea unei funcții.
;;; Cum rezultatul unei funcții în logica de ordinul întâi este un obiect, un
;;; apel de funcție poate apărea ca argument al unui alt apel de funcție.
(define eval-func
  (λ (f)
    (apply (car f)
           (map (λ (arg) (if (list? arg) (eval-func arg) arg)) (cdr f)))
    )
  )

;;; ---------------------------------------------------------------------------
;;; ---------------------------------------------------------------------------

;;; *sort-substitution* ordonează substituțiile unui unificator astfel
;;; încât pentru o variabilă x substituția (x . ?) să apară după toate
;;; substituțiile (? . x) și înainte de ((SKOLEM ... x ...) . ?)
(define sort-substitution
  (λ (subst)
    (if (null? subst) subst
        (let ((first (findf (λ (arg) 
                              (not (findf (λ (p) 
                                            (or (equal? (cdr p) (car arg))
                                                (and (list? (car arg))
                                                     (not (equal? p arg))
                                                     (member (cdr p) (car arg)))
                                                ))
                                          subst)))
                            subst)))
          (if first
              (cons first (sort-substitution (remove first subst)))
              ;;; nu rezolvă problema ciclurilor (de revăzut)!!!
              (cons (car subst) (sort-substitution (cdr subst))))
          ))
    )
  )

;;; *substitute* aplică în formula @f substituțille din lista @subst
;;; ATENȚIE! Substutuțiile ciclice '((x . y) (y . z) (z . x)), deși pot fi
;;; avea sens logic, nu funcționează! *unify* nu produce astfel de unificatori.
(define _substitute
  (λ (f subst)
    (foldl
     (λ (s e) (cond ((equal? (car s) e) (cdr s))
                    ((list? e) (map (λ (arg) (_substitute arg (list s))) e))
                    (#t e))
       ) 
     f subst))
  )
(define (substitute f subst) (_substitute f (sort-substitution subst)))


;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;
;;; extrage valoarea după cheie dintr-o listă de perechi
(define (_value-of val pairs)
  (let ((val (assoc val pairs))) 
    (if val (cdr val) val)))

;;; shortcut pentru linie nouă
(define (_nl) (display "\n"))
         
;;; *_modify* reîntoarce lista obținută prin aplicarea funcției @proc asupra
;;; tuturor elementelor din @list asupra cărora aplicarea funcției @test
;;; reîntoarce #t (restul elementelor rămân neschimbate).
;;;
;;; exemplu: 
;;; (_modify '(1 2 3 4 5 6) (λ (x) (eq? (modulo x 2) 1)) (λ (x) (* -1 x)))

(define _modify
  (λ (list test proc) (map (λ (arg) (if (test arg) (proc arg) arg)) list))
  )


(define _take
  (λ (lst n)
    (if (or (not (list? lst)) (empty? lst) (< n 1)) '()
        (cons (car lst) (_take (cdr lst) (- n 1))))))

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------
        
;;;;; 6. Rezultate și statistici

;;; *_end-game* afișează rezultatele finale
(define _end-game
  (λ (world-state statistics)
    (let ((red-score (fourth (_delivered 'Red world-state)))
          (blue-score (fourth (_delivered 'Blue world-state))))
      (cond ((> red-score blue-score)
             (display "Agentul ROȘU a câștigat!\n"))
            ((< red-score blue-score)
             (display "Agentul ALBASTRU a câștigat!\n"))
            (#t (display "Egalitate!\n")))
      (display "ROȘU vs. ALBASTRU\n")
      (display red-score) (display " ~ ") (display blue-score) (_nl)
      (map (λ (arg) 
             (begin
               (display (first arg)) (display ": ")
               (display (second (second arg))) (display " ~ ")
               (display (second (third arg))) (_nl)
               ))
           (_compute-average-planning-time statistics))
      #t
      )
    )
  )

;;; *_initial-statistics* construiește o listă de perechi cu contoarele pe zero
(define (_initial-statistics)
  '(("Acțiuni" . ((Red 0) (Blue 0)))
    ("Replanificări" . ((Red 0) (Blue 0)))
    ("Erori de aplicare" . ((Red 0) (Blue 0)))
    ("Teste trecute" . ((Red 0) (Blue 0)))
    ("Teste eșuate" . ((Red 0) (Blue 0)))
    ("Timp total planificare" . ((Red .0) (Blue .0)))
    ("Timp mediu planificare" . ((Red .0) (Blue .0)))
    )
  )

;;; *_increment* adaugă în @statistics 1 la categoria @str-name pentru robotul
;;; de culoare @color
(define _increment
  (λ (str-name color statistics)
    (_modify statistics
            (λ (x) (string=? str-name (car x)))
            (λ (x) (cons (car x) 
                         (_modify (cdr x)
                                 (λ (c) (equal? (car c) color))
                                 (λ (c) (list (car c) (+ 1 (second c)))))
                         )
              )
            )
    )
  )

;;; *_add-to-statistics* adaugă în @statistics @val la categoria @str-name pentru robotul
;;; de culoare @color
(define _add-to-statistics
  (λ (str-name color val statistics)
    (_modify statistics
            (λ (x) (string=? str-name (car x)))
            (λ (x) (cons (car x) 
                         (_modify (cdr x)
                                 (λ (c) (equal? (car c) color))
                                 (λ (c) (list (car c) (+ val (second c)))))
                         )
              )
            )
    )
  )

;;; *_compute-average-planning-time* calculează timpul mediu de planificare
(define _compute-average-planning-time
  (λ (statistics)
    (_modify statistics
            (λ (x) (string=? "Timp mediu planificare" (car x)))
            (λ (x) (cons (car x)
                         (map
                          (λ (z) 
                            (list (car z)
                                  (/ 
                                   (car (_value-of (car z) (_value-of "Timp total planificare" statistics)))
                                   (car (_value-of (car z) (_value-of "Replanificări" statistics)))))
                            )
                          (cdr x))
                         ))
            )
    )
  )
    
   

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 7. Afișare

(define (_print-round-separator color)
  (begin
    (display "--------------------------------------\n") 
    (display "--------------------------------------\n")
    (display "Runda: ") (display color) (_nl) (_nl) 
    )
  )

(define (_print-score world-score)
  (begin
    (display "ROȘU : ")
    (display (fourth (_delivered 'Red world-score)))
    (display " ~~~ ")
    (display (fourth (_delivered 'Blue world-score)))
    (display " : ALBASTRU\n\n") 
    )
  )

(define _print-world-state
  (λ (world-state)
    (begin
      (display "[Cameră : Roșii, Albastre, Gri]\n")
      (map
       (λ (room)
         (display "[") (display room) (display ":")
         (map
          (λ (color)
            (begin
              (display " ")
              (display (_in-room-spheres-color color room world-state))
              ))
          _SPHERE-COLORS
          )
         (display "]")
         )
       (_all-rooms world-state)
       )
      (_nl)(_nl)
      )
    )
  )

(define _print-agent-state
  (λ (agent-state)
    (begin
      (display (_value-of 'Color agent-state))
      (display "\tSfere:")
      (map
       (λ (color)
         (begin
           (display " ")
           (display (_loaded-spheres-color agent-state color))
           ))
          _SPHERE-COLORS
          )
      (display "\tLocalizare: ")
      (display (_value-of 'Location agent-state))
      (_nl)
      )
    )
  )

(define _print-new-plan
  (λ (plan)
    (display "Plan nou: ")
    (display plan)  
    (_nl)
    )
  )

(define _print-action-error 
  (λ (action message)
    (begin
      (display "EROARE:\t")
      (display action) (_nl) (display message)(_nl)
      )
    ))

(define _print-action 
  (λ (action)
    (begin
      (display "EXECUTĂ:\t")
      (display action) (_nl)
      )
    ))

(define _print-condition
  (λ (condition result)
    (begin
      (display "TEST:\t")
      (display condition)
      (display " ===> ")
      (display (if result "ADEVĂRAT" "FALS"))
      (_nl)
      )
    )
  )
;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 8. Verificarea acțiunilor

;;; *_check-move-action* verifică dacă o acțiune Move este validă
;;; @args reprezintă parametrii acțiunii
;;; @agent-state este starea agentului
;;; @world-state este starea lumii
(define _check-move-action
  (λ (args agent-state world-state)
    (cond ((not (= (length args) 2))
           '(#f . "Număr incorect de parametri"))
          ((or (not (member (first args) (_all-rooms world-state)))
               (not (member (second args) (_all-rooms world-state))))
           '(#f . "Argumentele nu sunt camere din scenariul curent"))
          ((not (member (list 'Location (first args)) agent-state))
           '(#f . "Primul argument din Move nu coincide cu camera curentă"))
          ((not (member (list 'Door (first args) (second args)) world-state))
           '(#f . "Nu exista o ușă între camerele date ca paremtri"))
          ((= (modulo (_loaded-spheres-total agent-state) 2) 1)
           '(#f . "Robotul nu poate călători cu o singură sferă"))
          (#t '(#t . "ok"))
          )
    )
  )

;;; *_check-load-action* verifică dacă o acțiune Load este validă
(define _check-load-action
  (λ (args agent-state world-state)
    (let* ((room (second (assoc 'Location agent-state)))
           (color (first args)))
      (cond ((> (_loaded-spheres-total agent-state) 1)
             '(#f . "Robotul are compartimentele pline"))
            ((equal? (_color-of-room room world-state) color)
             '(#f . "Nu se pot ridica sferele duse deja la depozitul lor"))
            ((< (_in-room-spheres-color color room world-state) 1)
             '(#f . "Nu există sfere de acea culoare în camera curentă"))
            (#t '(#t . "ok"))
            )
      )
    )
  )

;;; *_check-unload-action*
(define _check-unload-action
  (λ (args agent-state world-state)
    (let* ((colored-spheres (_loaded-spheres-color agent-state (first args))))
      (if (> colored-spheres 0) '(#t . "ok") 
          '(#f . "Robotul nu are sfere pe care sa le descarce")
          )
      )
    )
  )

;;; *_sort-conditions* sorteaza predicatele astfel încât să se poată
;;; lega variabilele și face verificările... dacă se poate
(define _sort-conditions
  (λ (conditions known-vars)
    (if (empty? conditions)
        '()
        (let* ((first-el
                (findf (λ (arg)
                         (or 
                          ;; Fie este un predicat 'Spheres
                          (equal? (first arg) 'Spheres)
                          ;; Fie este un Succ cu măcar o variabilă legată
                          (and (equal? (first arg) 'Succ)
                               (or (member (second arg) known-vars)
                                   (member (third arg) known-vars)))
                          ;; Fie este un Greater cu ambele variable legate
                          (and (equal? (first arg) 'Greater)
                               (member (second arg) known-vars)
                               (member (third arg) known-vars))
                          ;; Fie este un Positive cu variabila legată
                          (and (equal? (first arg) 'Positive)
                               (member (second arg) known-vars)))
                         )
                       conditions)))
          (if first-el
              (let* ((new-vars (cond ((equal? (first first-el) 'Spheres)
                                      (list (fourth first-el)))
                                     ((equal? (first first-el) 'Succ)
                                      (cdr first-el))
                                     (#t '())))
                     (sorted-rest (_sort-conditions 
                                   (remove first-el conditions)
                                   (append new-vars known-vars))))
                (if sorted-rest (cons first-el sorted-rest) #f))
              #f
              )
          )
        )
    )
  )
                                                 
;;; *_check-test-action*
(define _check-test-action
  (λ (arguments agent-state world-state)
    (if (_sort-conditions arguments '()) '(#t . "ok") 
        '(#f . "Nu s-a găsit o ordonare bună a condițiilor."))
    )
  )

;;; *_operator-check* verifică dacă se poate aplica acțiunea @action
;;; din statea agentului @agent-state și starea lumii @world-state
(define _operator-check
  (λ (action agent-state world-state)
    (cond ((equal? (first action) 'Move)
           (_check-move-action (cdr action) agent-state world-state))
          ((equal? (first action) 'Load)
           (_check-load-action (cdr action) agent-state world-state))
          ((equal? (first action) 'Unload)
           (_check-unload-action (cdr action) agent-state world-state))
          ((equal? (first action) 'Test)
           (_check-test-action (cdr action) agent-state world-state))
          (#t '(#f . "Operator necunoscut")))
    )
  )

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 9. Aplicarea acțiunilor

;;; *_apply-action* reîntoarce noua starea a lumii și noua stare
;;; a agentului după aplicarea acțiunii @action în starea mediului
;;; @world-state și în starea internă a agentului @ag-state .
;;; (car @action) poate fi doar Move, Unload sau Load .
(define _apply-action
  (λ (action world-state ag-state)
    (if (equal? (first action) 'Move)
        ;; acțiunea Move: schimbăm Location în starea agentului
        (cons world-state
              (_modify ag-state 
                      (λ (arg) (equal? (first arg) 'Location))
                      (λ (arg) (list 'Location (third action)))))
        ;; acțiune Load sau Unload
        (let* ((n (_value-of (first action) '((Load . 1) (Unload . -1))))
               (color (second action))
               (room (first (_value-of 'Location ag-state))))
          (cons
           (_modify world-state
                   (λ (arg) (and (equal? (first arg) 'Spheres)
                                 (equal? (second arg) color)
                                 (equal? (third arg) room)))
                   (λ (arg) `(Spheres ,color ,room ,(- (fourth arg) n))))
           (_modify ag-state
                   (λ (arg) (and (equal? (first arg) 'Carries)
                                 (equal? (second arg) color)))
                   (λ (arg) `(Carries ,color ,(+ (third arg) n)))))
          )))
    )

;;;;; 10. Verificarea testelor

;;; *_check-conditions* evaluează conjuncția de condiții @conditions
;;; conform stării curente a lumii @world-state
(define _check-conditions
  (λ (conditions world-state)
    (_verify-conditions (_sort-conditions conditions '())
                       world-state '())
    )
  )

;;; *_verify-conditions* evaluează condițiile și le verifică cu starea
;;; curentă a lumii @world-state
;;; funcția este recursivă, iar @bindings reprezintă legările anterioare
;;; ale variabilelor la numere
(define _verify-conditions
  (λ (conditions world-state bindings)
    (if (empty? conditions) #t
        (let ((cond1 (first conditions)))
          (cond (;; Dacă este un termen Spheres
                 (equal? (first cond1) 'Spheres)
                 (let* ((s (findf
                            (λ (arg) 
                              (and (equal? (first arg) (first cond1))
                                   (equal? (second arg) (second cond1))
                                   (equal? (third arg) (third cond1))))
                            world-state))
                        (x (fourth cond1))
                        (val (fourth s))
                        )
                   (cond 
                     ((number? x)
                      (and (equal? x val)
                           (_verify-conditions (cdr conditions)
                                              world-state bindings)))
                     ((assoc x bindings)
                      (and (equal? val (_value-of x bindings))
                           (_verify-conditions (cdr conditions)
                                              world-state bindings)))
                     (#t (_verify-conditions (cdr conditions)
                                            world-state
                                            (cons (cons x val) bindings))))
                   ))
                (;; Dacă este un succc
                 (equal? (first cond1) 'Succ)
                 (let ((n1 (second cond1))
                       (n2 (third cond1)))
                   (cond ((number? n1)
                          (cond ((number? n2)
                                 (and (= (+ 1 n1) n2)
                                      (_verify-conditions (cdr conditions)
                                                         world-state 
                                                         bindings)))
                                ((assoc n2 bindings)
                                 (and (= (+ 1 n1) (_value-of n2 bindings))
                                      (_verify-conditions (cdr conditions)
                                                         world-state
                                                         bindings)))
                                (#t (_verify-conditions (cdr conditions)
                                                       world-state
                                                       (cons (cons n2 (+ 1 n1))
                                                             bindings)))
                                ))
                         ((assoc n1 bindings)
                          (cond ((number? n2)
                                 (and (= (+ 1 (_value-of n1 bindings)) n2)
                                      (_verify-conditions (cdr conditions)
                                                         world-state
                                                         bindings)))
                                ((assoc n2 bindings)
                                 (and (= (+ 1 (_value-of n1 bindings))
                                         (_value-of n2 bindings))
                                      (_verify-conditions (cdr conditions)
                                                         world-state
                                                         bindings)))
                                (#t (_verify-conditions 
                                     (cdr conditions) world-state
                                     (cons (cons n2 (_value-of n1 bindings))
                                           bindings)))
                                ))
                         (#t (cond ((number? n2)
                                    (_verify-conditions (cdr conditions)
                                                       world-state
                                                       (cons 
                                                        (cons n1 (- n2 1))
                                                        bindings)))
                                   ((assoc n2 bindings)
                                    (_verify-conditions (cdr conditions)
                                                       world-state
                                                       (cons 
                                                        (cons n1 
                                                              (- (_value-of n2 bindings) 1))
                                                        bindings)))
                                   (#t #f)))
                         )))
                (;;; este un Positive
                 (equal? (first cond1) 'Positive)
                 (let ((x (second cond1)))
                   (and (> (_value-of x bindings) 0)
                        (_verify-conditions (cdr conditions)
                                           world-state bindings))
                   ))
                (;;; este un Greater
                 (equal? (first cond1) 'Greater)
                 (let ((x (second cond1))
                       (y (third cond1)))
                   (and (> (_value-of x bindings) (_value-of y bindings))
                        (_verify-conditions (cdr conditions)
                                           world-state bindings))
                   ))
                (#t #f))
          )
        )
    )
  )

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 11. Poziționare camere pe canvas

(define _get-matrix
  (λ (world-state)
    (let* ((rooms
            (map (λ (x) (cons (second x) 0))
               (filter (λ (x) 
                     (and (equal? (car x) 'Color)
                          (= (length x) 3)))
                       initial-world-state)))
           (edges (map (λ (x) (cons (second x) (third x)))
                       (filter (λ (x) (equal? (car x) 'Door)) 
                               initial-world-state))))
      (cons (cons (car (car rooms)) (cons 0 0))
            (_search-pos (list (cons (car (car rooms)) (cons 0 0)))
                        (map (λ (arg)
                               (if (or (member (cons (car arg) (car (car rooms)))
                                               edges)
                                       (member (cons (car (car rooms)) (car arg))
                                               edges))
                                   (cons (car arg) (+ 1 (cdr arg)))
                                   arg))
                             (cdr rooms))
                        edges)
            )
      )
    )
  )

(define _get-all-around
  (λ (p)
    (map (λ (arg) (cons (+ (car p) (car arg))
                        (+ (cdr p) (cdr arg))))
         (list '(1 . 0) '(1 . 1) '(1 . -1)
               '(0 . 1) '(0 . -1) 
               '(-1 . 0) '(-1 . 1) '(-1 . -1))
         )
    )
  )

(define _next-to 
  (λ (p1 p2)
    (member (cons (- (car p1) (car p2)) (- (cdr p1) (cdr p2)))
            '((-1 . -1) (-1 . 0) (-1 . 1) (0 . -1) (0 . 1) (1 . -1) (1 . 0) (1 . 1))
            )
    )
  )

  
(define _search-pos
  (λ (fixed left edges)
    (if 
     ;; s-a găsit o soluție.. întoarce o listă
     (empty? left) '()
     ;; mai avem camere
     (let* ((sorted (sort left (λ (r1 r2) (>= (cdr r1) (cdr r2)))))
            ;; next-room e camera cu cei mai mulți vecini
            (next-room (first sorted))
            ;; positions este lista cu pozițiile valide pentru next-room
            (positions
             (filter
              (λ (position)
                (not (member position (map cdr fixed))))
              (foldl (λ (r p)
                       (if (or (member (cons (car next-room) (car r)) edges)
                               (member (cons (car r) (car next-room)) edges))
                           (if (equal? p 'start)
                                 (_get-all-around (cdr r))
                                 (filter (λ (pos)
                                           (_next-to pos (cdr r)))
                                         (remove (cdr r) p))
                                 )
                           p)
                       )
                     'start
                     fixed))))
       (foldl (λ (p r)
                (if (list? r) r
                    (let ((result
                           (_search-pos
                            (cons (cons (car next-room) p) fixed)
                            (map (λ (arg)
                                   (if (or (member (cons (car next-room) (car arg)) edges)
                                           (member (cons (car arg) (car next-room)) edges))
                                       (cons (car arg) (+ (cdr arg) 1))
                                       arg
                                       )
                                   )
                                 (cdr sorted))
                            edges)))
                      (if (list? result)
                          (cons (cons (car next-room) p) result)
                          #f
                          )
                      )
                    )
                )
              #f
              positions)
       )
     )
    )
  )


;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 12. Desenare GUI

(define _frame (new frame% [label "Planificare"]))
(define _canvas (new canvas% [parent _frame]))
(define _in-room-positions
  '((-1 . 0) (0 . -1) (-2 . 0) (-1 . -1) (0 . -2)
              (-3 . 0) (-2 . -1) (-1 . -2) (0 . -3)))

(define _redraw
  (λ (positions world-state red-state blue-state)
    (begin 
      ;(send _canvas suspend-flush)
      (let ((redraw-proc 
             (λ (dc)
               (begin
                 (send (send _canvas get-dc) erase)
                 (for-each
                  (λ (room)
                    (let* (;(dc (send _canvas get-dc))
                           (x (* (cadr room) 2.5 _ROOM-RADIUS))
                           (y (* (cddr room) 2.5 _ROOM-RADIUS))
                           (to (map third (filter (λ (arg)
                                                    (and (equal? (first arg) 'Door)
                                                         (equal? (second arg) (car room))))
                                                  world-state)))
                           (ncoord (map (λ (arg)
                                          (cons
                                           (- (car (_value-of arg positions)) (cadr room))
                                           (- (cdr (_value-of arg positions)) (cddr room))
                                           ))
                                        to))
                           )
                      (begin
                      ;; desenează camerele
                        
                        (send dc set-smoothing 'aligned)
                        (send dc set-pen _ROOM-CONTOUR-COLOR 2 'solid)
                        (send dc set-brush
                              (_value-of
                               (_color-of-room (car room) world-state)
                               `((Red . ,_RED-ROOM-COLOR)
                                 (Blue . ,_BLUE-ROOM-COLOR)
                                 (White . ,_WHITE-ROOM-COLOR)))
                              'crossdiag-hatch)
                        (send dc draw-ellipse 
                              (+ x (* .25 _ROOM-RADIUS)) (+ y (* .25 _ROOM-RADIUS)) 
                              (* 2 _ROOM-RADIUS) (* 2 _ROOM-RADIUS))
                        ;; desenează arcele
                        (for-each
                         (λ (arg)
                           (let* ((startx (if (= (cdr arg) 0) 
                                              (+ x (* .25 _ROOM-RADIUS) _ROOM-RADIUS 
                                                 (* _ROOM-RADIUS (sgn (car arg))))
                                              (+ x (* .25 _ROOM-RADIUS) _ROOM-RADIUS 
                                                 (* (/ _ROOM-RADIUS (sqrt 2)) (sgn (car arg))))))
                                  
                                  (starty (if (= (car arg) 0) 
                                              (+ y (* .25 _ROOM-RADIUS) _ROOM-RADIUS 
                                               (* _ROOM-RADIUS (sgn (cdr arg))))
                                              (+ y (* .25 _ROOM-RADIUS) _ROOM-RADIUS 
                                                 (* (/ _ROOM-RADIUS (sqrt 2)) (sgn (cdr arg))))))
                                  
                                  (endx (if (= (cdr arg) 0) 
                                            (+ startx (* (sgn (car arg)) (* .5 _ROOM-RADIUS)))
                                            (+ startx (* (sgn (car arg)) 
                                                         (* 2 _ROOM-RADIUS (- 1.25 (/ 1(sqrt 2))))))))
                                  
                                  (endy (if (= (car arg) 0) 
                                            (+ starty (* (sgn (cdr arg)) (* .5 _ROOM-RADIUS)))
                                            (+ starty (* (sgn (cdr arg))
                                                       (* 2 _ROOM-RADIUS (- 1.25 (/ 1(sqrt 2))))))))
                                  
                                  (arrowx1 (cond ((= (cdr arg) 0) (- endx (* 10 (sgn (car arg)))))
                                                 ((= (car arg) 0) (- endx (* 10 (sgn (cdr arg)))))
                                                 (#t (- endx (* 14.1 (sgn (car arg)))))))
                                  (arrowx2 (cond ((= (cdr arg) 0) (- endx (* 10 (sgn (car arg)))))
                                                 ((= (car arg) 0) (+ endx (* 10 (sgn (cdr arg)))))
                                                 (#t endx)))
                                  (arrowy1 (cond ((= (car arg) 0) (- endy (* 10 (sgn (cdr arg)))))
                                                 ((= (cdr arg) 0) (+ endy (* 10 (sgn (car arg)))))
                                               (#t endy)))
                                  (arrowy2 (cond ((= (car arg) 0) (- endy (* 10 (sgn (cdr arg)))))
                                                 ((= (cdr arg) 0) (- endy (* 10 (sgn (car arg)))))
                                                 (#t (- endy (* 14.1 (sgn (cdr arg)))))))
                                  )
                             (send dc set-pen _ROOM-CONTOUR-COLOR 2 'solid)
                             (send dc draw-line startx starty endx endy)
                             (send dc draw-line endx endy arrowx1 arrowy1)
                             (send dc draw-line endx endy arrowx2 arrowy2)
                             ;; agenții
                             (if (equal? (car (_value-of 'Location red-state)) (car room))
                                 (begin
                                   (send dc set-pen _AGENT-CONTOUR-COLOR 1 'solid)
                                   (send dc set-brush _RED-AGENT-COLOR 'solid)
                                   (send dc draw-rectangle (+ x _ROOM-RADIUS 1) (+ y _ROOM-RADIUS 1) 
                            (- (/ _ROOM-RADIUS 4) 2) (- (/ _ROOM-RADIUS 2) 2))
                                   (let ((s (_loaded-spheres red-state)))
                                     (if (> (length s) 0)
                                         (begin
                              (send dc set-brush
                                    (_value-of (first s)
                                              `((Red . ,_RED-SPHERE-COLOR)
                                                (Blue . ,_BLUE-SPHERE-COLOR)
                                                (Gray . ,_GRAY-SPHERE-COLOR))) 'solid)
                              (send dc set-pen _ROOM-CONTOUR-COLOR 1 'solid)
                              (send dc draw-ellipse 
                                    (+ x _ROOM-RADIUS 3)
                                    (+ y _ROOM-RADIUS 3)
                                    (- (/ _ROOM-RADIUS 4) 6)
                                    (- (/ _ROOM-RADIUS 4) 6))
                              ))
                        (if (> (length s) 1)
                            (begin
                              (send dc set-brush
                                    (_value-of (second s)
                                              `((Red . ,_RED-SPHERE-COLOR)
                                                (Blue . ,_BLUE-SPHERE-COLOR)
                                                (Gray . ,_GRAY-SPHERE-COLOR))) 'solid)
                              (send dc set-pen _ROOM-CONTOUR-COLOR 1 'solid)
                              (send dc draw-ellipse 
                                    (+ x _ROOM-RADIUS 3)
                                    (+ y (* _ROOM-RADIUS 1.25) 3)
                                    (- (/ _ROOM-RADIUS 4) 6)
                                    (- (/ _ROOM-RADIUS 4) 6))
                              ))
                        )
                      )
                    )
                (if (equal? (car (_value-of 'Location blue-state)) (car room))
                    (begin
                      (send dc set-pen _AGENT-CONTOUR-COLOR 1 'solid)
                      (send dc set-brush _BLUE-AGENT-COLOR 'solid)
                      (send dc draw-rectangle (+ x (* 1.25 _ROOM-RADIUS) 1) (+ y _ROOM-RADIUS 1) 
                            (- (/ _ROOM-RADIUS 4) 2) (- (/ _ROOM-RADIUS 2) 2))
                      (let ((s (_loaded-spheres blue-state)))
                        (if (> (length s) 0)
                            (begin
                              (send dc set-brush
                                    (_value-of (first s)
                                              `((Red . ,_RED-SPHERE-COLOR)
                                                (Blue . ,_BLUE-SPHERE-COLOR)
                                                (Gray . ,_GRAY-SPHERE-COLOR))) 'solid)
                              (send dc set-pen _ROOM-CONTOUR-COLOR 1 'solid)
                              (send dc draw-ellipse 
                                    (+ x (* _ROOM-RADIUS 1.25) 3)
                                    (+ y _ROOM-RADIUS 3)
                                    (- (/ _ROOM-RADIUS 4) 6)
                                    (- (/ _ROOM-RADIUS 4) 6))
                            ))
                        (if (> (length s) 1)
                            (begin
                              (send dc set-brush
                                    (_value-of (second s)
                                              `((Red . ,_RED-SPHERE-COLOR)
                                                (Blue . ,_BLUE-SPHERE-COLOR)
                                                (Gray . ,_GRAY-SPHERE-COLOR))) 'solid)
                              (send dc set-pen _ROOM-CONTOUR-COLOR 1 'solid)
                              (send dc draw-ellipse 
                                    (+ x (* _ROOM-RADIUS 1.25) 3)
                                    (+ y (* _ROOM-RADIUS 1.25) 3)
                                    (- (/ _ROOM-RADIUS 4) 6)
                                    (- (/ _ROOM-RADIUS 4) 6))
                              ))
                        )
                      )
                    )
                ;; bilele
                (for-each
                 (λ (color)
                   (let* ((n (_in-room-spheres-color (car color) (car room) world-state))
                          (spheres-pos (_take _in-room-positions n)))
                     (for-each
                      (λ (s)
                        (begin
                          (send dc set-brush
                                (_value-of (car color) 
                                          `((Red . ,_RED-SPHERE-COLOR)
                                            (Blue . ,_BLUE-SPHERE-COLOR)
                                            (Gray . ,_GRAY-SPHERE-COLOR))) 'solid)
                          (send dc set-pen "black" 0.5 'solid)
                          (send dc draw-ellipse
                                (+ x (* _ROOM-RADIUS 1.25) 3
                                   (* (cadr color) (car s) (/ _ROOM-RADIUS 4))
                                   (if (> (cadr color) 0) (/ _ROOM-RADIUS -4) 0)
                                   )
                                (+ y (* _ROOM-RADIUS 1.25) 3
                                   (* (cddr color) (cdr s) (/ _ROOM-RADIUS 4))
                                   (if (> (cddr color) 0) (/ _ROOM-RADIUS -4) 0))
                                (- (/ _ROOM-RADIUS 4) 6)
                                (- (/ _ROOM-RADIUS 4) 6))
                          )
                        )
                      spheres-pos
                      )
                     )
                   )
                 '((Red . (-1 . -1)) (Blue . (1 . -1)) (Gray . (-1 . 1)))
                 )
                             )
                           )
                         ncoord)
                        )
                      )
                    )
                  positions
                  )
                 ))))
        (send _canvas refresh-now redraw-proc)
        ;(send _canvas suspend-flush)
        )
      )
    )
  )

;;; -----------------------------------------------------------------
;;; -----------------------------------------------------------------

;;;;; 13. Rulare scenarii

(define _play
  (lambda (color world-state statistics positions
                 ag1 ag1-state ag1-plan ag1-goal ag1-info ag1-level
                 ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level)
    (begin
      (if _pause-before-next-round? (read-char) #t)
      (if (> _SLEEP-TIME-BEFORE-NEXT-ROUND 0)
          (sleep _SLEEP-TIME-BEFORE-NEXT-ROUND)) 
      (if _print-round-separator? (_print-round-separator color) #t)
      (if _print-score? (_print-score world-state) #t)
      (if _print-world-state? (_print-world-state world-state) #t)
      (if _print-agent-state? 
          (if (equal? (first (_value-of 'Color ag1-state)) 'Red)
              (begin (_print-agent-state ag1-state) (_print-agent-state ag2-state) (_nl))
              (begin (_print-agent-state ag2-state) (_print-agent-state ag1-state) (_nl))
              )
          #t)
      (cond 
        ;; A câștigat vreun agent?
        ;; Atenție: poate câștiga și agentul roșu ca urmare a unei acțiuni a
        ;; agentului albastru și invers (serendipity)
        ((_winner? world-state)
         (_end-game world-state statistics))
        ;; Obiectivul agentului a fost atins 
        ;; (pentru agenții simpli care primesc ca obiectiv să aducă o sferă)
        ;; dacă se întâmplă asta, sigur agentul este level 1
        ((or (> (fourth (_delivered color world-state)) (fourth ag1-goal))
             (empty? ag1-plan)
             (equal? (car ag1-plan) 'PAUSE))
         (let*-values 
             (;; Obiectivul agentului (mediu dinamic, se calculează mereu)
              ((ag1-new-goal) 
               (if (= ag1-level 1) (_one-sphere-goal color world-state)
                     ag1-goal))
              ((planning-result cpu-time a b)  
               (time-apply ag1 (list ag1-new-goal 
                                     (append world-state ag1-state)   
                                     (if (= ag1-level 1) '() (if (empty? ag1-plan) '() (cdr ag1-plan)))
                                     (if (= ag1-level 1) #f ag1-info)))) 
              ((ag1-new-plan) (first (car planning-result)))
              ((ag1-new-info) (cdr (car planning-result))))
           (begin
             (if _print-new-plan? (_print-new-plan ag1-new-plan) #t)
             (_play (_next-agent color) world-state 
                   (_add-to-statistics "Timp total planificare" color cpu-time 
                                      (_increment "Replanificări" color statistics))
                   positions
                   ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level
                   ag1 ag1-state ag1-new-plan ag1-new-goal ag1-new-info ag1-level)
           )))
        ;;
        ;; Se aplică un operator greșit
        ((let* ((check-result (_operator-check (first ag1-plan) ag1-state world-state)))
           (if (equal? (car check-result) #f) 
               (begin
                 (if _print-action-error?
                     (_print-action-error (first ag1-plan) (cdr check-result))
                     #t
                     )
                 #t)
               #f))
         (_play (_next-agent color) world-state 
               (_increment "Erori de aplicare" color statistics) positions
               ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level
               ag1 ag1-state (cons 'PAUSE ag1-plan) ag1-goal ag1-info ag1-level)
         )
        ;; Operator Test
        ((equal? (caar ag1-plan) 'Test)
         (let ((result (_check-conditions (cdar ag1-plan) world-state)))
           (begin
             (if _print-condition? (_print-condition (cdar ag1-plan) result)
                 #t)
             (if result
                 (_play (_next-agent color) world-state
                       (_increment "Teste trecute" color statistics) positions
                       ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level
                       ag1 ag1-state (cdr ag1-plan) ag1-goal ag1-info ag1-level)
                 (_play (_next-agent color) world-state
                       (_increment "Teste eșuate" color statistics) positions
                       ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level
                       ag1 ag1-state (cons 'PAUSE ag1-plan) ag1-goal ag1-info ag1-level)
                 ))
           ))
        ;; Aplică acțiunea următoare
        (#t 
         (let ((new-state (_apply-action (car ag1-plan) world-state ag1-state)))
           (begin
             (if _print-action? (_print-action (car ag1-plan)) #t)
             (if _display-gui? 
                 (_redraw positions world-state 
                          (if (equal? color 'Red) ag1-state ag2-state)
                          (if (equal? color 'Red) ag2-state ag1-state)))
             (_play (_next-agent color) (car new-state)
                   (_increment "Acțiuni" color statistics) positions
                   ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level
                   ag1 (cdr new-state) (cdr ag1-plan) ag1-goal ag1-info ag1-level)
             )
           )
         )
        )
      )
    )
  )

(define _play2
  (lambda (color world-state statistics positions
                 ag1 ag1-state ag1-plan ag1-goal ag1-info ag1-level
                 ag2 ag2-state ag2-plan ag2-goal ag2-info ag2-level)
    (begin
      ;(cond 
        ;; A câștigat vreun agent?
        ;; Atenție: poate câștiga și agentul roșu ca urmare a unei acțiuni a
        ;; agentului albastru și invers (serendipity)
       ; ((_winner? world-state)
       ;  (_end-game world-state statistics))

        (display (simpleagent (_one-sphere-goal 'Red world-state) (append world-state ag1-state) '() '()))
     )
  )
)
    
;;; *run* rulează scenariul din @scenario-file
;;; cu un agent roșu memoryless-agent pentru @level=1 sau un agent roșu
;;; advanced-agent pentru @level = 2
;;; și un agent albastru memoryless-agent
(define run
  (lambda (scenario-file level)
    (begin
      ;; se încarcă scenariul cu definițiile pentru initial-world-state și M
      (load scenario-file)
      (let* (;; planificatoarele celor 2 agenți
             ;;  dacă nivelul este 1: memoryless-agent vs. memoryless-agent
             ;;  dacă nivelul este 2: advanced-agent vs. memoryless-agent
             (red-agent (if (= level 1) memoryless-agent advanced-agent))
             (blue-agent memoryless-agent)
             ;; ----
             ;; stările inițiale ale celor 2 agenți
             (red-state (_initial-agent-state 'Red initial-world-state))

             (blue-state (_initial-agent-state 'Blue initial-world-state))
             ;; ----
             ;; obiectivele celor 2 agenți
             ;;  pentru memoryless-agent: să aducă o sferă
             ;;  pentru advanced-agent: să aducă toate sferele
             (red-goal
              (if (= level 1) (_one-sphere-goal 'Red initial-world-state)
                  (_all-spheres-goal 'Red initial-world-state)))
             (blue-goal (_one-sphere-goal 'Blue initial-world-state))
             ;; ----
             ;; inițializăm statisticile
             (statistics (_initial-statistics))
             ;; ----
             ;; calculăm pozițiile camerelor pe canvas
             (positions (_get-matrix initial-world-state))
             (minx (apply min (map cadr positions)))
             (miny (apply min (map cddr positions)))
             (tr-pos (map (λ (p) (cons (car p) (cons (- (cadr p) minx) 
                                                     (- (cddr p) miny))))
                          positions))
             (f-width (+ 1 (apply max (map cadr tr-pos))))
             (f-height (+ 1 (apply max (map cddr tr-pos))))
             )
        ;(display tr-pos)
        (_redraw tr-pos initial-world-state red-state blue-state)
        (begin
          (if _display-gui? 
              (begin
                (send _frame set-label scenario-file)
                (send _frame resize 
                      (inexact->exact (* 2.5 _ROOM-RADIUS f-width)) 
                      (inexact->exact (* 2.5 _ROOM-RADIUS f-height)))
                (_redraw tr-pos initial-world-state red-state blue-state)
                (send _frame show #t)
                )
              )
          (_play 'Red initial-world-state statistics tr-pos
                red-agent red-state '() red-goal '() level
                blue-agent blue-state '() blue-goal '() 1)
          )
        )
      )
    )
  )

(begin (run "scenario2.scm" 1)) 
