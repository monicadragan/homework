;; Monica Dragan, tema2 IA, 2012

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;Interogari world state;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; numărul de sfere de culoarea @color încărcate de robot
(define carries 
  (lambda (world-state)
    (filter (λ (arg) (equal? (first arg) 'Carries)) world-state)))

(define location
  (lambda (world-state)
    (filter (λ (arg) (equal? (first arg) 'Location)) world-state)))

(define doors
  (lambda (world-state)
    (filter (λ (arg) (equal? (first arg) 'Door)) world-state)))

(define total_colored_balls
  (lambda (world-state color)
    (sum (map fourth (filter (lambda(x) (and (equal? (second x) color) (equal? (first x) 'Spheres))) world-state)))))

(define get_location 
  (lambda (world-state)
    (second (car (filter (λ (arg) (equal? (first arg) 'Location)) world-state)))))

(define get_color 
  (lambda (world-state)
    (second (car (filter (λ (arg) (and (= (length arg) 2) (equal? (first arg) 'Color))) world-state)))))

;returneaza numarul de bile detinute de agent de o anumita culoare
(define get_carried
  (lambda (world-state color)
    (let* ((sublist (filter (λ (arg) (and (equal? (first arg) 'Carries) (equal? (second arg) color))) world-state)))
           (cond ((null? sublist) '())
                 (else (third (car sublist))))
    )))

;intoarce numarul de bile de culoarea color din camera room
(define get_colored_balls_in_room
  (lambda (world-state color room)
    (let* ((sublist 
            (filter (λ (arg) (and (and (equal? (first arg) 'Spheres) 
                                  (equal? (third arg) room)) 
                      (equal? (second arg) color))) world-state)))
      ;(display sublist)(display "\n")
           (cond ((null? sublist) 0)
                 (else (fourth (car sublist)))))
    ))

;returneaza camerele care se invecineaza cu o anumita camera
(define get_neighbour_rooms
  (lambda (world-state room)
    (let* ((sublist (filter (λ (arg) (and (equal? (first arg) 'Door) (equal? (second arg) room))) world-state)))
      (cond ((null? sublist) '())
            (else (map third sublist))))))

(define get-robothouse
  (lambda (color)
    (cond ((equal? color 'Red) 'RedWarehouse)
          (else 'BlueWarehouse))))

(define near-robothouse?
  (lambda (world-state)
    (let* ((color (get_color world-state))
          (location (get_location world-state))
          (neighbours (get_neighbour_rooms world-state (get_location world-state))))
          (cond ((in_list (get-robothouse color) neighbours) (get-robothouse color))
          (else #f))
)))

(define in-robothouse?
  (lambda (world-state)
    (let* ((color (get_color world-state))
          (location (get_location world-state)))
          (cond ((and (equal? 'RedWarehouse location) (equal? color 'Red)) #t)
                ((and (equal? 'BlueWarehouse location) (equal? color 'Blue)) #t) 
                (else #f)))
))

(define carried_balls
  (lambda (world-state)
    (sum (map third (filter (λ (x) (equal? (car x) 'Carries)) world-state)))))

(define get_balls_in_room
  (lambda (world_state)
    (sum (map third (filter  
       (λ (x)(and (and (equal? (first x) 'Spheres) (equal? (third x) (get_location world_state))) (number? (fourth x)))) world_state)))))

(define total_colored_balls
  (lambda (world-state color)
    (sum (map fourth (filter (lambda(x) (and (equal? (second x) color) (equal? (first x) 'Spheres))) world-state)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;Functii auxiliare;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;flatten elimina parantezele
(define (flatten list)
   (cond ((null? list) null)
         ((list? (car list)) (append (flatten (car list)) (flatten (cdr list))))
         (else
          (cons (car list) (flatten (cdr list))))))


;;daca un element este in lista
(define in_list
  (lambda (item lista)
    (cond ((null? (filter (lambda (x) (equal? item x)) lista)) #f)
          (else #t))))

(define nth 
  (lambda (ls n)
      (cond ((= (length ls) 1) ls)
      (else
       (if (eq? n 1)(car ls)
          (nth (cdr ls) (- n 1)))))))

(define remove-nth
  (lambda (ls n)
    (if (= n 1) (cdr ls)
        (append (list (car ls)) (remove-nth (cdr ls) (- n  1))))))
        

(define shuffle
  (lambda (ls)
    (cond ((null? ls) '())
            (else (let ((rand (+ (random (length ls)) 1) ))
                    ;(display rand)(display ls)(display "\n")
                    (flatten (append (list (nth ls rand)) (shuffle (remove-nth ls rand)))))))))

; inlocuieste o operatie legata cu una nelegata din lista
(define replace
  (lambda (propozitie lista)
    (let ((delete_item (car (filter (lambda (arg) 
              (begin ;(display (first propozitie)) (display "\n")
              (cond ((equal? (first propozitie) 'Location) (equal? (first arg) 'Location))
                    ((equal? (first propozitie) 'Spheres)
                        (and 
                         (and (equal? (first arg) 'Spheres) (equal? (second arg) (second propozitie)))
                          (equal? (third arg) (third propozitie))))     
                    ((equal? (first propozitie) 'Carries) 
                        (and (equal? (first arg) 'Carries) (equal? (second arg) (second propozitie))))       
                    (else #f)
              ))) lista))))
           (append (list propozitie) (remove delete_item lista))
      )))

(define sum
  (lambda (lista)
    (cond ((= (length lista) 0) 0)
          (else (+ (car lista) (sum (cdr lista)))))))

;; verifica daca argumentul este pozitiv
(define positive 
  (lambda item
    (> item 0)))

;; verifica daca cele doua argumente sunt diferite
(define different 
  (lambda item1 item2
    (not (equal? item1 item2))))

(define opposite-color?
  (lambda (color)
    (cond ((equal? color 'Red) 'Blue)
          (else 'Red))))

; compara 2 world stateuri
(define liste-egale?
  (λ (l1 l2)
    (if (and (andmap (λ (el) (if (not (member el l1)) #f #t)) l2)
         (andmap (λ (el) (if (not (member el l2)) #f #t)) l1))
         #t
         #f)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;Euristici;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define check_unload_color
  (lambda (world-state forbidden-actions color)
    (begin
    (cond ((and (not(in_list (list 'Unload color) forbidden-actions))(> (get_carried world-state color) 0)) (list 'Unload color))
    (else '())))))


;verifica daca preconditiile pentru mutare sunt valide si
;returneaza maxim 3 posibilitati de mutare
(define apply_unload
  (lambda (world-state forbidden-actions)
    (let* ((color (get_color world-state)))
          (cond ((and (in-robothouse? world-state) (equal? color 'Red))
                 (filter (lambda(x)(not(null? x))) 
                         (list (check_unload_color world-state forbidden-actions 'Red)
                               (check_unload_color world-state forbidden-actions 'Blue)
                               (check_unload_color world-state forbidden-actions 'Gray))))
                ((and (in-robothouse? world-state) (equal? color 'Blue))
                 (filter (lambda(x)(not(null? x))) 
                         (list (check_unload_color world-state forbidden-actions 'Blue)
                               (check_unload_color world-state forbidden-actions 'Red)
                               (check_unload_color world-state forbidden-actions 'Gray))))
                (else 
                 (filter (lambda(x)(not(null? x))) 
                         (list (check_unload_color world-state forbidden-actions 'Gray)
                               (check_unload_color world-state forbidden-actions 'Red)
                               (check_unload_color world-state forbidden-actions 'Blue))))))
))

;;
(define check_load_color
  (lambda (world-state forbidden-actions color)
    (begin
    (cond  ((and (equal? (get_location world-state) 'RedWarehouse) (equal? color 'Red)) '())
           ((and (equal? (get_location world-state) 'BlueWarehouse) (equal? color 'Blue)) '())
           ((and (and (not(in_list (list 'Load color) forbidden-actions))
                     (< (carried_balls world-state) 2) 
                (> (get_colored_balls_in_room world-state color (get_location world-state)) 0))) (list 'Load color)) 
    (else '())))))

;verifica daca preconditiile pentru mutare sunt valide si
;returneaza maxim 3 posibilitati de mutare
(define apply_load
  (lambda (world-state forbidden-actions)
    ;Prioritate la load are bila de culoarea robotului
    (cond ((and (in-robothouse? world-state) (equal? (get_color world-state) 'Red))
             (filter (lambda(x)(not(null? x)))
                  (list (check_load_color world-state forbidden-actions 'Blue)
                        (check_load_color world-state forbidden-actions 'Gray))))
          ((and (in-robothouse? world-state) (equal? (get_color world-state) 'Blue))
             (filter (lambda(x)(not(null? x)))
                  (list (check_load_color world-state forbidden-actions 'Red)
                        (check_load_color world-state forbidden-actions 'Gray))))
          ((equal? (get_color world-state) 'Red)
              (filter (lambda(x)(not(null? x)))
                  (list (check_load_color world-state forbidden-actions 'Red)
                        (check_load_color world-state forbidden-actions 'Gray)
                        (check_load_color world-state forbidden-actions 'Blue))))
          (else 
              (filter (lambda(x)(not(null? x)))
                  (list (check_load_color world-state forbidden-actions 'Blue)
                        (check_load_color world-state forbidden-actions 'Gray)
                        (check_load_color world-state forbidden-actions 'Red)))))
    ))
  
;verifica daca preconditiile pentru mutare sunt valide si
;returneaza maxim 2 posibilitati de mutare
(define apply_move    
  (lambda (world-state forbidden-actions)
      (cond ((or (= (carried_balls world-state) 2)(= (carried_balls world-state) 0))
             (let* ((neighbours (shuffle (get_neighbour_rooms world-state (get_location world-state))))
                    (location (get_location world-state)))
             ;daca robotul se afla langa camera de culoarea lui
               (cond ((near-robothouse? world-state)
                   (let ((neighbours2 
                         (append (list (near-robothouse? world-state)) (remove (near-robothouse? world-state) neighbours))))
                     (map (lambda(y) (list 'Move location y))
                        (filter (lambda(x) (not(in_list (list 'Move x) forbidden-actions))) neighbours2))))
                     (else (map (lambda(y) (list 'Move location y))
                        (filter (lambda(x) (not(in_list (list 'Move x) forbidden-actions))) neighbours))))))
            (else '()))
))

(define generate_possible_actions
  (lambda (world-state forbidden-actions)
    (let* ((color (get_color world-state))
           (location (get_location world-state))
           (colored_balls (get_colored_balls_in_room world-state color location))
           (carried_colored_balls (get_carried world-state color))
           )
      (cond ((and (= carried_colored_balls 0) (> colored_balls 0))
             (append (apply_load world-state forbidden-actions)
                     (apply_move world-state forbidden-actions)
                     (apply_unload world-state forbidden-actions)))
            ((equal? location (get-robothouse color)) 
             (append (apply_unload world-state forbidden-actions)
                     (apply_move world-state forbidden-actions)
                     (apply_load world-state forbidden-actions)))
            (else 
             (append (apply_move world-state forbidden-actions)
                     (apply_unload world-state forbidden-actions)
                     (apply_load world-state forbidden-actions))))
)))
    
;returneaza (new_world_state . lista_constrangeri)
(define update_world_state
  (lambda (world-state current_action)
    (cond ((equal? (first current_action) 'Move) (list (replace (list 'Location (third current_action)) world-state) '()))
          ((equal? (first current_action) 'Load)
             (begin 
               (let* ((spheres (get_colored_balls_in_room world-state (second current_action) (get_location world-state)))
                     (carried (get_carried world-state (second current_action)))
                     (new_world_state (replace (list 'Spheres (second current_action) (get_location world-state) (- spheres 1))
                              (replace (list 'Carries (cadr current_action) (+ carried 1)) world-state))))
                     (list new_world_state (list 'Unload (second current_action))))
             ))
          ((equal? (first current_action) 'Unload)
             (begin 
               (let* ((spheres (get_colored_balls_in_room world-state (second current_action) (get_location world-state)))
                     (carried (get_carried world-state (second current_action)))
                     (new_world_state (replace (list 'Spheres (second current_action) (get_location world-state) (+ spheres 1))
                              (replace (list 'Carries (cadr current_action) (- carried 1)) world-state))))
                     (list new_world_state (list 'Load (second current_action))))
             )))
))

(define visited-state?
  (λ (world-state world-states)
    (ormap (λ (x) (liste-egale? world-state x)) world-states)))
         

(define game_over
  (lambda (goalas world-state)
    (in_list goalas world-state)))

(define simpleagent  
  (lambda (goals world-state rest-actions info)
    (let* ((possible_actions (append (apply_unload world-state '())
                                           (apply_load world-state '()) 
                                           (apply_move world-state '())))
           (robot_color (get_color world-state))
           (opposite_color (opposite-color? robot_color))
           (balls_in_world (total_colored_balls world-state robot_color)) 
           (balls_in_room (get_colored_balls_in_room world-state robot_color (get-robothouse robot_color)))
           (carries_same_color (get_carried world-state robot_color))
           (carries_oppsite_color (get_carried world-state opposite_color)))
          ;(display "!!!")(display balls_in_world) (display balls_in_room) (display "\n")
          (cond ((and (equal? balls_in_world balls_in_room)(= carries_same_color 0))
                 (cond ((= carries_oppsite_color 0) (list '()))
                       ((= carries_oppsite_color 1) (list (list '(Unload opposite_color))))
                       ((= carries_oppsite_color 2) (list (list '(Unload opposite_color) '(Unload opposite_color))))))
          (else 
          (multiple_actions goals (list world-state) '() (list possible_actions) '())))
    ))) 

(define multiple_actions 
  (lambda (goals world-states actions possible_actions forbidden_actions)
    (let ((next_action (one_action goals world-states actions possible_actions forbidden_actions)))
      
      (cond ((> (length (second next_action)) 30) (list '()))
            ((game_over goals (car world-states))(begin (list (reverse (second next_action)))))
            (else (multiple_actions goals (first next_action) (second next_action) (third next_action) (fourth next_action)))))
))
                  

;; returneaza o lista cu goal-urile, current_world_state, actiunile de pana acum, actiunile interzise
(define one_action  
  (lambda (goals world-states actions possible_actions forbidden_actions)
    (begin  
      ;(display "\n*********************************************\n")
      ;(display "Robot color    :")(display (get_color (car world-states)))(display "\n")
      ;(display "Goals          :")(display goals)(display "\n")
      ;(display "Actions        :")(display actions)(display "\n")
      ;(display "Possible  actio:")(display possible_actions)(display "\n")
      ;(display "Forbidden actio:")(display forbidden_actions)(display "\n")
      
      (let* (
         (world-state (car world-states))
         ;aleg prima posibilitate din lista de actiuni posibile
         (current_possible_actions (car possible_actions)))
         (cond ((null? current_possible_actions) 
                ;(one_action goals (cdr world-states) (cdr actions) (cdr possible_actions) '())
                (list (cdr world-states) actions (cdr possible_actions) forbidden_actions)
                ) 
           (else (let* (
             (current_action (car current_possible_actions)))
             ;(display "Current action    :")(display current_action)(display "\n")
             (let* ((update_world_state (update_world_state world-state current_action))
                    (new_world_state (first update_world_state))               
                    (new_forbidden_actions '())
                    (additional_forbidden_actions (list (second update_world_state))))
               (cond ((visited-state? new_world_state world-states) 
                      (begin 
                        (display "!!!!!!!!\n")
                        (list world-states actions 
                              (append (list (cdr current_possible_actions)) (cdr possible_actions)) forbidden_actions)))
               (else (begin
                    (cond ((not (equal? (car current_action) 'Move))
                           ;calculez noua lista de actiuni posibile
                           (let* ((new_possible_actions (generate_possible_actions new_world_state new_forbidden_actions)))
                                  ;(display "New forbidden actions   :")(display new_forbidden_actions)(display "\n") 
                                  ;(display "New possible actions    :")(display new_possible_actions)(display "\n") 
                                  (list (append (list new_world_state) world-states) 
                                        (append (list current_action) actions) 
                                        (append (list new_possible_actions) (list (cdr current_possible_actions)) (cdr possible_actions)) 
                                         new_forbidden_actions))) 
                          (else
                           ;new_forbidden_actions = '()
                           (let* ((new_possible_actions (generate_possible_actions new_world_state '())))
                                 ;(display "New forbidden actions   :")(display '())(display "\n") 
                                 ;(display "New possible actions    :")(display new_possible_actions)(display "\n") 
                                 (list (append (list new_world_state) world-states) 
                                       (append (list current_action) actions) 
                                       (append (list new_possible_actions) (list (cdr current_possible_actions)) (cdr possible_actions)) 
                                       '()))))
              )))))))
    ))))
		
(define memoryless-agent simpleagent)

