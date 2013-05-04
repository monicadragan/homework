;; Scenariul 1
(define M 4)
(define initial-world-state
  '(
   ;; room colors
   (Color BlueWarehouse Blue) (Color RedWarehouse Red)
   (Color Room1 White) (Color Room2 White) (Color Room3 White)
   ;; doors
   (Door BlueWarehouse Room1) 
   (Door Room1 BlueWarehouse) (Door Room1 Room2)
   (Door Room1 Room3) (Door Room2 Room1) 
   (Door Room2 Room3) (Door Room2 RedWarehouse)
   (Door Room3 Room1) (Door Room3 Room2)
   (Door RedWarehouse Room2)
   ;; spheres
   (Spheres Gray BlueWarehouse 1) (Spheres Red BlueWarehouse 0) 
   (Spheres Blue BlueWarehouse 0)
   (Spheres Gray Room1 1) (Spheres Red Room1 1) 
   (Spheres Blue Room1 1)
   (Spheres Gray Room2 1) (Spheres Red Room2 1) 
   (Spheres Blue Room2 1)
   (Spheres Gray Room3 1) (Spheres Red Room3 2) 
   (Spheres Blue Room3 2)
   (Spheres Gray RedWarehouse 1) (Spheres Red RedWarehouse 0) 
   (Spheres Blue RedWarehouse 0)
   )
  )