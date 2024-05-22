(in-package #:spring-lisp-game-jam-2024)

(defstruct game-context
  (money 0 :type non-negative-fixnum)
  (towers nil :type list)
  (enemies nil :type list)
  (objects nil :type list)
  (game-over-p nil :type boolean))

(defclass game-scene (basic-scene)
  ((map-renderer :initarg :map-renderer :initform (eon:tiled-map-renderer (tiled:load-map (game-asset #P"maps/map-1.tmx"))) :type eon:tiled-renderer :accessor game-scene-map-renderer)
   (context :initarg :context :initform (make-game-context) :type game-context :accessor game-scene-context)))

(defmethod basic-scene-draw-map ((scene game-scene))
  (rlgl:push-matrix)
  (rlgl:rotatef 90.0 1.0 0.0 0.0)
  (rlgl:scalef (/ (coerce +tile-width+ 'single-float)) (/ (coerce +tile-height+ 'single-float)) single-float-epsilon)
  (funcall (game-scene-map-renderer scene))
  (rlgl:pop-matrix))

(defmethod basic-scene-draw-objects ((scene game-scene))
  (let ((context (game-scene-context scene)))
    (unless (game-context-game-over-p context)
      (mapc (rcurry #'game-scene-tower-try-attack (game-context-enemies context)) (game-context-towers context)))
    (eon:scene3d-draw-simple (game-context-towers context))
    (eon:scene3d-draw-simple (game-context-enemies context))
    (rlgl:normal3f 0.0 1.0 0.0)
    (eon:scene3d-draw-simple (game-context-objects context))))

(eon:define-scene2d-constructed game-scene-ui
    (eon:scene2d-group
     :name group
     :children ((eon:scene2d-cell
                 :size (#.(float +viewport-width+) #.(float +viewport-height+))
                 :alignment (:end :start)
                 :child (eon:scene2d-window
                         :child (eon:scene2d-margin
                                 :top 2.0 :bottom 2.0 :left 2.0 :right 2.0
                                 :child (eon:scene2d-box
                                         :orientation :horizontal
                                         :children ((eon:scene2d-label :string "$ ")
                                                    (eon:scene2d-label :string "0" :name label-money)))))))))

(defstruct game-scene-screen
  (scene (make-instance 'game-scene) :type game-scene)
  (ui (make-game-scene-ui) :type eon:scene2d-constructed))

(defmethod eon:screen-render ((screen game-scene-screen))
  (raylib:clear-background raylib:+white+)
  (eon:scene3d-draw-simple (game-scene-screen-scene screen))
  (let ((ui (game-scene-screen-ui screen)))
    (let ((old (eon:scene2d-label-string (game-scene-ui-label-money ui)))
          (new (princ-to-string (game-context-money (game-scene-context (game-scene-screen-scene screen))))))
      (unless (string= old new)
        (setf (eon:scene2d-label-string (game-scene-ui-label-money ui)) new)
        (eon:scene2d-layout (game-scene-screen-ui screen))))
    (eon:scene2d-draw-simple ui)))