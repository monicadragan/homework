;; Scenariul 4
(define M 5)
(define initial-world-state
  '(
    ;; Room colors
    (Color BlueWarehouse Blue) (Color RedWarehouse Red)
    (Color Room1 White) (Color Room2 White) (Color Room3 White)
    (Color Room4 White) (Color Room5 White) (Color Room6 White)
    ;; Doors
    (Door BlueWarehouse Room1) (Door Room1 BlueWarehouse)
    (Door Room1 Room2) (Door Room2 Room3) (Door Room3 Room4)
    (Door Room4 RedWarehouse) (Door Room4 Room5) 
    (Door Room5 Room6) (Door Room6 Room1)
    (Door RedWarehouse Room4)
    ;; Spheres
    (Spheres Gray BlueWarehouse 1) (Spheres Red BlueWarehouse 0) (Spheres Blue BlueWarehouse 0)
    (Spheres Gray Room1 1) (Spheres Red Room1 2) (Spheres Blue Room1 0)
    (Spheres Gray Room2 1) (Spheres Red Room2 1) (Spheres Blue Room2 0)
    (Spheres Gray Room3 1) (Spheres Red Room3 1) (Spheres Blue Room3 1)
    (Spheres Gray Room4 1) (Spheres Red Room4 0) (Spheres Blue Room4 2)
    (Spheres Gray Room5 1) (Spheres Red Room5 0) (Spheres Blue Room5 1)
    (Spheres Gray Room6 1) (Spheres Red Room6 1) (Spheres Blue Room6 1)
    (Spheres Gray RedWarehouse 1) (Spheres Red RedWarehouse 0) (Spheres Blue RedWarehouse 0)
    )
  )