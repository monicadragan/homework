;; Scenariul 3
(define M 11)
(define initial-world-state
  '(
   ;; room colors
   (Color BlueWarehouse Blue) (Color RedWarehouse Red)
   (Color Room1 White) (Color Room2 White) (Color Room3 White)
   (Color Room4 White) (Color Room5 White) (Color Room6 White)
   (Color Room7 White) (Color Room8 White)
   ;; Doors
   (Door Room1 Room4) (Door Room2 Room4) (Door Room3 Room4)
   (Door Room4 Room1) (Door Room4 Room2) (Door Room4 Room3)
   (Door Room4 RedWarehouse)
   (Door RedWarehouse Room4) (Door RedWarehouse BlueWarehouse)
   (Door BlueWarehouse RedWarehouse) (Door BlueWarehouse Room5) (Door Room5 BlueWarehouse)
   (Door Room5 Room6) (Door Room5 Room7) (Door Room5 Room8)
   (Door Room6 Room5) (Door Room7 Room5) (Door Room8 Room5)
   ;; Spheres
   (Spheres Gray BlueWarehouse 1) (Spheres Red BlueWarehouse 0) (Spheres Blue BlueWarehouse 0)
   (Spheres Gray Room1 1) (Spheres Red Room1 1) (Spheres Blue Room1 2)
   (Spheres Gray Room2 1) (Spheres Red Room2 0) (Spheres Blue Room2 3)
   (Spheres Gray Room3 1) (Spheres Red Room3 1) (Spheres Blue Room3 2)
   (Spheres Gray Room4 1) (Spheres Red Room4 2) (Spheres Blue Room4 0)
   (Spheres Gray Room5 1) (Spheres Red Room5 0) (Spheres Blue Room5 2)
   (Spheres Gray Room6 1) (Spheres Red Room6 2) (Spheres Blue Room6 1)
   (Spheres Gray Room7 1) (Spheres Red Room7 2) (Spheres Blue Room7 1)
   (Spheres Gray Room8 1) (Spheres Red Room8 3) (Spheres Blue Room8 0)
   (Spheres Gray RedWarehouse 1) (Spheres Red RedWarehouse 0) (Spheres Blue RedWarehouse 0)
   )
  )