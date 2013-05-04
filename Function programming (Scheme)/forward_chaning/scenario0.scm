;; Scenariul 0
(define M 4)
(define initial-world-state
  '(
   ;; room colors
   (Color BlueWarehouse Blue) (Color RedWarehouse Red)
   (Color Room1 White) (Color Room2 White)
   ;; doors
   (Door BlueWarehouse Room1) 
   (Door Room1 BlueWarehouse) (Door Room1 Room2)
   (Door Room2 Room1) (Door Room2 RedWarehouse)
   (Door RedWarehouse Room2)
   ;; spheres
   (Spheres Gray BlueWarehouse 1) (Spheres Red BlueWarehouse 0) 
   (Spheres Blue BlueWarehouse 0)
   (Spheres Gray Room1 1) (Spheres Red Room1 2) 
   (Spheres Blue Room1 2)
   (Spheres Gray Room2 1) (Spheres Red Room2 2) 
   (Spheres Blue Room2 2)
   (Spheres Gray RedWarehouse 1) (Spheres Red RedWarehouse 0) 
   (Spheres Blue RedWarehouse 0)
   )
  )