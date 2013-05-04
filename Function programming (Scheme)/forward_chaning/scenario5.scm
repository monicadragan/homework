;; Scenariul 4
(define M 7)
(define initial-world-state
  '(
   ;; room colors
   (Color BlueWarehouse Blue) (Color RedWarehouse Red)
   (Color Room1 White) (Color Room2 White) (Color Room3 White)
   (Color Room4 White) (Color Room5 White) (Color Room6 White)
   (Color Room7 White)
   ;; Doors
   (Door BlueWarehouse Room1) (Door BlueWarehouse Room3)
   (Door Room1 BlueWarehouse) (Door Room1 Room2)
   (Door Room2 Room1) (Door Room2 Room4)
   (Door Room3 BlueWarehouse) (Door Room3 Room4)
   (Door Room4 Room2) (Door Room4 Room3) (Door Room4 Room5) (Door Room4 Room6)
   (Door Room5 Room4) (Door Room5 RedWarehouse)
   (Door Room6 Room4) (Door Room6 Room7)
   (Door Room7 Room6) (Door Room7 RedWarehouse)
   (Door RedWarehouse Room5) (Door RedWarehouse Room7)
   ;; Spheres
   (Spheres Gray BlueWarehouse 1) (Spheres Red BlueWarehouse 0) (Spheres Blue BlueWarehouse 0)
   (Spheres Gray Room1 1) (Spheres Red Room1 1) (Spheres Blue Room1 1)
   (Spheres Gray Room2 1) (Spheres Red Room2 2) (Spheres Blue Room2 1)
   (Spheres Gray Room3 1) (Spheres Red Room3 1) (Spheres Blue Room3 0)
   (Spheres Gray Room4 1) (Spheres Red Room4 2) (Spheres Blue Room4 1)
   (Spheres Gray Room5 1) (Spheres Red Room5 1) (Spheres Blue Room5 1)
   (Spheres Gray Room6 1) (Spheres Red Room6 0) (Spheres Blue Room6 1)
   (Spheres Gray Room7 1) (Spheres Red Room7 0) (Spheres Blue Room7 2)
   (Spheres Gray RedWarehouse 1) (Spheres Red RedWarehouse 0) (Spheres Blue RedWarehouse 0)
   )
  )